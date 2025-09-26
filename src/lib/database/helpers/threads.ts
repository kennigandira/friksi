import type {
  Tables,
  TablesInsert,
  TablesUpdate,
  Database,
  UserLevel,
} from '../types/database.types'
import { createServerSupabaseClient } from '../lib/server'
import { getBrowserSupabaseClient } from '../lib/browser'

export type Thread = Tables<'threads'>
export type ThreadInsert = TablesInsert<'threads'>
export type ThreadUpdate = TablesUpdate<'threads'>

/**
 * Thread management utilities
 */
export class ThreadHelpers {
  /**
   * Create a new thread
   */
  static async createThread(
    data: Omit<ThreadInsert, 'id' | 'created_at' | 'updated_at'>,
    options?: { useServerClient?: boolean }
  ): Promise<{ thread: Thread | null; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      // Calculate initial hot score
      const hotScore = this.calculateHotScore(0, 0, new Date())

      const { data: thread, error } = await supabase
        .from('threads')
        .insert({
          ...data,
          hot_score: hotScore,
          wilson_score: 0,
          last_activity_at: new Date().toISOString(),
        })
        .select()
        .single()

      if (error) {
        return { thread: null, error: error.message }
      }

      return { thread, error: null }
    } catch (error) {
      return {
        thread: null,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Get threads by category with pagination
   */
  static async getThreadsByCategory(
    categoryId: string,
    options: {
      sortBy?: 'hot' | 'new' | 'top'
      limit?: number
      offset?: number
      includeRemoved?: boolean
    } = {}
  ): Promise<{ threads: Thread[]; error: string | null }> {
    try {
      const supabase = getBrowserSupabaseClient()
      const {
        sortBy = 'hot',
        limit = 20,
        offset = 0,
        includeRemoved = false,
      } = options

      let query = supabase
        .from('threads')
        .select(
          `
          *,
          users!threads_user_id_fkey(username, avatar_url, level),
          categories!threads_category_id_fkey(name, slug)
        `
        )
        .eq('category_id', categoryId)

      if (!includeRemoved) {
        query = query.eq('is_removed', false).eq('is_spam', false)
      }

      // Apply sorting
      switch (sortBy) {
        case 'hot':
          query = query.order('hot_score', { ascending: false })
          break
        case 'new':
          query = query.order('created_at', { ascending: false })
          break
        case 'top':
          query = query.order('upvotes', { ascending: false })
          break
      }

      query = query.range(offset, offset + limit - 1)

      const { data: threads, error } = await query

      if (error) {
        return { threads: [], error: error.message }
      }

      return { threads: threads || [], error: null }
    } catch (error) {
      return {
        threads: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Get single thread with details
   */
  static async getThread(
    threadId: string,
    options: { incrementViews?: boolean } = {}
  ): Promise<{ thread: Thread | null; error: string | null }> {
    try {
      const supabase = getBrowserSupabaseClient()

      const { data: thread, error } = await supabase
        .from('threads')
        .select(
          `
          *,
          users!threads_user_id_fkey(username, avatar_url, level, is_bot),
          categories!threads_category_id_fkey(name, slug, path)
        `
        )
        .eq('id', threadId)
        .single()

      if (error) {
        return { thread: null, error: error.message }
      }

      // Increment view count if requested
      if (options.incrementViews && thread) {
        await supabase
          .from('threads')
          .update({ view_count: thread.view_count + 1 })
          .eq('id', threadId)

        thread.view_count += 1
      }

      return { thread, error: null }
    } catch (error) {
      return {
        thread: null,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Update thread
   */
  static async updateThread(
    threadId: string,
    updates: ThreadUpdate,
    options?: { useServerClient?: boolean }
  ): Promise<{ thread: Thread | null; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      const updateData: ThreadUpdate = {
        ...updates,
        updated_at: new Date().toISOString(),
      }

      // If content is being updated, mark as edited
      if (updates.content) {
        updateData.edited_at = new Date().toISOString()
      }

      const { data: thread, error } = await supabase
        .from('threads')
        .update(updateData)
        .eq('id', threadId)
        .select()
        .single()

      if (error) {
        return { thread: null, error: error.message }
      }

      return { thread, error: null }
    } catch (error) {
      return {
        thread: null,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Delete thread (soft delete)
   */
  static async deleteThread(
    threadId: string,
    options?: { hard?: boolean; useServerClient?: boolean }
  ): Promise<{ success: boolean; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      if (options?.hard) {
        // Hard delete (use with caution)
        const { error } = await supabase
          .from('threads')
          .delete()
          .eq('id', threadId)

        return { success: !error, error: error?.message || null }
      } else {
        // Soft delete
        const { error } = await supabase
          .from('threads')
          .update({
            is_deleted: true,
            updated_at: new Date().toISOString(),
          })
          .eq('id', threadId)

        return { success: !error, error: error?.message || null }
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Search threads
   */
  static async searchThreads(
    query: string,
    options: {
      categoryId?: string
      limit?: number
      offset?: number
    } = {}
  ): Promise<{ threads: Thread[]; error: string | null }> {
    try {
      const supabase = getBrowserSupabaseClient()
      const { limit = 20, offset = 0 } = options

      const { data: threads, error } = await supabase.rpc('search_threads', {
        search_query: query,
        category_filter: options.categoryId || null,
        limit_count: limit,
        offset_count: offset,
      })

      if (error) {
        return { threads: [], error: error.message }
      }

      return { threads: threads || [], error: null }
    } catch (error) {
      return {
        threads: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Get hot threads across all categories
   */
  static async getHotThreads(
    options: {
      limit?: number
      offset?: number
      minLevel?: UserLevel
    } = {}
  ): Promise<{ threads: Thread[]; error: string | null }> {
    try {
      const supabase = getBrowserSupabaseClient()
      const { limit = 20, offset = 0 } = options

      let query = supabase
        .from('threads')
        .select(
          `
          *,
          users!threads_user_id_fkey(username, avatar_url, level, is_bot),
          categories!threads_category_id_fkey(name, slug)
        `
        )
        .eq('is_removed', false)
        .eq('is_spam', false)
        .gte('hot_score', 1)
        .order('hot_score', { ascending: false })

      if (options.minLevel) {
        query = query.gte('users.level', options.minLevel)
      }

      query = query.range(offset, offset + limit - 1)

      const { data: threads, error } = await query

      if (error) {
        return { threads: [], error: error.message }
      }

      return { threads: threads || [], error: null }
    } catch (error) {
      return {
        threads: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Calculate Reddit-style hot score
   */
  static calculateHotScore(
    upvotes: number,
    downvotes: number,
    createdAt: Date
  ): number {
    const score = upvotes - downvotes
    const order = Math.log10(Math.max(Math.abs(score), 1))
    const sign = score > 0 ? 1 : score < 0 ? -1 : 0
    const seconds =
      (createdAt.getTime() - new Date('2005-12-08T06:00:00Z').getTime()) / 1000

    return sign * order + seconds / 45000
  }

  /**
   * Calculate Wilson score confidence interval
   */
  static calculateWilsonScore(
    upvotes: number,
    downvotes: number,
    confidence: number = 0.95
  ): number {
    const n = upvotes + downvotes
    if (n === 0) return 0

    const p = upvotes / n
    const z = 1.96 // 95% confidence

    return (
      (p +
        (z * z) / (2 * n) -
        z * Math.sqrt((p * (1 - p) + (z * z) / (4 * n)) / n)) /
      (1 + (z * z) / n)
    )
  }

  /**
   * Update hot scores for recent threads (maintenance function)
   */
  static async updateHotScores(options?: {
    useServerClient?: boolean
  }): Promise<{ updated: number; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      // Get threads from the last week
      const weekAgo = new Date()
      weekAgo.setDate(weekAgo.getDate() - 7)

      const { data: threads, error: fetchError } = await supabase
        .from('threads')
        .select('id, upvotes, downvotes, created_at')
        .gte('created_at', weekAgo.toISOString())

      if (fetchError) {
        return { updated: 0, error: fetchError.message }
      }

      let updated = 0
      for (const thread of threads || []) {
        const hotScore = this.calculateHotScore(
          thread.upvotes,
          thread.downvotes,
          new Date(thread.created_at)
        )

        const wilsonScore = this.calculateWilsonScore(
          thread.upvotes,
          thread.downvotes
        )

        const { error: updateError } = await supabase
          .from('threads')
          .update({
            hot_score: hotScore,
            wilson_score: wilsonScore,
            updated_at: new Date().toISOString(),
          })
          .eq('id', thread.id)

        if (!updateError) {
          updated++
        }
      }

      return { updated, error: null }
    } catch (error) {
      return {
        updated: 0,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }
}
