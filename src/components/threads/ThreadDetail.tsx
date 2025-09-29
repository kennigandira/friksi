'use client'

import {
  Card,
  Text,
  Group,
  Badge,
  Avatar,
  Title,
  Stack,
  Paper,
  Divider,
  ActionIcon,
  Menu,
} from '@mantine/core'
import {
  IconPin,
  IconLock,
  IconArchive,
  IconFlame,
  IconEye,
  IconMessage,
  IconClock,
  IconEdit,
  IconTrash,
  IconDots,
  IconFlag,
  IconShare,
} from '@tabler/icons-react'
import { TrustIndicator } from './TrustIndicator'
import { Thread } from '@/lib/database/helpers/threads'
import { useAuth } from '@/hooks/useAuth'
import { useThread } from '@/hooks/useThread'
import { formatDistanceToNow } from 'date-fns'
import { useState } from 'react'

interface ThreadDetailProps {
  thread: Thread & {
    users?: {
      username: string
      avatar_url: string | null
      level: number
      is_bot: boolean
      trust_score: number
      bot_flags: number
    } | null
    categories?: {
      name: string
      slug: string
      path?: string
    } | null
  }
}

export function ThreadDetail({ thread: initialThread }: ThreadDetailProps) {
  const { user, profile } = useAuth()
  const { thread, updateThread, deleteThread } = useThread({
    threadId: initialThread.id,
    initialThread: initialThread as any,
  })
  const [isEditing, setIsEditing] = useState(false)

  if (!thread) return null

  const threadWithRelations = thread as typeof initialThread
  const isOwner = user?.id === thread.user_id
  const createdAt = new Date(thread.created_at)
  const editedAt = thread.edited_at ? new Date(thread.edited_at) : null
  const isHot = thread.hot_score > 10 // Threshold for "hot" threads

  // Calculate engagement metrics
  const engagementRate = thread.view_count > 0
    ? ((thread.comment_count / thread.view_count) * 100).toFixed(1)
    : '0'

  const handleEdit = () => {
    setIsEditing(true)
    // TODO: Implement edit modal
  }

  const handleDelete = async () => {
    if (confirm('Are you sure you want to delete this thread?')) {
      const { success } = await deleteThread()
      if (success) {
        // TODO: Navigate back to thread list
      }
    }
  }

  return (
    <Paper p="lg" shadow="sm" withBorder radius="md" className="relative">
      {/* Thread status badges */}
      <Group gap="xs" mb="md">
        {thread.is_pinned && (
          <Badge leftSection={<IconPin size={12} />} color="grape" variant="light">
            Pinned
          </Badge>
        )}
        {thread.is_locked && (
          <Badge leftSection={<IconLock size={12} />} color="gray" variant="light">
            Locked
          </Badge>
        )}
        {(thread as any).is_archived && (
          <Badge leftSection={<IconArchive size={12} />} color="dark" variant="light">
            Archived
          </Badge>
        )}
        {isHot && (
          <Badge
            leftSection={<IconFlame size={12} />}
            color="orange"
            variant="filled"
            className="animate-pulse"
          >
            Hot Thread
          </Badge>
        )}
      </Group>

      <Stack gap="md">
        {/* Author information */}
        <Group justify="space-between">
          <Group>
            <Avatar size="md" src={threadWithRelations.users?.avatar_url}>
              {threadWithRelations.users?.username?.[0]?.toUpperCase()}
            </Avatar>
            <div>
              <Group gap="xs">
                <Text fw={500}>{threadWithRelations.users?.username || 'Unknown'}</Text>
                {threadWithRelations.users && (
                  <TrustIndicator
                    trustScore={threadWithRelations.users.trust_score}
                    botFlags={threadWithRelations.users.bot_flags}
                    isBot={threadWithRelations.users.is_bot}
                    level={threadWithRelations.users.level}
                  />
                )}
              </Group>
              <Group gap="xs">
                <Text size="xs" c="dimmed">
                  <IconClock size={12} className="inline mr-1" />
                  {formatDistanceToNow(createdAt, { addSuffix: true })}
                </Text>
                {editedAt && (
                  <Text size="xs" c="dimmed">
                    (edited {formatDistanceToNow(editedAt, { addSuffix: true })})
                  </Text>
                )}
              </Group>
            </div>
          </Group>

          <Group gap="xs">
            {threadWithRelations.categories && (
              <Badge variant="light" color="gray">
                {threadWithRelations.categories.name}
              </Badge>
            )}

            <Menu position="bottom-end">
              <Menu.Target>
                <ActionIcon variant="subtle" color="gray">
                  <IconDots size={16} />
                </ActionIcon>
              </Menu.Target>
              <Menu.Dropdown>
                <Menu.Item leftSection={<IconShare size={14} />}>
                  Share
                </Menu.Item>
                {isOwner && (
                  <>
                    <Menu.Item leftSection={<IconEdit size={14} />} onClick={handleEdit}>
                      Edit
                    </Menu.Item>
                    <Menu.Item
                      leftSection={<IconTrash size={14} />}
                      color="red"
                      onClick={handleDelete}
                    >
                      Delete
                    </Menu.Item>
                  </>
                )}
                {!isOwner && (
                  <Menu.Item leftSection={<IconFlag size={14} />} color="red">
                    Report
                  </Menu.Item>
                )}
              </Menu.Dropdown>
            </Menu>
          </Group>
        </Group>

        <Divider />

        {/* Thread content */}
        <div>
          <Title order={1} size="h2" mb="md">
            {thread.title}
          </Title>
          <Text style={{ whiteSpace: 'pre-wrap', lineHeight: 1.6 }}>
            {thread.content}
          </Text>
        </div>

        <Divider />

        {/* Engagement metrics */}
        <Group gap="xl">
          <Group gap={4}>
            <IconEye size={16} className="text-gray-500" />
            <Text size="sm" c="dimmed">
              {thread.view_count.toLocaleString()} views
            </Text>
          </Group>
          <Group gap={4}>
            <IconMessage size={16} className="text-gray-500" />
            <Text size="sm" c="dimmed">
              {thread.comment_count.toLocaleString()} comments
            </Text>
          </Group>
          <Group gap={4}>
            <IconFlame size={16} className="text-gray-500" />
            <Text size="sm" c="dimmed">
              {engagementRate}% engagement
            </Text>
          </Group>
          <Text size="sm" c="dimmed">
            Score: {(thread.upvotes - thread.downvotes).toLocaleString()}
          </Text>
        </Group>
      </Stack>
    </Paper>
  )
}