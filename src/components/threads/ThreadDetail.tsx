'use client'

import { Card, Text, Group, Badge, Avatar, Title, Stack } from '@mantine/core'

interface ThreadDetailProps {
  threadId: string
}

export function ThreadDetail({ threadId }: ThreadDetailProps) {
  // Mock data for now
  const thread = {
    id: threadId,
    title: 'How can we improve public transportation in our city?',
    content: `I've been thinking about the current state of our public transit system and believe there are several areas where we could make significant improvements.

    First, increasing the frequency of buses during peak hours would reduce overcrowding and wait times. Currently, many routes only run every 30 minutes during rush hour, which is insufficient for the demand.

    Second, we should consider dedicated bus lanes on major streets. This would help buses avoid traffic congestion and maintain more reliable schedules.

    What are your thoughts on these suggestions? Do you have other ideas for improving our public transportation?`,
    author: { username: 'citizen_alice', avatar_url: null, level: 3 },
    category: { name: 'Local Issues', slug: 'local' },
    upvotes: 24,
    downvotes: 3,
    commentCount: 12,
    viewCount: 156,
    createdAt: '2024-01-15T10:30:00Z',
  }

  return (
    <Card p="lg" shadow="sm" withBorder mb="lg">
      <Stack gap="md">
        <Group justify="space-between">
          <Group>
            <Avatar size="md" src={thread.author.avatar_url}>
              {thread.author.username[0].toUpperCase()}
            </Avatar>
            <div>
              <Text fw={500}>{thread.author.username}</Text>
              <Group gap="xs">
                <Badge size="xs" color="blue">
                  Level {thread.author.level}
                </Badge>
                <Text size="xs" c="dimmed">
                  {new Date(thread.createdAt).toLocaleDateString()}
                </Text>
              </Group>
            </div>
          </Group>
          <Badge variant="light" color="gray">
            {thread.category.name}
          </Badge>
        </Group>

        <Title order={1} size="h2">
          {thread.title}
        </Title>

        <Text style={{ whiteSpace: 'pre-wrap' }}>{thread.content}</Text>

        <Group gap="lg" mt="md">
          <Text size="sm" c="dimmed">
            {thread.viewCount} views
          </Text>
          <Text size="sm" c="dimmed">
            {thread.commentCount} comments
          </Text>
          <Text size="sm" c="dimmed">
            {thread.upvotes - thread.downvotes} score
          </Text>
        </Group>
      </Stack>
    </Card>
  )
}
