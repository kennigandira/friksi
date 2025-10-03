import type {
  Tables,
  TablesInsert,
  VoteType,
  ContentType,
} from '../types/database.types'
import { createServerSupabaseClient } from '../lib/server'
import { getBrowserSupabaseClient } from '../lib/browser'
import { getTypedClient, TableInsert, TableUpdate } from '../lib/typed-client'

export type ThreadVote = Tables<'thread_votes'>
export type CommentVote = Tables<'comment_votes'>
export type ThreadVoteInsert = TablesInsert<'thread_votes'>
export type CommentVoteInsert = TablesInsert<'comment_votes'>

// Union type for all votes
export type Vote = ThreadVote | CommentVote

export interface VoteStats {
  upvotes: number
  downvotes: number
  score: number
  user_vote?: VoteType | null
}

/**
 * Voting system utilities
 *
 * Note: Votes are stored in separate tables (thread_votes and comment_votes)
 * based on content type, but this helper provides a unified API.
 */
export class VoteHelpers {
  /**
   * Cast a vote on content (thread or comment)
   */
  static async castVote(
    userId: string,
    contentType: ContentType,
    contentId: string,
    voteType: VoteType,
    options?: { useServerClient?: boolean }
  ): Promise<{ success: boolean; vote?: Vote; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      const typedClient = getTypedClient(supabase)

      // Route to appropriate table based on content type
      if (contentType === 'thread') {
        return await this.castThreadVote(
          userId,
          contentId,
          voteType,
          typedClient
        )
      } else {
        return await this.castCommentVote(
          userId,
          contentId,
          voteType,
          typedClient
        )
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  private static async castThreadVote(
    userId: string,
    threadId: string,
    voteType: VoteType,
    typedClient: ReturnType<typeof getTypedClient>
  ): Promise<{ success: boolean; vote?: Vote; error: string | null }> {
    // Check if user already voted
    const { data: existingVote, error: checkError } = await typedClient
      .from('thread_votes')
      .select('*')
      .eq('user_id', userId)
      .eq('thread_id', threadId)
      .maybeSingle()

    if (checkError) {
      return { success: false, error: checkError.message }
    }

    if (existingVote) {
      if (existingVote.vote_type === voteType) {
        // User is trying to vote the same way - remove vote
        const { error: deleteError } = await typedClient
          .from('thread_votes')
          .delete()
          .eq('user_id', userId)
          .eq('thread_id', threadId)

        if (deleteError) {
          return { success: false, error: deleteError.message }
        }

        return { success: true, error: null }
      } else {
        // User is changing their vote - update it
        const { data: updatedVote, error: updateError } = await typedClient
          .from('thread_votes')
          .update({ vote_type: voteType } as TableUpdate<'thread_votes'>)
          .eq('user_id', userId)
          .eq('thread_id', threadId)
          .select()
          .single()

        if (updateError) {
          return { success: false, error: updateError.message }
        }

        return { success: true, vote: updatedVote, error: null }
      }
    } else {
      // New vote
      const voteData: TableInsert<'thread_votes'> = {
        user_id: userId,
        thread_id: threadId,
        vote_type: voteType,
      }

      const { data: newVote, error: insertError } = await typedClient
        .from('thread_votes')
        .insert(voteData)
        .select()
        .single()

      if (insertError) {
        return { success: false, error: insertError.message }
      }

      return { success: true, vote: newVote, error: null }
    }
  }

  private static async castCommentVote(
    userId: string,
    commentId: string,
    voteType: VoteType,
    typedClient: ReturnType<typeof getTypedClient>
  ): Promise<{ success: boolean; vote?: Vote; error: string | null }> {
    // Check if user already voted
    const { data: existingVote, error: checkError } = await typedClient
      .from('comment_votes')
      .select('*')
      .eq('user_id', userId)
      .eq('comment_id', commentId)
      .maybeSingle()

    if (checkError) {
      return { success: false, error: checkError.message }
    }

    if (existingVote) {
      if (existingVote.vote_type === voteType) {
        // User is trying to vote the same way - remove vote
        const { error: deleteError } = await typedClient
          .from('comment_votes')
          .delete()
          .eq('user_id', userId)
          .eq('comment_id', commentId)

        if (deleteError) {
          return { success: false, error: deleteError.message }
        }

        return { success: true, error: null }
      } else {
        // User is changing their vote - update it
        const { data: updatedVote, error: updateError } = await typedClient
          .from('comment_votes')
          .update({ vote_type: voteType } as TableUpdate<'comment_votes'>)
          .eq('user_id', userId)
          .eq('comment_id', commentId)
          .select()
          .single()

        if (updateError) {
          return { success: false, error: updateError.message }
        }

        return { success: true, vote: updatedVote, error: null }
      }
    } else {
      // New vote
      const voteData: TableInsert<'comment_votes'> = {
        user_id: userId,
        comment_id: commentId,
        vote_type: voteType,
      }

      const { data: newVote, error: insertError } = await typedClient
        .from('comment_votes')
        .insert(voteData)
        .select()
        .single()

      if (insertError) {
        return { success: false, error: insertError.message }
      }

      return { success: true, vote: newVote, error: null }
    }
  }

  /**
   * Get vote statistics for content
   */
  static async getVoteStats(
    contentType: ContentType,
    contentId: string,
    userId?: string
  ): Promise<{ stats: VoteStats | null; error: string | null }> {
    try {
      const supabase = getBrowserSupabaseClient()
      const typedClient = getTypedClient(supabase)

      if (contentType === 'thread') {
        return await this.getThreadVoteStats(contentId, userId, typedClient)
      } else {
        return await this.getCommentVoteStats(contentId, userId, typedClient)
      }
    } catch (error) {
      return {
        stats: null,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  private static async getThreadVoteStats(
    threadId: string,
    userId: string | undefined,
    typedClient: ReturnType<typeof getTypedClient>
  ): Promise<{ stats: VoteStats | null; error: string | null }> {
    // Get vote counts
    const { data: votes, error: votesError } = await typedClient
      .from('thread_votes')
      .select('vote_type')
      .eq('thread_id', threadId)

    if (votesError) {
      return { stats: null, error: votesError.message }
    }

    const upvotes = votes?.filter(v => v.vote_type === 'upvote').length || 0
    const downvotes =
      votes?.filter(v => v.vote_type === 'downvote').length || 0
    const score = upvotes - downvotes

    let userVote: VoteType | null = null

    // Get user's vote if userId provided
    if (userId) {
      const { data: userVoteData } = await typedClient
        .from('thread_votes')
        .select('vote_type')
        .eq('user_id', userId)
        .eq('thread_id', threadId)
        .maybeSingle()

      userVote = (userVoteData?.vote_type as VoteType) || null
    }

    const stats: VoteStats = {
      upvotes,
      downvotes,
      score,
      user_vote: userVote,
    }

    return { stats, error: null }
  }

  private static async getCommentVoteStats(
    commentId: string,
    userId: string | undefined,
    typedClient: ReturnType<typeof getTypedClient>
  ): Promise<{ stats: VoteStats | null; error: string | null }> {
    // Get vote counts
    const { data: votes, error: votesError } = await typedClient
      .from('comment_votes')
      .select('vote_type')
      .eq('comment_id', commentId)

    if (votesError) {
      return { stats: null, error: votesError.message }
    }

    const upvotes = votes?.filter(v => v.vote_type === 'upvote').length || 0
    const downvotes =
      votes?.filter(v => v.vote_type === 'downvote').length || 0
    const score = upvotes - downvotes

    let userVote: VoteType | null = null

    // Get user's vote if userId provided
    if (userId) {
      const { data: userVoteData } = await typedClient
        .from('comment_votes')
        .select('vote_type')
        .eq('user_id', userId)
        .eq('comment_id', commentId)
        .maybeSingle()

      userVote = (userVoteData?.vote_type as VoteType) || null
    }

    const stats: VoteStats = {
      upvotes,
      downvotes,
      score,
      user_vote: userVote,
    }

    return { stats, error: null }
  }

  /**
   * Get user's voting history
   */
  static async getUserVotes(
    userId: string,
    options: {
      contentType?: ContentType
      limit?: number
      offset?: number
    } = {}
  ): Promise<{ votes: Vote[]; error: string | null }> {
    try {
      const supabase = getBrowserSupabaseClient()
      const typedClient = getTypedClient(supabase)
      const { limit = 50, offset = 0, contentType } = options

      // If content type specified, query only that table
      if (contentType === 'thread') {
        const { data: threadVotes, error } = await typedClient
          .from('thread_votes')
          .select('*')
          .eq('user_id', userId)
          .order('voted_at', { ascending: false })
          .range(offset, offset + limit - 1)

        if (error) {
          return { votes: [], error: error.message }
        }

        return { votes: threadVotes || [], error: null }
      } else if (contentType === 'comment') {
        const { data: commentVotes, error } = await typedClient
          .from('comment_votes')
          .select('*')
          .eq('user_id', userId)
          .order('voted_at', { ascending: false })
          .range(offset, offset + limit - 1)

        if (error) {
          return { votes: [], error: error.message }
        }

        return { votes: commentVotes || [], error: null }
      } else {
        // Get both types and merge
        const [threadResult, commentResult] = await Promise.all([
          typedClient
            .from('thread_votes')
            .select('*')
            .eq('user_id', userId)
            .order('voted_at', { ascending: false })
            .range(offset, offset + limit - 1),
          typedClient
            .from('comment_votes')
            .select('*')
            .eq('user_id', userId)
            .order('voted_at', { ascending: false })
            .range(offset, offset + limit - 1),
        ])

        if (threadResult.error || commentResult.error) {
          return {
            votes: [],
            error: threadResult.error?.message || commentResult.error?.message || 'Unknown error',
          }
        }

        // Merge and sort by date
        const allVotes = [
          ...(threadResult.data || []),
          ...(commentResult.data || []),
        ].sort((a, b) => {
          const dateA = new Date(a.voted_at || 0).getTime()
          const dateB = new Date(b.voted_at || 0).getTime()
          return dateB - dateA
        })

        return { votes: allVotes.slice(0, limit), error: null }
      }
    } catch (error) {
      return {
        votes: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Get most upvoted content
   */
  static async getMostUpvotedContent(
    contentType: ContentType,
    options: {
      timeframe?: 'day' | 'week' | 'month' | 'year' | 'all'
      limit?: number
      offset?: number
    } = {}
  ): Promise<{
    content: Array<{
      content_id: string
      upvotes: number
      downvotes: number
      score: number
    }>
    error: string | null
  }> {
    try {
      const supabase = getBrowserSupabaseClient()
      const typedClient = getTypedClient(supabase)
      const { timeframe = 'all', limit = 20, offset = 0 } = options

      // Calculate timeframe filter
      let timeAgo: Date | null = null
      if (timeframe !== 'all') {
        const now = new Date()
        switch (timeframe) {
          case 'day':
            timeAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000)
            break
          case 'week':
            timeAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
            break
          case 'month':
            timeAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000)
            break
          case 'year':
            timeAgo = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000)
            break
        }
      }

      if (contentType === 'thread') {
        let query = typedClient
          .from('thread_votes')
          .select('thread_id, vote_type')

        if (timeAgo) {
          query = query.gte('voted_at', timeAgo.toISOString())
        }

        const { data: votes, error } = await query

        if (error) {
          return { content: [], error: error.message }
        }

        return {
          content: this.aggregateVotes(votes || [], 'thread_id', limit, offset),
          error: null,
        }
      } else {
        let query = typedClient
          .from('comment_votes')
          .select('comment_id, vote_type')

        if (timeAgo) {
          query = query.gte('voted_at', timeAgo.toISOString())
        }

        const { data: votes, error } = await query

        if (error) {
          return { content: [], error: error.message }
        }

        return {
          content: this.aggregateVotes(
            votes || [],
            'comment_id',
            limit,
            offset
          ),
          error: null,
        }
      }
    } catch (error) {
      return {
        content: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  private static aggregateVotes(
    votes: Array<{ vote_type: string; [key: string]: any }>,
    idField: string,
    limit: number,
    offset: number
  ): Array<{
    content_id: string
    upvotes: number
    downvotes: number
    score: number
  }> {
    const voteMap = new Map<string, { upvotes: number; downvotes: number }>()

    votes.forEach(vote => {
      const contentId = vote[idField]
      const existing = voteMap.get(contentId) || {
        upvotes: 0,
        downvotes: 0,
      }

      if (vote.vote_type === 'upvote') {
        existing.upvotes++
      } else {
        existing.downvotes++
      }

      voteMap.set(contentId, existing)
    })

    return Array.from(voteMap.entries())
      .map(([content_id, votes]) => ({
        content_id,
        upvotes: votes.upvotes,
        downvotes: votes.downvotes,
        score: votes.upvotes - votes.downvotes,
      }))
      .sort((a, b) => b.score - a.score)
      .slice(offset, offset + limit)
  }

  /**
   * Get controversial content (high engagement, low score)
   */
  static async getControversialContent(
    contentType: ContentType,
    options: {
      timeframe?: 'day' | 'week' | 'month' | 'year' | 'all'
      limit?: number
      offset?: number
      minVotes?: number
    } = {}
  ): Promise<{
    content: Array<{
      content_id: string
      upvotes: number
      downvotes: number
      score: number
      total_votes: number
      controversy_score: number
    }>
    error: string | null
  }> {
    try {
      const supabase = getBrowserSupabaseClient()
      const typedClient = getTypedClient(supabase)
      const {
        timeframe = 'all',
        limit = 20,
        offset = 0,
        minVotes = 5,
      } = options

      // Calculate timeframe filter
      let timeAgo: Date | null = null
      if (timeframe !== 'all') {
        const now = new Date()
        switch (timeframe) {
          case 'day':
            timeAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000)
            break
          case 'week':
            timeAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
            break
          case 'month':
            timeAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000)
            break
          case 'year':
            timeAgo = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000)
            break
        }
      }

      if (contentType === 'thread') {
        let query = typedClient
          .from('thread_votes')
          .select('thread_id, vote_type')

        if (timeAgo) {
          query = query.gte('voted_at', timeAgo.toISOString())
        }

        const { data: votes, error } = await query

        if (error) {
          return { content: [], error: error.message }
        }

        return {
          content: this.calculateControversy(
            votes || [],
            'thread_id',
            minVotes,
            limit,
            offset
          ),
          error: null,
        }
      } else {
        let query = typedClient
          .from('comment_votes')
          .select('comment_id, vote_type')

        if (timeAgo) {
          query = query.gte('voted_at', timeAgo.toISOString())
        }

        const { data: votes, error } = await query

        if (error) {
          return { content: [], error: error.message }
        }

        return {
          content: this.calculateControversy(
            votes || [],
            'comment_id',
            minVotes,
            limit,
            offset
          ),
          error: null,
        }
      }
    } catch (error) {
      return {
        content: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  private static calculateControversy(
    votes: Array<{ vote_type: string; [key: string]: any }>,
    idField: string,
    minVotes: number,
    limit: number,
    offset: number
  ): Array<{
    content_id: string
    upvotes: number
    downvotes: number
    score: number
    total_votes: number
    controversy_score: number
  }> {
    const voteMap = new Map<string, { upvotes: number; downvotes: number }>()

    votes.forEach(vote => {
      const contentId = vote[idField]
      const existing = voteMap.get(contentId) || {
        upvotes: 0,
        downvotes: 0,
      }

      if (vote.vote_type === 'upvote') {
        existing.upvotes++
      } else {
        existing.downvotes++
      }

      voteMap.set(contentId, existing)
    })

    return Array.from(voteMap.entries())
      .map(([content_id, votes]) => {
        const total_votes = votes.upvotes + votes.downvotes
        const score = votes.upvotes - votes.downvotes

        // Controversy score: high engagement with score close to 0
        const controversy_score =
          total_votes * (1 - Math.abs(score) / total_votes)

        return {
          content_id,
          upvotes: votes.upvotes,
          downvotes: votes.downvotes,
          score,
          total_votes,
          controversy_score,
        }
      })
      .filter(item => item.total_votes >= minVotes)
      .sort((a, b) => b.controversy_score - a.controversy_score)
      .slice(offset, offset + limit)
  }

  /**
   * Get vote trends over time
   */
  static async getVoteTrends(
    contentId: string,
    contentType: ContentType,
    options: {
      timeframe?: 'day' | 'week' | 'month'
      interval?: 'hour' | 'day'
    } = {}
  ): Promise<{
    trends: Array<{
      timestamp: string
      upvotes: number
      downvotes: number
      cumulative_score: number
    }>
    error: string | null
  }> {
    try {
      const supabase = getBrowserSupabaseClient()
      const typedClient = getTypedClient(supabase)
      const { timeframe = 'week', interval = 'day' } = options

      const now = new Date()
      let timeAgo: Date

      switch (timeframe) {
        case 'day':
          timeAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000)
          break
        case 'week':
          timeAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
          break
        case 'month':
          timeAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000)
          break
        default:
          timeAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
      }

      let votes: Array<{ vote_type: string; voted_at: string | null }> = []
      let error: any = null

      if (contentType === 'thread') {
        const result = await typedClient
          .from('thread_votes')
          .select('vote_type, voted_at')
          .eq('thread_id', contentId)
          .gte('voted_at', timeAgo.toISOString())
          .order('voted_at', { ascending: true })

        votes = result.data || []
        error = result.error
      } else {
        const result = await typedClient
          .from('comment_votes')
          .select('vote_type, voted_at')
          .eq('comment_id', contentId)
          .gte('voted_at', timeAgo.toISOString())
          .order('voted_at', { ascending: true })

        votes = result.data || []
        error = result.error
      }

      if (error) {
        return { trends: [], error: error.message }
      }

      // Group votes by time interval
      const trends: Array<{
        timestamp: string
        upvotes: number
        downvotes: number
        cumulative_score: number
      }> = []

      let cumulativeScore = 0
      const intervalMs =
        interval === 'hour' ? 60 * 60 * 1000 : 24 * 60 * 60 * 1000

      const timeSlots = new Map<
        string,
        { upvotes: number; downvotes: number }
      >()

      votes.forEach(vote => {
        if (!vote.voted_at) return

        const voteTime = new Date(vote.voted_at)
        const slotTime = new Date(
          Math.floor(voteTime.getTime() / intervalMs) * intervalMs
        )
        const slotKey = slotTime.toISOString()

        const existing = timeSlots.get(slotKey) || { upvotes: 0, downvotes: 0 }

        if (vote.vote_type === 'upvote') {
          existing.upvotes++
        } else {
          existing.downvotes++
        }

        timeSlots.set(slotKey, existing)
      })

      // Convert to array and calculate cumulative scores
      Array.from(timeSlots.entries())
        .sort(([a], [b]) => a.localeCompare(b))
        .forEach(([timestamp, votes]) => {
          const periodScore = votes.upvotes - votes.downvotes
          cumulativeScore += periodScore

          trends.push({
            timestamp,
            upvotes: votes.upvotes,
            downvotes: votes.downvotes,
            cumulative_score: cumulativeScore,
          })
        })

      return { trends, error: null }
    } catch (error) {
      return {
        trends: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Remove a vote (admin function)
   */
  static async removeVote(
    contentType: ContentType,
    userId: string,
    contentId: string,
    options?: { useServerClient?: boolean }
  ): Promise<{ success: boolean; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      const typedClient = getTypedClient(supabase)

      if (contentType === 'thread') {
        const { error } = await typedClient
          .from('thread_votes')
          .delete()
          .eq('user_id', userId)
          .eq('thread_id', contentId)

        return { success: !error, error: error?.message || null }
      } else {
        const { error } = await typedClient
          .from('comment_votes')
          .delete()
          .eq('user_id', userId)
          .eq('comment_id', contentId)

        return { success: !error, error: error?.message || null }
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }
}