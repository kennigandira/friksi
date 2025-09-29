'use client'

import { useState } from 'react'
import { Stack, Group, SegmentedControl, Text } from '@mantine/core'
import { IconLayoutGrid, IconList } from '@tabler/icons-react'
import { ThreadCard, ViewMode } from './ThreadCard'
import { ThreadSkeleton } from './ThreadSkeleton'

interface Thread {
  id: string
  title: string
  content?: string | null
  excerpt?: string | null
  upvotes: number
  downvotes: number
  comment_count: number
  view_count: number
  hot_score: number
  created_at: string
  users?: {
    username: string
    avatar_url?: string | null
    level: number
  }
  categories?: {
    name: string
    slug: string
  }
}

interface ThreadListContainerProps {
  threads: Thread[]
  loading?: boolean
  title?: string
  showViewToggle?: boolean
  onVote?: (threadId: string, voteType: 'upvote' | 'downvote') => void
  onLoadMore?: () => void
  hasMore?: boolean
}

export function ThreadListContainer({
  threads,
  loading = false,
  title,
  showViewToggle = true,
  onVote,
  onLoadMore,
  hasMore = false,
}: ThreadListContainerProps) {
  const [viewMode, setViewMode] = useState<ViewMode>('card')

  if (loading && threads.length === 0) {
    return (
      <Stack gap="md">
        {title && (
          <Text size="xl" fw={700}>
            {title}
          </Text>
        )}
        <ThreadSkeleton count={5} variant={viewMode} />
      </Stack>
    )
  }

  return (
    <Stack gap="md">
      {(title || showViewToggle) && (
        <Group justify="space-between">
          {title && (
            <Text size="xl" fw={700}>
              {title}
            </Text>
          )}
          {showViewToggle && (
            <SegmentedControl
              value={viewMode}
              onChange={(value) => setViewMode(value as ViewMode)}
              data={[
                {
                  value: 'card',
                  label: (
                    <Group gap={4}>
                      <IconLayoutGrid size={16} />
                      <span>Card</span>
                    </Group>
                  ),
                },
                {
                  value: 'compact',
                  label: (
                    <Group gap={4}>
                      <IconList size={16} />
                      <span>Compact</span>
                    </Group>
                  ),
                },
              ]}
            />
          )}
        </Group>
      )}

      <Stack gap={viewMode === 'compact' ? 'xs' : 'md'}>
        {threads.map((thread) => (
          <ThreadCard
            key={thread.id}
            thread={thread}
            variant={viewMode}
            onVote={onVote}
          />
        ))}
      </Stack>

      {loading && threads.length > 0 && (
        <ThreadSkeleton count={3} variant={viewMode} />
      )}

      {hasMore && !loading && onLoadMore && (
        <Group justify="center" mt="xl">
          <Text
            size="sm"
            c="blue"
            style={{ cursor: 'pointer' }}
            onClick={onLoadMore}
          >
            Load more threads
          </Text>
        </Group>
      )}
    </Stack>
  )
}