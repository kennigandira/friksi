'use client'

import { useState, useEffect } from 'react'
import { Card, Stack, ActionIcon, Text, Center } from '@mantine/core'
import { IconArrowUp, IconArrowDown } from '@tabler/icons-react'
import { useAuth } from '@/hooks/use-auth'
import { VoteHelpers, type VoteType, type ContentType } from '@/lib/database'
import { notifications } from '@mantine/notifications'
import { logger } from '@/lib/logger'

interface VotePanelProps {
  contentId: string
  contentType: ContentType
  initialUpvotes?: number
  initialDownvotes?: number
}

export function VotePanel({
  contentId,
  contentType,
  initialUpvotes = 0,
  initialDownvotes = 0,
}: VotePanelProps) {
  const { user } = useAuth()

  const [upvotes, setUpvotes] = useState(initialUpvotes)
  const [downvotes, setDownvotes] = useState(initialDownvotes)
  const [userVote, setUserVote] = useState<VoteType | null>(null)
  const [loading, setLoading] = useState(false)

  // Fetch vote stats on mount
  useEffect(() => {
    const fetchVoteStats = async () => {
      try {
        const { stats, error } = await VoteHelpers.getVoteStats(
          contentType,
          contentId,
          user?.id
        )

        if (error) {
          logger.error('Failed to fetch vote stats:', error)
          return
        }

        if (stats) {
          setUpvotes(stats.upvotes)
          setDownvotes(stats.downvotes)
          setUserVote(stats.user_vote || null)
        }
      } catch (err) {
        logger.error('Error fetching vote stats:', err)
      }
    }

    fetchVoteStats()
  }, [contentId, contentType, user?.id])

  const handleVote = async (voteType: VoteType) => {
    // Check authentication
    if (!user) {
      notifications.show({
        title: 'Login required',
        message: 'Please log in to vote on content',
        color: 'yellow',
      })
      return
    }

    // Prevent double-clicking during loading
    if (loading) return

    setLoading(true)

    // Store previous state for rollback
    const previousUpvotes = upvotes
    const previousDownvotes = downvotes
    const previousUserVote = userVote

    try {
      // Calculate optimistic updates
      let newUserVote: VoteType | null = voteType
      let upvoteDelta = 0
      let downvoteDelta = 0

      if (userVote === voteType) {
        // Clicking same vote - remove it
        newUserVote = null
        if (voteType === 'upvote') {
          upvoteDelta = -1
        } else {
          downvoteDelta = -1
        }
      } else if (userVote) {
        // Switching vote
        if (voteType === 'upvote') {
          upvoteDelta = 1
          downvoteDelta = -1
        } else {
          upvoteDelta = -1
          downvoteDelta = 1
        }
      } else {
        // New vote
        if (voteType === 'upvote') {
          upvoteDelta = 1
        } else {
          downvoteDelta = 1
        }
      }

      // Optimistic update
      setUserVote(newUserVote)
      setUpvotes(prev => prev + upvoteDelta)
      setDownvotes(prev => prev + downvoteDelta)

      // Make API call
      const { success, error } = await VoteHelpers.castVote(
        user.id,
        contentType,
        contentId,
        voteType
      )

      if (!success || error) {
        throw new Error(error || 'Failed to register vote')
      }
    } catch (err) {
      // Rollback on error
      setUserVote(previousUserVote)
      setUpvotes(previousUpvotes)
      setDownvotes(previousDownvotes)

      notifications.show({
        title: 'Vote failed',
        message: err instanceof Error ? err.message : 'Failed to register vote. Please try again.',
        color: 'red',
      })
    } finally {
      setLoading(false)
    }
  }

  const score = upvotes - downvotes

  return (
    <Card p="sm" shadow="sm" withBorder w={60}>
      <Stack gap="xs" align="center">
        <ActionIcon
          variant={userVote === 'upvote' ? 'filled' : 'subtle'}
          color={userVote === 'upvote' ? 'orange' : 'gray'}
          size="lg"
          onClick={() => handleVote('upvote')}
          disabled={loading}
          style={{ cursor: loading ? 'not-allowed' : 'pointer' }}
        >
          <IconArrowUp size={20} />
        </ActionIcon>

        <Text
          fw={700}
          size="lg"
          c={score > 0 ? 'orange' : score < 0 ? 'blue' : 'dimmed'}
        >
          {score}
        </Text>

        <ActionIcon
          variant={userVote === 'downvote' ? 'filled' : 'subtle'}
          color={userVote === 'downvote' ? 'blue' : 'gray'}
          size="lg"
          onClick={() => handleVote('downvote')}
          disabled={loading}
          style={{ cursor: loading ? 'not-allowed' : 'pointer' }}
        >
          <IconArrowDown size={20} />
        </ActionIcon>
      </Stack>
    </Card>
  )
}
