'use client'

import {
  Stack,
  Card,
  Text,
  Textarea,
  Button,
  Group,
  Avatar,
  ActionIcon,
} from '@mantine/core'
import { IconArrowUp, IconArrowDown, IconCornerDownRight } from '@tabler/icons-react'

interface CommentSectionProps {
  threadId: string
}

// Mock comment data
const mockComments = [
  {
    id: '1',
    content:
      "Great points! I especially agree about the dedicated bus lanes. We've seen how effective they are in other cities.",
    author: { username: 'transit_fan', avatar_url: null, level: 2 },
    upvotes: 8,
    downvotes: 1,
    createdAt: '2024-01-15T11:15:00Z',
    replies: [
      {
        id: '2',
        content:
          'Yes! And they should be enforced properly. Too often I see cars using bus lanes.',
        author: { username: 'bus_rider', avatar_url: null, level: 1 },
        upvotes: 3,
        downvotes: 0,
        createdAt: '2024-01-15T11:30:00Z',
        replies: [],
      },
    ],
  },
]

export function CommentSection({ threadId }: CommentSectionProps) {
  const renderComment = (comment: any, depth = 0) => (
    <Stack key={comment.id} gap="sm" ml={depth * 20}>
      <Card p="md" shadow="xs" withBorder>
        <Group gap="sm" mb="sm">
          <Avatar size="sm" src={comment.author.avatar_url}>
            {comment.author.username[0].toUpperCase()}
          </Avatar>
          <Text size="sm" fw={500}>
            {comment.author.username}
          </Text>
          <Text size="xs" c="dimmed">
            Level {comment.author.level}
          </Text>
          <Text size="xs" c="dimmed">
            {new Date(comment.createdAt).toLocaleDateString()}
          </Text>
        </Group>

        <Text mb="sm">{comment.content}</Text>

        <Group gap="xs">
          <Group gap={4}>
            <ActionIcon variant="subtle" size="sm">
              <IconArrowUp size={12} />
            </ActionIcon>
            <Text size="sm">{comment.upvotes - comment.downvotes}</Text>
            <ActionIcon variant="subtle" size="sm">
              <IconArrowDown size={12} />
            </ActionIcon>
          </Group>

          <ActionIcon variant="subtle" size="sm">
            <IconCornerDownRight size={12} />
          </ActionIcon>
        </Group>
      </Card>

      {comment.replies?.map((reply: any) => renderComment(reply, depth + 1))}
    </Stack>
  )

  return (
    <Stack gap="lg">
      <Card p="md" shadow="sm" withBorder>
        <Textarea placeholder="Add a comment..." minRows={3} mb="md" />
        <Group justify="flex-end">
          <Button>Post Comment</Button>
        </Group>
      </Card>

      <Stack gap="md">
        {mockComments.map(comment => renderComment(comment))}
      </Stack>
    </Stack>
  )
}
