'use client'

import { useEffect, useState } from 'react'
import { Card, Text, Group, Badge, Avatar, Title, Stack, Skeleton, Alert } from '@mantine/core'
import { IconAlertCircle } from '@tabler/icons-react'
import { ThreadHelpers, type Thread } from '@/lib/database'
import { logger } from '@/lib/logger'

interface ThreadDetailProps {
  threadId: string
}

interface ThreadWithRelations extends Thread {
  users?: {
    username: string
    avatar_url: string | null
    level: number
  }
  categories?: {
    name: string
    slug: string
    path: string | null
  }
}

export function ThreadDetail({ threadId }: ThreadDetailProps) {
  const [thread, setThread] = useState<ThreadWithRelations | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchThread = async () => {
      try {
        setLoading(true)
        setError(null)

        const { thread: fetchedThread, error: fetchError } = await ThreadHelpers.getThread(
          threadId,
          { incrementViews: true }
        )

        if (fetchError) {
          setError(fetchError)
          logger.error('Failed to fetch thread:', fetchError)
          return
        }

        if (!fetchedThread) {
          setError('Thread not found')
          return
        }

        setThread(fetchedThread as ThreadWithRelations)
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : 'Failed to load thread'
        setError(errorMessage)
        logger.error('Error fetching thread:', err)
      } finally {
        setLoading(false)
      }
    }

    fetchThread()
  }, [threadId])

  if (loading) {
    return (
      <Card p="lg" shadow="sm" withBorder mb="lg">
        <Stack gap="md">
          <Group justify="space-between">
            <Group>
              <Skeleton height={40} circle />
              <div>
                <Skeleton height={16} width={120} mb={4} />
                <Skeleton height={14} width={180} />
              </div>
            </Group>
            <Skeleton height={24} width={80} />
          </Group>
          <Skeleton height={32} width="70%" />
          <Skeleton height={200} />
          <Group gap="lg">
            <Skeleton height={14} width={60} />
            <Skeleton height={14} width={80} />
            <Skeleton height={14} width={60} />
          </Group>
        </Stack>
      </Card>
    )
  }

  if (error) {
    return (
      <Alert icon={<IconAlertCircle size={16} />} color="red" mb="lg">
        {error}
      </Alert>
    )
  }

  if (!thread) {
    return (
      <Alert icon={<IconAlertCircle size={16} />} color="yellow" mb="lg">
        Thread not found
      </Alert>
    )
  }

  const author = thread.users || { username: 'Unknown', avatar_url: null, level: 1 }
  const category = thread.categories || { name: 'Unknown', slug: 'unknown' }

  return (
    <Card p="lg" shadow="sm" withBorder mb="lg">
      <Stack gap="md">
        <Group justify="space-between">
          <Group>
            <Avatar size="md" src={author.avatar_url}>
              {author.username[0]?.toUpperCase()}
            </Avatar>
            <div>
              <Text fw={500}>{author.username}</Text>
              <Group gap="xs">
                <Badge size="xs" color="blue">
                  Level {author.level}
                </Badge>
                <Text size="xs" c="dimmed">
                  {new Date(thread.created_at).toLocaleDateString()}
                </Text>
              </Group>
            </div>
          </Group>
          <Badge variant="light" color="gray">
            {category.name}
          </Badge>
        </Group>

        <Title order={1} size="h2">
          {thread.title}
        </Title>

        <Text style={{ whiteSpace: 'pre-wrap' }}>{thread.content}</Text>

        {thread.edited_at && (
          <Text size="xs" c="dimmed" fs="italic">
            Edited on {new Date(thread.edited_at).toLocaleString()}
          </Text>
        )}

        <Group gap="lg" mt="md">
          <Text size="sm" c="dimmed">
            {thread.view_count} views
          </Text>
          <Text size="sm" c="dimmed">
            {thread.comment_count} comments
          </Text>
          <Text size="sm" c="dimmed">
            {thread.upvotes - thread.downvotes} score
          </Text>
        </Group>
      </Stack>
    </Card>
  )
}
