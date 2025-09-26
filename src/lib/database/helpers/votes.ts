import type {
  Tables,
  TablesInsert,
  VoteType,
  ContentType,
} from '../types/database.types'
import { createServerSupabaseClient } from '../lib/server'
import { getBrowserSupabaseClient } from '../lib/browser'

export type Vote = Tables<'votes'>
export type VoteInsert = TablesInsert<'votes'>

export interface VoteStats {
  upvotes: number
  downvotes: number
  score: number
  user_vote?: VoteType | null
}

/**
 * Voting system utilities
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

      // Check if user already voted on this content
      const { data: existingVote, error: checkError } = await supabase
        .from('votes')
        .select('*')
        .eq('user_id', userId)
        .eq('content_type', contentType)
        .eq('content_id', contentId)
        .single()

      if (checkError && checkError.code !== 'PGRST116') {
        return { success: false, error: checkError.message }
      }

      if (existingVote) {
        if (existingVote.vote_type === voteType) {
          // User is trying to vote the same way - remove vote
          const { error: deleteError } = await supabase
            .from('votes')
            .delete()
            .eq('id', existingVote.id)

          if (deleteError) {
            return { success: false, error: deleteError.message }
          }

          return { success: true, error: null }
        } else {
          // User is changing their vote
          const { data: updatedVote, error: updateError } = await supabase
            .from('votes')
            .update({ vote_type: voteType })
            .eq('id', existingVote.id)
            .select()
            .single()

          if (updateError) {
            return { success: false, error: updateError.message }
          }

          return { success: true, vote: updatedVote, error: null }
        }
      } else {
        // New vote
        const { data: newVote, error: insertError } = await supabase
          .from('votes')
          .insert({
            user_id: userId,
            content_type: contentType,
            content_id: contentId,
            vote_type: voteType,
          })
          .select()
          .single()

        if (insertError) {
          return { success: false, error: insertError.message }
        }

        return { success: true, vote: newVote, error: null }
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
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

      // Get vote counts
      const { data: votes, error: votesError } = await supabase
        .from('votes')
        .select('vote_type')
        .eq('content_type', contentType)
        .eq('content_id', contentId)

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
        const { data: userVoteData } = await supabase
          .from('votes')
          .select('vote_type')
          .eq('user_id', userId)
          .eq('content_type', contentType)
          .eq('content_id', contentId)
          .single()

        userVote = userVoteData?.vote_type || null
      }

      const stats: VoteStats = {
        upvotes,
        downvotes,
        score,
        user_vote: userVote,
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
      const { limit = 50, offset = 0 } = options

      let query = supabase.from('votes').select('*').eq('user_id', userId)

      if (options.contentType) {
        query = query.eq('content_type', options.contentType)
      }

      query = query
        .order('created_at', { ascending: false })
        .range(offset, offset + limit - 1)

      const { data: votes, error } = await query

      if (error) {
        return { votes: [], error: error.message }
      }

      return { votes: votes || [], error: null }
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
      const { timeframe = 'all', limit = 20, offset = 0 } = options

      let query = supabase
        .from('votes')
        .select('content_id, vote_type')
        .eq('content_type', contentType)

      // Apply timeframe filter
      if (timeframe !== 'all') {
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
          case 'year':
            timeAgo = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000)
            break
          default:
            timeAgo = new Date(0)
        }

        query = query.gte('created_at', timeAgo.toISOString())
      }

      const { data: votes, error } = await query

      if (error) {
        return { content: [], error: error.message }
      }

      // Aggregate votes by content
      const voteMap = new Map<string, { upvotes: number; downvotes: number }>()

      votes?.forEach(vote => {
        const existing = voteMap.get(vote.content_id) || {
          upvotes: 0,
          downvotes: 0,
        }

        if (vote.vote_type === 'upvote') {
          existing.upvotes++
        } else {
          existing.downvotes++
        }

        voteMap.set(vote.content_id, existing)
      })

      // Convert to array and sort by score
      const content = Array.from(voteMap.entries())
        .map(([content_id, votes]) => ({
          content_id,
          upvotes: votes.upvotes,
          downvotes: votes.downvotes,
          score: votes.upvotes - votes.downvotes,
        }))
        .sort((a, b) => b.score - a.score)
        .slice(offset, offset + limit)

      return { content, error: null }
    } catch (error) {
      return {
        content: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
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
      const {
        timeframe = 'all',
        limit = 20,
        offset = 0,
        minVotes = 5,
      } = options

      let query = supabase
        .from('votes')
        .select('content_id, vote_type')
        .eq('content_type', contentType)

      // Apply timeframe filter
      if (timeframe !== 'all') {
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
          case 'year':
            timeAgo = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000)
            break
          default:
            timeAgo = new Date(0)
        }

        query = query.gte('created_at', timeAgo.toISOString())
      }

      const { data: votes, error } = await query

      if (error) {
        return { content: [], error: error.message }
      }

      // Aggregate votes by content
      const voteMap = new Map<string, { upvotes: number; downvotes: number }>()

      votes?.forEach(vote => {
        const existing = voteMap.get(vote.content_id) || {
          upvotes: 0,
          downvotes: 0,
        }

        if (vote.vote_type === 'upvote') {
          existing.upvotes++
        } else {
          existing.downvotes++
        }

        voteMap.set(vote.content_id, existing)
      })

      // Convert to array and calculate controversy score
      const content = Array.from(voteMap.entries())
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

      return { content, error: null }
    } catch (error) {
      return {
        content: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
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

      const { data: votes, error } = await supabase
        .from('votes')
        .select('vote_type, created_at')
        .eq('content_type', contentType)
        .eq('content_id', contentId)
        .gte('created_at', timeAgo.toISOString())
        .order('created_at', { ascending: true })

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

      votes?.forEach(vote => {
        const voteTime = new Date(vote.created_at)
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
    voteId: string,
    options?: { useServerClient?: boolean }
  ): Promise<{ success: boolean; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      const { error } = await supabase.from('votes').delete().eq('id', voteId)

      return { success: !error, error: error?.message || null }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }
}
