'use client'

import { useState, useEffect } from 'react'
import {
  Stack,
  Card,
  Text,
  Group,
  Badge,
  Avatar,
  ActionIcon,
  Loader,
  Center,
  Alert,
} from '@mantine/core'
import {
  IconArrowUp,
  IconArrowDown,
  IconMessage,
  IconEye,
  IconAlertCircle,
} from '@tabler/icons-react'
import { ThreadHelpers } from '@/lib/database'
import type { Tables } from '@/lib/database/types/database.types'

type Thread = Tables<'threads'>
import { logger } from '@/lib/logger'
import Link from 'next/link'

interface ThreadListProps {
  sortBy?: 'hot' | 'new' | 'top'
  categoryId?: string
}

export function ThreadList({ sortBy = 'hot', categoryId }: ThreadListProps) {
  const [threads, setThreads] = useState<Thread[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchThreads = async () => {
      try {
        setLoading(true)
        setError(null)

        const { threads: data, error: fetchError } = categoryId
          ? await ThreadHelpers.getThreadsByCategory(categoryId, { sortBy })
          : await ThreadHelpers.getHotThreads({ limit: 20 })

        if (fetchError) {
          throw new Error(fetchError)
        }

        setThreads(data || [])
      } catch (err) {
        const errorMessage =
          err instanceof Error ? err.message : 'Failed to load threads'
        logger.error('Error fetching threads:', err)
        setError(errorMessage)
      } finally {
        setLoading(false)
      }
    }

    fetchThreads()
  }, [sortBy, categoryId])

  if (loading) {
    return (
      <Center py="xl">
        <Loader size="md" />
      </Center>
    )
  }

  if (error) {
    return (
      <Alert
        icon={<IconAlertCircle size={16} />}
        title="Error"
        color="red"
        variant="filled"
      >
        {error}
      </Alert>
    )
  }

  if (threads.length === 0) {
    return (
      <Card p="xl" withBorder>
        <Center>
          <Stack align="center" gap="sm">
            <Text size="lg" c="dimmed">
              No threads yet
            </Text>
            <Text size="sm" c="dimmed">
              Be the first to start a discussion!
            </Text>
          </Stack>
        </Center>
      </Card>
    )
  }
  return (
    <Stack gap="md">
      {threads.map(thread => {
        const score = (thread.upvotes || 0) - (thread.downvotes || 0)
        const author = (thread as any).users
        const category = (thread as any).categories

        return (
          <Card
            key={thread.id}
            p="md"
            shadow="sm"
            withBorder
            component={Link}
            href={`/threads/${thread.id}`}
            style={{ cursor: 'pointer', textDecoration: 'none' }}
          >
            <Group justify="space-between" mb="sm">
              <Group>
                <Avatar size="sm" src={author?.avatar_url}>
                  {author?.username?.[0]?.toUpperCase() || '?'}
                </Avatar>
                <div>
                  <Text size="sm" fw={500}>
                    {author?.username || 'Unknown'}
                  </Text>
                  <Badge size="xs" color="blue">
                    Level {author?.level || 1}
                  </Badge>
                </div>
              </Group>
              <Badge variant="light" color="gray">
                {category?.name || 'General'}
              </Badge>
            </Group>

            <Text fw={600} mb="xs" lineClamp={2}>
              {thread.title}
            </Text>

            <Text size="sm" c="dimmed" lineClamp={3} mb="md">
              {thread.content}
            </Text>

            <Group justify="space-between">
              <Group gap="xs">
                <Group gap={4}>
                  <ActionIcon variant="subtle" size="sm">
                    <IconArrowUp size={14} />
                  </ActionIcon>
                  <Text size="sm" fw={500} {...(score > 0 && { c: 'orange' })}>
                    {score}
                  </Text>
                  <ActionIcon variant="subtle" size="sm">
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
                  ? new Date(thread.created_at).toLocaleDateString()
                  : 'Unknown'}
              </Text>
            </Group>
          </Card>
        )
      })}
    </Stack>
  )
}
