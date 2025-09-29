'use client'

import { useState, useCallback, useEffect } from 'react'
import { VoteHelpers, VoteStats } from '@/lib/database/helpers/votes'
import { useAuth } from './useAuth'
import type { ContentType, VoteType } from '@/lib/database/types/database.types'

interface UseVotingProps {
  contentId: string
  contentType: ContentType
  initialUpvotes?: number
  initialDownvotes?: number
}

export function useVoting({
  contentId,
  contentType,
  initialUpvotes = 0,
  initialDownvotes = 0,
}: UseVotingProps) {
  const { user } = useAuth()
  const [loading, setLoading] = useState(false)
  const [stats, setStats] = useState<VoteStats>({
    upvotes: initialUpvotes,
    downvotes: initialDownvotes,
    score: initialUpvotes - initialDownvotes,
    user_vote: null,
  })

  const updateStatsOptimistically = (newVote: VoteType | null) => {
    setStats(currentStats => {
      let newUpvotes = currentStats.upvotes
      let newDownvotes = currentStats.downvotes

      // Remove previous vote effect
      if (currentStats.user_vote === 'upvote') {
        newUpvotes--
      } else if (currentStats.user_vote === 'downvote') {
        newDownvotes--
      }

      // Add new vote effect
      if (newVote === 'upvote') {
        newUpvotes++
      } else if (newVote === 'downvote') {
        newDownvotes++
      }

      return {
        upvotes: newUpvotes,
        downvotes: newDownvotes,
        score: newUpvotes - newDownvotes,
        user_vote: newVote,
      }
    })
  }

  const vote = useCallback(
    async (voteType: VoteType) => {
      if (!user) {
        // TODO: Show login prompt
        return { success: false, error: 'You must be logged in to vote' }
      }

      setLoading(true)

      // Optimistically update the UI
      const newVote = stats.user_vote === voteType ? null : voteType
      const previousVote = stats.user_vote || null
      updateStatsOptimistically(newVote)

      try {
        const result = await VoteHelpers.castVote(
          user.id,
          contentType,
          contentId,
          voteType
        )

        if (!result.success) {
          // Revert optimistic update on failure
          updateStatsOptimistically(previousVote)
        }

        return result
      } catch (error) {
        // Revert optimistic update on error
        updateStatsOptimistically(previousVote)
        return {
          success: false,
          error: error instanceof Error ? error.message : 'Failed to cast vote',
        }
      } finally {
        setLoading(false)
      }
    },
    [user, contentType, contentId, stats.user_vote]
  )

  const upvote = useCallback(() => vote('upvote'), [vote])
  const downvote = useCallback(() => vote('downvote'), [vote])

  // Load user's existing vote on mount
  useEffect(() => {
    const loadUserVote = async () => {
      if (user) {
        const { stats: fetchedStats } = await VoteHelpers.getVoteStats(
          contentType,
          contentId,
          user.id
        )
        if (fetchedStats) {
          setStats(fetchedStats)
        }
      }
    }

    loadUserVote()
  }, [user, contentType, contentId])

  return {
    stats,
    userVote: stats.user_vote,
    loading,
    upvote,
    downvote,
    vote,
  }
}