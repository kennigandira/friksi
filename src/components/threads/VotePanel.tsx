'use client'

import { Card, Stack, ActionIcon, Text, Tooltip, Transition } from '@mantine/core'
import { IconArrowUp, IconArrowDown } from '@tabler/icons-react'
import { useVoting } from '@/hooks/useVoting'
import type { ContentType } from '@/lib/database/types/database.types'
import styles from './VotePanel.module.css'

interface VotePanelProps {
  contentId: string
  contentType: ContentType
  initialUpvotes?: number
  initialDownvotes?: number
  compact?: boolean
}

export function VotePanel({
  contentId,
  contentType,
  initialUpvotes = 0,
  initialDownvotes = 0,
  compact = false,
}: VotePanelProps) {
  const { stats, userVote, loading, upvote, downvote } = useVoting({
    contentId,
    contentType,
    initialUpvotes,
    initialDownvotes,
  })

  // Format score for display
  const formatScore = (score: number) => {
    if (Math.abs(score) >= 1000000) {
      return `${(score / 1000000).toFixed(1)}M`
    }
    if (Math.abs(score) >= 1000) {
      return `${(score / 1000).toFixed(1)}k`
    }
    return score.toString()
  }

  // Get color based on score
  const getScoreColor = (score: number) => {
    if (score > 0) return 'orange'
    if (score < 0) return 'blue'
    return undefined
  }

  if (compact) {
    // Inline compact version for comments
    return (
      <Stack gap={4} align="center">
        <ActionIcon
          variant={userVote === 'upvote' ? 'filled' : 'subtle'}
          color={userVote === 'upvote' ? 'orange' : 'gray'}
          size="sm"
          onClick={upvote}
          disabled={loading}
          className={userVote === 'upvote' ? styles.voteActive : styles.voteButton}
          aria-label="Upvote"
        >
          <IconArrowUp size={16} />
        </ActionIcon>

        <Text
          fw={700}
          size="sm"
          c={getScoreColor(stats.score)}
          className={styles.scoreText}
        >
          {formatScore(stats.score)}
        </Text>

        <ActionIcon
          variant={userVote === 'downvote' ? 'filled' : 'subtle'}
          color={userVote === 'downvote' ? 'blue' : 'gray'}
          size="sm"
          onClick={downvote}
          disabled={loading}
          className={userVote === 'downvote' ? styles.voteActive : styles.voteButton}
          aria-label="Downvote"
        >
          <IconArrowDown size={16} />
        </ActionIcon>
      </Stack>
    )
  }

  // Full version for threads
  return (
    <Card p="sm" shadow="sm" withBorder radius="md" className={styles.votePanel}>
      <Stack gap="xs" align="center">
        <Tooltip
          label={`${stats.upvotes.toLocaleString()} upvotes`}
          position="right"
          withArrow
        >
          <ActionIcon
            variant={userVote === 'upvote' ? 'filled' : 'subtle'}
            color={userVote === 'upvote' ? 'orange' : 'gray'}
            size="xl"
            onClick={upvote}
            disabled={loading}
            className={userVote === 'upvote' ? styles.voteActive : styles.voteButton}
            aria-label={`Upvote (${stats.upvotes})`}
          >
            <IconArrowUp size={24} />
          </ActionIcon>
        </Tooltip>

        <Transition
          mounted={true}
          transition="scale"
          duration={200}
          timingFunction="ease"
        >
          {(styles) => (
            <Text
              fw={700}
              size="xl"
              c={getScoreColor(stats.score)}
              style={styles}
            >
              {formatScore(stats.score)}
            </Text>
          )}
        </Transition>

        <Tooltip
          label={`${stats.downvotes.toLocaleString()} downvotes`}
          position="right"
          withArrow
        >
          <ActionIcon
            variant={userVote === 'downvote' ? 'filled' : 'subtle'}
            color={userVote === 'downvote' ? 'blue' : 'gray'}
            size="xl"
            onClick={downvote}
            disabled={loading}
            className={userVote === 'downvote' ? styles.voteActive : styles.voteButton}
            aria-label={`Downvote (${stats.downvotes})`}
          >
            <IconArrowDown size={24} />
          </ActionIcon>
        </Tooltip>
      </Stack>

      {/* Vote percentage bar */}
      {stats.upvotes + stats.downvotes > 0 && (
        <div className={styles.voteBar}>
          <Tooltip
            label={`${((stats.upvotes / (stats.upvotes + stats.downvotes)) * 100).toFixed(0)}% upvoted`}
            position="right"
            withArrow
          >
            <div
              className={styles.voteBarFill}
              style={{
                height: `${(stats.upvotes / (stats.upvotes + stats.downvotes)) * 100}%`,
                backgroundColor: 'var(--mantine-color-orange-5)',
              }}
            />
          </Tooltip>
        </div>
      )}
    </Card>
  )
}