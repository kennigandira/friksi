'use client'

import Link from 'next/link'
import {
  Card,
  Group,
  Text,
  Badge,
  ActionIcon,
  Stack,
  Avatar,
} from '@mantine/core'
import {
  IconArrowUp,
  IconArrowDown,
  IconMessage,
  IconEye,
  IconClock,
} from '@tabler/icons-react'
import { HotIndicator } from './HotIndicator'
import { formatDistanceToNow } from 'date-fns'
import classes from './ThreadCard.module.css'

export type ViewMode = 'card' | 'compact'

interface ThreadCardProps {
  thread: {
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
  variant?: ViewMode
  onVote?: (threadId: string, voteType: 'upvote' | 'downvote') => void
}

function formatNumber(num: number): string {
  if (num >= 1000) {
    return `${(num / 1000).toFixed(1)}k`
  }
  return num.toString()
}

export function ThreadCard({
  thread,
  variant = 'card',
  onVote,
}: ThreadCardProps) {
  const score = thread.upvotes - thread.downvotes
  const timeAgo = formatDistanceToNow(new Date(thread.created_at), {
    addSuffix: true,
  })

  if (variant === 'compact') {
    return (
      <Card
        shadow="xs"
        padding="sm"
        radius="md"
        withBorder
        className={thread.hot_score > 100 ? classes.hotThread : ''}
      >
        <Group justify="space-between" wrap="nowrap">
          <Stack gap={4} style={{ flex: 1, minWidth: 0 }}>
            <Group gap="xs" wrap="nowrap">
              <HotIndicator score={thread.hot_score} compact />
              {thread.categories && (
                <Badge size="xs" variant="dot" color="blue">
                  {thread.categories.name}
                </Badge>
              )}
              <Text size="xs" c="dimmed">
                {timeAgo}
              </Text>
            </Group>
            <Link
              href={`/threads/${thread.id}`}
              className={classes.threadLink}
            >
              <Text fw={500} lineClamp={1} className={classes.threadTitle}>
                {thread.title}
              </Text>
            </Link>
            {thread.users && (
              <Text size="xs" c="dimmed">
                by {thread.users.username}
              </Text>
            )}
          </Stack>
          <Group gap="md" wrap="nowrap">
            <Group gap={4}>
              <ActionIcon
                variant="subtle"
                size="sm"
                color="green"
                onClick={() => onVote?.(thread.id, 'upvote')}
              >
                <IconArrowUp size={14} />
              </ActionIcon>
              <Text size="sm" fw={500}>
                {formatNumber(score)}
              </Text>
              <ActionIcon
                variant="subtle"
                size="sm"
                color="red"
                onClick={() => onVote?.(thread.id, 'downvote')}
              >
                <IconArrowDown size={14} />
              </ActionIcon>
            </Group>
            <Group gap={4}>
              <IconMessage size={14} />
              <Text size="sm">{formatNumber(thread.comment_count)}</Text>
            </Group>
          </Group>
        </Group>
      </Card>
    )
  }

  return (
    <Card
      shadow="sm"
      padding="lg"
      radius="md"
      withBorder
      className={thread.hot_score > 100 ? classes.hotThread : ''}
    >
      <Stack gap="md">
        <Group justify="space-between">
          <Group gap="sm">
            <HotIndicator score={thread.hot_score} />
            {thread.categories && (
              <Badge variant="dot" color="blue">
                {thread.categories.name}
              </Badge>
            )}
          </Group>
          <Group gap="xs">
            <IconClock size={14} />
            <Text size="xs" c="dimmed">
              {timeAgo}
            </Text>
          </Group>
        </Group>

        <Link href={`/threads/${thread.id}`} className={classes.threadLink}>
          <Text fw={600} size="lg" lineClamp={2} className={classes.threadTitle}>
            {thread.title}
          </Text>
        </Link>

        {(thread.excerpt || thread.content) && (
          <Text size="sm" c="dimmed" lineClamp={3}>
            {thread.excerpt || thread.content?.substring(0, 200)}
          </Text>
        )}

        {thread.users && (
          <Group gap="xs">
            <Avatar size="sm" src={thread.users.avatar_url}>
              {thread.users.username[0].toUpperCase()}
            </Avatar>
            <div>
              <Text size="sm" fw={500}>
                {thread.users.username}
              </Text>
              <Badge size="xs" variant="light" color="blue">
                Level {thread.users.level}
              </Badge>
            </div>
          </Group>
        )}

        <Group justify="space-between">
          <Group gap="xs">
            <ActionIcon
              variant="subtle"
              color="green"
              onClick={() => onVote?.(thread.id, 'upvote')}
            >
              <IconArrowUp size={16} />
            </ActionIcon>
            <Text fw={500}>{formatNumber(score)}</Text>
            <ActionIcon
              variant="subtle"
              color="red"
              onClick={() => onVote?.(thread.id, 'downvote')}
            >
              <IconArrowDown size={16} />
            </ActionIcon>
          </Group>

          <Group gap="sm" c="dimmed">
            <Group gap={4}>
              <IconMessage size={16} />
              <Text size="sm">{formatNumber(thread.comment_count)} comments</Text>
            </Group>
            <Text size="sm">•</Text>
            <Group gap={4}>
              <IconEye size={16} />
              <Text size="sm">{formatNumber(thread.view_count)} views</Text>
            </Group>
          </Group>
        </Group>
      </Stack>
    </Card>
  )
}