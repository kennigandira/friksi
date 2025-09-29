'use client'

import {
  Stack,
  Card,
  Text,
  Group,
  Badge,
  Avatar,
  ActionIcon,
} from '@mantine/core'
import {
  IconArrowUp,
  IconArrowDown,
  IconMessage,
  IconEye,
} from '@tabler/icons-react'
import Link from 'next/link'
import { formatDistanceToNow } from 'date-fns'

interface ThreadListProps {
  threads: any[]
  onVote?: (threadId: string, voteType: 'upvote' | 'downvote') => void
}

export function ThreadList({ threads, onVote }: ThreadListProps) {
  if (threads.length === 0) {
    return (
      <Card p="xl" withBorder>
        <Text ta="center" c="dimmed">
          No threads found. Be the first to start a discussion!
        </Text>
      </Card>
    )
  }

  return (
    <Stack gap="md">
      {threads.map(thread => (
        <Card key={thread.id} p="md" shadow="sm" withBorder>
          <Group justify="space-between" mb="sm">
            <Group>
              <Avatar size="sm" src={thread.users?.avatar_url}>
                {thread.users?.username?.[0]?.toUpperCase() || 'A'}
              </Avatar>
              <div>
                <Text size="sm" fw={500}>
                  {thread.users?.username || 'Anonymous'}
                </Text>
                <Badge size="xs" color="blue">
                  Level {thread.users?.level || 1}
                </Badge>
              </div>
            </Group>
            <Badge variant="light" color="gray">
              {thread.categories?.name || 'General'}
            </Badge>
          </Group>

          <Link
            href={`/threads/${thread.id}`}
            style={{ textDecoration: 'none', color: 'inherit' }}
          >
            <Text fw={600} mb="xs" lineClamp={2} style={{ cursor: 'pointer' }}>
              {thread.title}
            </Text>
          </Link>

          <Text size="sm" c="dimmed" lineClamp={3} mb="md">
            {thread.content}
          </Text>

          <Group justify="space-between">
            <Group gap="xs">
              <Group gap={4}>
                <ActionIcon
                  variant="subtle"
                  size="sm"
                  onClick={() => onVote?.(thread.id, 'upvote')}
                >
                  <IconArrowUp size={14} />
                </ActionIcon>
                <Text size="sm" fw={500}>
                  {(thread.upvotes || 0) - (thread.downvotes || 0)}
                </Text>
                <ActionIcon
                  variant="subtle"
                  size="sm"
                  onClick={() => onVote?.(thread.id, 'downvote')}
                >
                  <IconArrowDown size={14} />
                </ActionIcon>
              </Group>

              <Group gap={4}>
                <IconMessage size={14} />
                <Text size="sm" c="dimmed">
                  {thread.comment_count || 0}
                </Text>
              </Group>

              <Group gap={4}>
                <IconEye size={14} />
                <Text size="sm" c="dimmed">
                  {thread.view_count || 0}
                </Text>
              </Group>
            </Group>

            <Text size="xs" c="dimmed">
              {thread.created_at
                ? formatDistanceToNow(new Date(thread.created_at), { addSuffix: true })
                : 'Unknown'}
            </Text>
          </Group>
        </Card>
      ))}
    </Stack>
  )
}
