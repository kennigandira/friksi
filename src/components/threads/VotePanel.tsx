'use client'

import { Card, Stack, ActionIcon, Text, Center } from '@mantine/core'
import { IconArrowUp, IconArrowDown } from '@tabler/icons-react'

interface VotePanelProps {
  threadId: string
}

export function VotePanel({ threadId }: VotePanelProps) {
  // Mock data for now
  const score = 21 // upvotes - downvotes
  const userVote = null // 'up' | 'down' | null

  const handleVote = (voteType: 'up' | 'down') => {
    console.log(`Voting ${voteType} on thread ${threadId}`)
    // TODO: Implement voting logic
  }

  return (
    <Card p="sm" shadow="sm" withBorder w={60}>
      <Stack gap="xs" align="center">
        <ActionIcon
          variant={userVote === 'up' ? 'filled' : 'subtle'}
          color={userVote === 'up' ? 'orange' : 'gray'}
          size="lg"
          onClick={() => handleVote('up')}
        >
          <IconArrowUp size={20} />
        </ActionIcon>

        <Text fw={700} size="lg">
          {score}
        </Text>

        <ActionIcon
          variant={userVote === 'down' ? 'filled' : 'subtle'}
          color={userVote === 'down' ? 'blue' : 'gray'}
          size="lg"
          onClick={() => handleVote('down')}
        >
          <IconArrowDown size={20} />
        </ActionIcon>
      </Stack>
    </Card>
  )
}
