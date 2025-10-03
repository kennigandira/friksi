import type { User, Session, AuthError } from '@supabase/supabase-js'
import type {
  Database,
  Tables,
  UserLevel,
  AccountStatus,
} from '../types/database.types'
import { getBrowserSupabaseClient } from './browser'
import { createServerClientWithAuth } from './server'
import { getTypedClient, TableInsert, TableUpdate } from './typed-client'
import { logger } from '@/lib/logger'
import { env } from '@/lib/env'

export type FriksiUser = Tables<'users'>

/**
 * Authentication utilities for Friksi platform
 */
export class FriksiAuth {
  /**
   * Sign up a new user
   */
  static async signUp(credentials: {
    email: string
    password: string
    username: string
    fullName?: string
  }): Promise<{ user: User | null; error: AuthError | null }> {
    const supabase = getBrowserSupabaseClient()

    const { data, error } = await supabase.auth.signUp({
      email: credentials.email,
      password: credentials.password,
      options: {
        data: {
          username: credentials.username,
          full_name: credentials.fullName,
        },
      },
    })

    // Profile creation is now handled automatically by database trigger
    // See: supabase/migrations/00019_secure_profile_creation.sql
    // The trigger ensures secure defaults (level=1, xp=0, trust_score=50.0)
    // and prevents client-side manipulation of these values

    return { user: data.user, error }
  }

  /**
   * Sign in with email and password
   */
  static async signIn(credentials: {
    email: string
    password: string
  }): Promise<{ user: User | null; error: AuthError | null }> {
    const supabase = getBrowserSupabaseClient()

    const { data, error } = await supabase.auth.signInWithPassword(credentials)

    return { user: data.user, error }
  }

  /**
   * Sign out
   */
  static async signOut(): Promise<{ error: AuthError | null }> {
    const supabase = getBrowserSupabaseClient()

    const { error } = await supabase.auth.signOut()

    return { error }
  }

  /**
   * Get current session
   */
  static async getSession(): Promise<Session | null> {
    const supabase = getBrowserSupabaseClient()

    const {
      data: { session },
    } = await supabase.auth.getSession()

    return session
  }

  /**
   * Get current user
   */
  static async getCurrentUser(): Promise<User | null> {
    const supabase = getBrowserSupabaseClient()

    const {
      data: { user },
    } = await supabase.auth.getUser()

    return user
  }

  /**
   * Get current user's profile
   */
  static async getCurrentUserProfile(): Promise<FriksiUser | null> {
    const supabase = getBrowserSupabaseClient()

    const user = await this.getCurrentUser()
    if (!user) return null

    const { data, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', user.id)
      .single()

    if (error) {
      logger.error('Error fetching user profile:', error)
      return null
    }

    return data
  }

  /**
   * Update user profile
   */
  static async updateProfile(updates: {
    username?: string
    bio?: string
    avatar_url?: string
  }): Promise<{ success: boolean; error?: string }> {
    const supabase = getBrowserSupabaseClient()

    const user = await this.getCurrentUser()
    if (!user) return { success: false, error: 'Not authenticated' }

    const typedClient = getTypedClient(supabase)
    const updateData: TableUpdate<'users'> = updates

    const { error } = await typedClient
      .from('users')
      .update(updateData)
      .eq('id', user.id)

    if (error) {
      return { success: false, error: error.message }
    }

    return { success: true }
  }

  /**
   * Check if user has required level
   */
  static async hasLevel(requiredLevel: UserLevel): Promise<boolean> {
    const profile = await this.getCurrentUserProfile()
    if (!profile || profile.level === null) return false

    return profile.level >= requiredLevel
  }

  /**
   * Check if user is moderator
   */
  static async isModerator(categoryId?: string): Promise<boolean> {
    const supabase = getBrowserSupabaseClient()
    const user = await this.getCurrentUser()
    if (!user) return false

    let query = supabase
      .from('moderators')
      .select('id')
      .eq('user_id', user.id)
      .eq('is_active', true)

    if (categoryId) {
      query = query.eq('category_id', categoryId)
    }

    const { data, error } = await query

    if (error) return false

    return (data?.length || 0) > 0
  }

  /**
   * Check if user is banned or restricted
   */
  static async isRestricted(): Promise<{
    isRestricted: boolean
    accountStatus: AccountStatus | null
  }> {
    const profile = await this.getCurrentUserProfile()
    if (!profile) return { isRestricted: true, accountStatus: null }

    const accountStatus = (profile.account_status || 'active') as AccountStatus
    const isRestricted = ['restricted', 'shadowbanned', 'banned'].includes(
      accountStatus
    )

    return {
      isRestricted,
      accountStatus,
    }
  }

  /**
   * Listen to auth state changes
   */
  static onAuthStateChange(
    callback: (event: string, session: Session | null) => void
  ) {
    const supabase = getBrowserSupabaseClient()

    return supabase.auth.onAuthStateChange(callback)
  }

  /**
   * Reset password
   */
  static async resetPassword(
    email: string
  ): Promise<{ error: AuthError | null }> {
    const supabase = getBrowserSupabaseClient()

    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${env.app.url}/auth/reset-password`,
    })

    return { error }
  }

  /**
   * Update password
   */
  static async updatePassword(
    newPassword: string
  ): Promise<{ error: AuthError | null }> {
    const supabase = getBrowserSupabaseClient()

    const { error } = await supabase.auth.updateUser({
      password: newPassword,
    })

    return { error }
  }
}

/**
 * Server-side authentication utilities
 */
export class ServerAuth {
  /**
   * Get user from server-side with JWT token
   */
  static async getUserFromToken(token: string): Promise<FriksiUser | null> {
    try {
      const supabase = createServerClientWithAuth(token)

      const {
        data: { user },
      } = await supabase.auth.getUser()
      if (!user) return null

      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('id', user.id)
        .single()

      if (error) return null

      return data
    } catch (error) {
      logger.error('Error getting user from token:', error)
      return null
    }
  }

  /**
   * Verify if user has required level server-side
   */
  static async verifyUserLevel(
    token: string,
    requiredLevel: UserLevel
  ): Promise<boolean> {
    const user = await this.getUserFromToken(token)
    if (!user || user.level === null) return false

    return user.level >= requiredLevel
  }

  /**
   * Verify if user is moderator server-side
   */
  static async verifyModerator(
    token: string,
    categoryId?: string
  ): Promise<boolean> {
    try {
      const supabase = createServerClientWithAuth(token)

      const {
        data: { user },
      } = await supabase.auth.getUser()
      if (!user) return false

      let query = supabase
        .from('moderators')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_active', true)

      if (categoryId) {
        query = query.eq('category_id', categoryId)
      }

      const { data, error } = await query

      if (error) return false

      return (data?.length || 0) > 0
    } catch (error) {
      return false
    }
  }
}
