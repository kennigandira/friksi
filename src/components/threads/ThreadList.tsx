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

interface ThreadListProps {
  sortBy?: 'hot' | 'new' | 'top' | 'controversial'
  categoryId?: string
}

// Mock data for now
const mockThreads = [
  {
    id: '1',
    title: 'How can we improve public transportation in our city?',
    content:
      "I've been thinking about the current state of our public transit system...",
    author: { username: 'citizen_alice', avatar_url: null, level: 3 },
    category: { name: 'Local Issues', slug: 'local' },
    upvotes: 24,
    downvotes: 3,
    commentCount: 12,
    viewCount: 156,
    createdAt: '2024-01-15T10:30:00Z',
  },
  {
    id: '2',
    title: 'New climate change research shows accelerating trends',
    content: 'Recent studies from leading climate scientists indicate that...',
    author: { username: 'science_bob', avatar_url: null, level: 4 },
    category: { name: 'Environment', slug: 'environment' },
    upvotes: 45,
    downvotes: 8,
    commentCount: 28,
    viewCount: 234,
    createdAt: '2024-01-15T08:15:00Z',
  },
]

export function ThreadList({ sortBy = 'hot' }: ThreadListProps) {
  return (
    <Stack gap="md">
      {mockThreads.map(thread => (
        <Card key={thread.id} p="md" shadow="sm" withBorder>
          <Group justify="space-between" mb="sm">
            <Group>
              <Avatar size="sm" src={thread.author.avatar_url}>
                {thread.author.username[0].toUpperCase()}
              </Avatar>
              <div>
                <Text size="sm" fw={500}>
                  {thread.author.username}
                </Text>
                <Badge size="xs" color="blue">
                  Level {thread.author.level}
                </Badge>
              </div>
            </Group>
            <Badge variant="light" color="gray">
              {thread.category.name}
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
                <Text size="sm" fw={500}>
                  {thread.upvotes - thread.downvotes}
                </Text>
                <ActionIcon variant="subtle" size="sm">
                  <IconArrowDown size={14} />
                </ActionIcon>
              </Group>

              <Group gap={4}>
                <IconMessage size={14} />
                <Text size="sm" c="dimmed">
                  {thread.commentCount}
                </Text>
              </Group>

              <Group gap={4}>
                <IconEye size={14} />
                <Text size="sm" c="dimmed">
                  {thread.viewCount}
                </Text>
              </Group>
            </Group>

            <Text size="xs" c="dimmed">
              {new Date(thread.createdAt).toLocaleDateString()}
            </Text>
          </Group>
        </Card>
      ))}
    </Stack>
  )
}
