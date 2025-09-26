import type {
  Tables,
  TablesInsert,
  TablesUpdate,
} from '../types/database.types'
import { createServerSupabaseClient } from '../lib/server'
import { getBrowserSupabaseClient } from '../lib/browser'

export type Comment = Tables<'comments'>
export type CommentInsert = TablesInsert<'comments'>
export type CommentUpdate = TablesUpdate<'comments'>

export interface CommentWithUser extends Comment {
  users: {
    username: string
    avatar_url: string | null
    level: number
    is_bot: boolean
  } | null
}

export interface NestedComment extends CommentWithUser {
  replies?: NestedComment[]
  replyCount: number
}

/**
 * Comment management utilities with LTREE support
 */
export class CommentHelpers {
  /**
   * Create a new comment
   */
  static async createComment(
    data: Omit<
      CommentInsert,
      'id' | 'created_at' | 'updated_at' | 'path' | 'depth'
    >,
    options?: { useServerClient?: boolean }
  ): Promise<{ comment: Comment | null; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      // Generate comment path and depth
      let path: string
      let depth = 0

      if (data.parent_id) {
        // Get parent comment to build path
        const { data: parentComment, error: parentError } = await supabase
          .from('comments')
          .select('path, depth')
          .eq('id', data.parent_id)
          .single() as { data: { path: string; depth: number } | null; error: any }

        if (parentError || !parentComment) {
          return { comment: null, error: 'Parent comment not found' }
        }

        // Create path as parent_path.new_comment_id (we'll update after insert)
        depth = parentComment.depth + 1

        if (depth > 10) {
          return { comment: null, error: 'Maximum nesting depth exceeded' }
        }
      }

      // Insert comment (path will be set by trigger)
      const { data: comment, error } = await (supabase
        .from('comments')
        .insert({
          ...data,
          wilson_score: 0,
        } as any)
        .select()
        .single())

      if (error) {
        return { comment: null, error: error.message }
      }

      return { comment, error: null }
    } catch (error) {
      return {
        comment: null,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Get comments for a thread with nested structure
   */
  static async getThreadComments(
    threadId: string,
    options: {
      sortBy?: 'best' | 'new' | 'controversial'
      limit?: number
      maxDepth?: number
      includeRemoved?: boolean
    } = {}
  ): Promise<{ comments: NestedComment[]; error: string | null }> {
    try {
      const supabase = getBrowserSupabaseClient()
      const {
        sortBy = 'best',
        limit = 100,
        maxDepth = 10,
        includeRemoved = false,
      } = options

      let query = supabase
        .from('comments')
        .select(
          `
          *,
          users!comments_user_id_fkey(username, avatar_url, level, is_bot)
        `
        )
        .eq('thread_id', threadId)

      if (!includeRemoved) {
        query = query.eq('is_removed', false)
      }

      if (maxDepth < 10) {
        query = query.lte('depth', maxDepth)
      }

      // Apply sorting
      switch (sortBy) {
        case 'best':
          query = query.order('wilson_score', { ascending: false })
          break
        case 'new':
          query = query.order('created_at', { ascending: false })
          break
        case 'controversial':
          // Sort by high engagement but low wilson score
          query = query.order('upvotes', { ascending: false })
          break
      }

      // Order by path to maintain tree structure
      query = query.order('path', { ascending: true })

      if (limit) {
        query = query.limit(limit)
      }

      const { data: comments, error } = await query

      if (error) {
        return { comments: [], error: error.message }
      }

      // Build nested structure
      const nestedComments = this.buildCommentTree(comments || [])

      return { comments: nestedComments, error: null }
    } catch (error) {
      return {
        comments: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Get comment with its replies
   */
  static async getCommentWithReplies(
    commentId: string,
    options: {
      maxDepth?: number
      includeRemoved?: boolean
    } = {}
  ): Promise<{ comment: NestedComment | null; error: string | null }> {
    try {
      const supabase = getBrowserSupabaseClient()
      const { maxDepth = 5, includeRemoved = false } = options

      // Get the main comment
      const { data: mainComment, error: mainError } = await supabase
        .from('comments')
        .select(
          `
          *,
          users!comments_user_id_fkey(username, avatar_url, level, is_bot)
        `
        )
        .eq('id', commentId)
        .single() as { data: any; error: any }

      if (mainError || !mainComment) {
        return { comment: null, error: 'Comment not found' }
      }

      // Get all replies using LTREE path matching
      let repliesQuery = supabase
        .from('comments')
        .select(
          `
          *,
          users!comments_user_id_fkey(username, avatar_url, level, is_bot)
        `
        )
        .textSearch('path', `${mainComment.path}.*{1,${maxDepth}}`, {
          type: 'websearch',
        })

      if (!includeRemoved) {
        repliesQuery = repliesQuery.eq('is_removed', false)
      }

      const { data: replies, error: repliesError } = await repliesQuery.order(
        'path',
        { ascending: true }
      )

      if (repliesError) {
        return { comment: null, error: repliesError.message }
      }

      // Build nested structure including the main comment
      const allComments = [mainComment, ...(replies || [])]
      const nestedComments = this.buildCommentTree(allComments)

      return { comment: nestedComments[0] || null, error: null }
    } catch (error) {
      return {
        comment: null,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Update comment
   */
  static async updateComment(
    commentId: string,
    updates: CommentUpdate,
    options?: { useServerClient?: boolean }
  ): Promise<{ comment: Comment | null; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      const updateData: CommentUpdate = {
        ...updates,
        updated_at: new Date().toISOString(),
      }

      // If content is being updated, mark as edited
      if (updates.content) {
        updateData.edited_at = new Date().toISOString()
      }

      // Recalculate Wilson score if votes changed
      if (updates.upvotes !== undefined || updates.downvotes !== undefined) {
        const { data: currentComment } = await supabase
          .from('comments')
          .select('upvotes, downvotes')
          .eq('id', commentId)
          .single() as { data: { upvotes: number; downvotes: number } | null }

        if (currentComment) {
          const upvotes = updates.upvotes ?? currentComment.upvotes
          const downvotes = updates.downvotes ?? currentComment.downvotes
          updateData.wilson_score = this.calculateWilsonScore(
            upvotes,
            downvotes
          )
        }
      }

      const { data: comment, error } = await ((supabase as any)
        .from('comments')
        .update(updateData)
        .eq('id', commentId)
        .select()
        .single())

      if (error) {
        return { comment: null, error: error.message }
      }

      return { comment, error: null }
    } catch (error) {
      return {
        comment: null,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Delete comment (soft delete)
   */
  static async deleteComment(
    commentId: string,
    options?: { hard?: boolean; useServerClient?: boolean }
  ): Promise<{ success: boolean; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      if (options?.hard) {
        // Hard delete (use with caution - will affect reply tree)
        const { error } = await supabase
          .from('comments')
          .delete()
          .eq('id', commentId)

        return { success: !error, error: error?.message || null }
      } else {
        // Soft delete
        const { error } = await (supabase as any)
          .from('comments')
          .update({
            is_deleted: true,
            content: '[deleted]',
            updated_at: new Date().toISOString(),
          })
          .eq('id', commentId)

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
   * Get comment chain (from root to specific comment)
   */
  static async getCommentChain(
    commentId: string
  ): Promise<{ chain: Comment[]; error: string | null }> {
    try {
      const supabase = getBrowserSupabaseClient()

      // Get the target comment to get its path
      const { data: targetComment, error: targetError } = await supabase
        .from('comments')
        .select('path, thread_id')
        .eq('id', commentId)
        .single() as { data: { path: string; thread_id: string } | null; error: any }

      if (targetError || !targetComment) {
        return { chain: [], error: 'Comment not found' }
      }

      // Parse LTREE path to get all parent IDs
      const pathParts = targetComment.path.split('.')

      if (pathParts.length === 0) {
        return { chain: [], error: 'Invalid comment path' }
      }

      // Get all comments in the chain
      const { data: comments, error } = await supabase
        .from('comments')
        .select(
          `
          *,
          users!comments_user_id_fkey(username, avatar_url, level, is_bot)
        `
        )
        .in('id', pathParts)
        .order('depth', { ascending: true })

      if (error) {
        return { chain: [], error: error.message }
      }

      return { chain: comments || [], error: null }
    } catch (error) {
      return {
        chain: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Build nested comment tree from flat array
   */
  private static buildCommentTree(
    comments: CommentWithUser[]
  ): NestedComment[] {
    const commentMap = new Map<string, NestedComment>()
    const rootComments: NestedComment[] = []

    // First pass: create comment objects with reply arrays
    comments.forEach(comment => {
      const nestedComment: NestedComment = {
        ...comment,
        replies: [],
        replyCount: 0,
      }
      commentMap.set(comment.id, nestedComment)
    })

    // Second pass: build tree structure
    comments.forEach(comment => {
      const nestedComment = commentMap.get(comment.id)!

      if (comment.parent_id) {
        const parent = commentMap.get(comment.parent_id)
        if (parent) {
          parent.replies!.push(nestedComment)
          parent.replyCount++
        }
      } else {
        rootComments.push(nestedComment)
      }
    })

    // Third pass: sort replies by Wilson score for each level
    const sortReplies = (comments: NestedComment[]) => {
      comments.forEach(comment => {
        if (comment.replies && comment.replies.length > 0) {
          comment.replies.sort((a, b) => b.wilson_score - a.wilson_score)
          sortReplies(comment.replies)
        }
      })
    }

    sortReplies(rootComments)

    return rootComments
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
   * Get comment statistics
   */
  static async getCommentStats(commentId: string): Promise<{
    stats: {
      upvotes: number
      downvotes: number
      wilson_score: number
      reply_count: number
      total_descendants: number
    } | null
    error: string | null
  }> {
    try {
      const supabase = getBrowserSupabaseClient()

      // Get comment details
      const { data: comment, error: commentError } = await supabase
        .from('comments')
        .select('upvotes, downvotes, wilson_score, path')
        .eq('id', commentId)
        .single() as { data: { upvotes: number; downvotes: number; wilson_score: number; path: string } | null; error: any }

      if (commentError || !comment) {
        return { stats: null, error: 'Comment not found' }
      }

      // Count direct and total replies using LTREE
      const { count: directReplies } = await supabase
        .from('comments')
        .select('id', { count: 'exact' })
        .eq('parent_id', commentId)

      const { count: totalDescendants } = await supabase
        .from('comments')
        .select('id', { count: 'exact' })
        .textSearch('path', `${comment.path}.*`, { type: 'websearch' })

      return {
        stats: {
          upvotes: comment.upvotes,
          downvotes: comment.downvotes,
          wilson_score: comment.wilson_score,
          reply_count: directReplies || 0,
          total_descendants: totalDescendants || 0,
        },
        error: null,
      }
    } catch (error) {
      return {
        stats: null,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }
}
