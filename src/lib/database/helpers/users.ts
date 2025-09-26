import type {
  Tables,
  TablesInsert,
  TablesUpdate,
  UserLevel,
  AccountStatus,
} from '../types/database.types'
import { createServerSupabaseClient } from '../lib/server'
import { getBrowserSupabaseClient } from '../lib/browser'

export type User = Tables<'users'>
export type UserInsert = TablesInsert<'users'>
export type UserUpdate = TablesUpdate<'users'>

export interface UserStats {
  level: number
  xp: number
  trust_score: number
  post_count: number
  comment_count: number
  helpful_votes: number
  badge_count: number
  is_moderator: boolean
  next_level_xp: number | null
  account_status: AccountStatus
}

export interface UserProfile extends User {
  badges?: Array<{
    id: string
    name: string
    description: string
    tier: string
    awarded_at: string
  }>
  moderator_categories?: Array<{
    id: string
    name: string
    slug: string
  }>
}

/**
 * User management utilities
 */
export class UserHelpers {
  /**
   * Get user profile with extended information
   */
  static async getUserProfile(
    userId: string,
    options: {
      includeBadges?: boolean
      includeModeratorInfo?: boolean
    } = {}
  ): Promise<{ user: UserProfile | null; error: string | null }> {
    try {
      const supabase = getBrowserSupabaseClient()

      const query = supabase.from('users').select('*').eq('id', userId)

      const { data: user, error } = await query.single() as { data: any; error: any }

      if (error || !user) {
        return { user: null, error: 'User not found' }
      }

      const userProfile: UserProfile = { ...user }

      // Include badges if requested
      if (options.includeBadges) {
        const { data: badges } = await supabase
          .from('user_badges')
          .select(
            `
            awarded_at,
            badges!user_badges_badge_id_fkey(id, name, description, tier)
          `
          )
          .eq('user_id', userId)
          .order('awarded_at', { ascending: false }) as { data: any[] | null }

        userProfile.badges =
          badges?.map(b => ({
            id: b.badges.id,
            name: b.badges.name,
            description: b.badges.description,
            tier: b.badges.tier,
            awarded_at: b.awarded_at,
          })) || []
      }

      // Include moderator info if requested
      if (options.includeModeratorInfo) {
        const { data: moderatorCategories } = await supabase
          .from('moderators')
          .select(
            `
            categories!moderators_category_id_fkey(id, name, slug)
          `
          )
          .eq('user_id', userId)
          .eq('is_active', true) as { data: any[] | null }

        userProfile.moderator_categories =
          moderatorCategories?.map(m => ({
            id: m.categories.id,
            name: m.categories.name,
            slug: m.categories.slug,
          })) || []
      }

      return { user: userProfile, error: null }
    } catch (error) {
      return {
        user: null,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Get user statistics
   */
  static async getUserStats(
    userId: string
  ): Promise<{ stats: UserStats | null; error: string | null }> {
    try {
      const supabase = getBrowserSupabaseClient()

      const { data: user, error } = await supabase
        .from('users')
        .select('*')
        .eq('id', userId)
        .single() as { data: any; error: any }

      if (error || !user) {
        return { stats: null, error: 'User not found' }
      }

      // Count badges
      const { count: badgeCount } = await supabase
        .from('user_badges')
        .select('*', { count: 'exact' })
        .eq('user_id', userId)

      // Check if user is moderator
      const { count: moderatorCount } = await supabase
        .from('moderators')
        .select('*', { count: 'exact' })
        .eq('user_id', userId)
        .eq('is_active', true)

      const stats: UserStats = {
        level: user.level,
        xp: user.xp,
        trust_score: user.trust_score,
        post_count: user.post_count,
        comment_count: user.comment_count,
        helpful_votes: user.helpful_votes,
        badge_count: badgeCount || 0,
        is_moderator: (moderatorCount || 0) > 0,
        next_level_xp: this.getNextLevelXP(user.level),
        account_status: user.account_status,
      }

      return { stats, error: null }
    } catch (error) {
      return {
        stats: null,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Update user profile
   */
  static async updateUser(
    userId: string,
    updates: UserUpdate,
    options?: { useServerClient?: boolean }
  ): Promise<{ user: User | null; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      const updateData: UserUpdate = {
        ...updates,
        updated_at: new Date().toISOString(),
      }

      const { data: user, error } = await (supabase as any)
        .from('users')
        .update(updateData)
        .eq('id', userId)
        .select()
        .single()

      if (error) {
        return { user: null, error: error.message }
      }

      return { user, error: null }
    } catch (error) {
      return {
        user: null,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Award XP to user
   */
  static async awardXP(
    userId: string,
    amount: number,
    reason: string,
    sourceType?: string,
    sourceId?: string,
    options?: { useServerClient?: boolean }
  ): Promise<{ success: boolean; newLevel?: number; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      // Get current user data
      const { data: user, error: userError } = await supabase
        .from('users')
        .select('level, xp')
        .eq('id', userId)
        .single() as { data: { level: number; xp: number } | null; error: any }

      if (userError || !user) {
        return { success: false, error: 'User not found' }
      }

      const newXP = user.xp + amount
      const newLevel = this.calculateLevel(newXP)
      const levelChanged = newLevel !== user.level

      // Update user XP and level
      const { error: updateError } = await (supabase as any)
        .from('users')
        .update({
          xp: newXP,
          level: newLevel,
          last_active: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq('id', userId)

      if (updateError) {
        return { success: false, error: updateError.message }
      }

      // Log XP transaction
      const { error: transactionError } = await (supabase as any)
        .from('xp_transactions')
        .insert({
          user_id: userId,
          amount,
          reason,
          source_type: sourceType || 'manual',
          source_id: sourceId,
        })

      if (transactionError) {
        console.error('Failed to log XP transaction:', transactionError)
      }

      // Log level up activity
      if (levelChanged) {
        await (supabase as any).from('user_activities').insert({
          user_id: userId,
          activity_type: 'level_up',
          metadata: { old_level: user.level, new_level: newLevel },
        })
      }

      return {
        success: true,
        newLevel: levelChanged ? newLevel : undefined,
        error: null,
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Check if user has required level
   */
  static async hasLevel(
    userId: string,
    requiredLevel: UserLevel
  ): Promise<{
    hasLevel: boolean
    userLevel: UserLevel
    error: string | null
  }> {
    try {
      const supabase = getBrowserSupabaseClient()

      const { data: user, error } = await supabase
        .from('users')
        .select('level')
        .eq('id', userId)
        .single() as { data: { level: number } | null; error: any }

      if (error || !user) {
        return { hasLevel: false, userLevel: 1, error: 'User not found' }
      }

      return {
        hasLevel: user.level >= requiredLevel,
        userLevel: user.level as UserLevel,
        error: null,
      }
    } catch (error) {
      return {
        hasLevel: false,
        userLevel: 1,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Get users by level
   */
  static async getUsersByLevel(
    level: UserLevel,
    options: {
      limit?: number
      offset?: number
      sortBy?: 'xp' | 'trust_score' | 'created_at'
      order?: 'asc' | 'desc'
    } = {}
  ): Promise<{ users: User[]; error: string | null }> {
    try {
      const supabase = getBrowserSupabaseClient()
      const { limit = 20, offset = 0, sortBy = 'xp', order = 'desc' } = options

      let query = supabase
        .from('users')
        .select('*')
        .eq('level', level)
        .eq('account_status', 'active')

      query = query.order(sortBy, { ascending: order === 'asc' })
      query = query.range(offset, offset + limit - 1)

      const { data: users, error } = await query

      if (error) {
        return { users: [], error: error.message }
      }

      return { users: users || [], error: null }
    } catch (error) {
      return {
        users: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Search users
   */
  static async searchUsers(
    searchTerm: string,
    options: {
      limit?: number
      offset?: number
      minLevel?: UserLevel
    } = {}
  ): Promise<{ users: User[]; error: string | null }> {
    try {
      const supabase = getBrowserSupabaseClient()
      const { limit = 20, offset = 0 } = options

      let query = supabase
        .from('users')
        .select('*')
        .or(`username.ilike.%${searchTerm}%,email.ilike.%${searchTerm}%`)
        .eq('account_status', 'active')

      if (options.minLevel) {
        query = query.gte('level', options.minLevel)
      }

      query = query
        .order('trust_score', { ascending: false })
        .range(offset, offset + limit - 1)

      const { data: users, error } = await query

      if (error) {
        return { users: [], error: error.message }
      }

      return { users: users || [], error: null }
    } catch (error) {
      return {
        users: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Get user activity log
   */
  static async getUserActivity(
    userId: string,
    options: {
      limit?: number
      offset?: number
      activityType?: string
    } = {}
  ): Promise<{
    activities: Tables<'user_activities'>[]
    error: string | null
  }> {
    try {
      const supabase = getBrowserSupabaseClient()
      const { limit = 50, offset = 0 } = options

      let query = supabase
        .from('user_activities')
        .select('*')
        .eq('user_id', userId)

      if (options.activityType) {
        query = query.eq('activity_type', options.activityType)
      }

      query = query
        .order('created_at', { ascending: false })
        .range(offset, offset + limit - 1)

      const { data: activities, error } = await query

      if (error) {
        return { activities: [], error: error.message }
      }

      return { activities: activities || [], error: null }
    } catch (error) {
      return {
        activities: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Calculate user level from XP
   */
  static calculateLevel(xp: number): UserLevel {
    if (xp >= 5000) return 5
    if (xp >= 2000) return 4
    if (xp >= 500) return 3
    if (xp >= 100) return 2
    return 1
  }

  /**
   * Get XP required for next level
   */
  static getNextLevelXP(currentLevel: UserLevel): number | null {
    switch (currentLevel) {
      case 1:
        return 100
      case 2:
        return 500
      case 3:
        return 2000
      case 4:
        return 5000
      case 5:
        return null // Max level
      default:
        return null
    }
  }

  /**
   * Get XP for action
   */
  static getXPForAction(actionType: string): number {
    const xpValues: Record<string, number> = {
      thread_created: 10,
      comment_created: 5,
      upvote_received: 2,
      downvote_received: -1,
      voted: 1,
      daily_login: 1,
      moderate_action: 15,
      report_validated: 5,
      election_participation: 20,
    }

    return xpValues[actionType] || 0
  }

  /**
   * Update user's last active timestamp
   */
  static async updateLastActive(
    userId: string,
    options?: { useServerClient?: boolean }
  ): Promise<{ success: boolean; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      const { error } = await (supabase as any)
        .from('users')
        .update({
          last_active: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq('id', userId)

      return { success: !error, error: error?.message || null }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Ban or restrict user
   */
  static async moderateUser(
    userId: string,
    action: 'restrict' | 'shadowban' | 'ban' | 'activate',
    moderatorId: string,
    reason?: string,
    options?: { useServerClient?: boolean }
  ): Promise<{ success: boolean; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      const { error: updateError } = await (supabase as any)
        .from('users')
        .update({
          account_status: action === 'activate' ? 'active' : action,
          updated_at: new Date().toISOString(),
        })
        .eq('id', userId)

      if (updateError) {
        return { success: false, error: updateError.message }
      }

      // Log moderation action
      const { error: logError } = await (supabase as any)
        .from('user_activities')
        .insert({
          user_id: userId,
          activity_type: 'level_up', // We'll extend this enum
          metadata: {
            action,
            moderator_id: moderatorId,
            reason: reason || null,
          },
        })

      if (logError) {
        console.error('Failed to log moderation action:', logError)
      }

      return { success: true, error: null }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }
}
