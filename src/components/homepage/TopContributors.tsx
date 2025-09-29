'use client'

import Link from 'next/link'
import {
  Card,
  Stack,
  Text,
  Group,
  Badge,
  Avatar,
  Progress,
} from '@mantine/core'
import { IconTrophy, IconStar } from '@tabler/icons-react'

interface TopContributor {
  id: string
  username: string
  avatar_url?: string | null
  level: number
  trust_score: number
  post_count: number
  helpful_votes: number
}

interface TopContributorsProps {
  contributors?: TopContributor[]
  loading?: boolean
}

const mockContributors: TopContributor[] = [
  {
    id: '1',
    username: 'tech_wizard',
    avatar_url: null,
    level: 12,
    trust_score: 95,
    post_count: 342,
    helpful_votes: 1523,
  },
  {
    id: '2',
    username: 'science_enthusiast',
    avatar_url: null,
    level: 10,
    trust_score: 92,
    post_count: 287,
    helpful_votes: 1234,
  },
  {
    id: '3',
    username: 'civic_voice',
    avatar_url: null,
    level: 9,
    trust_score: 88,
    post_count: 234,
    helpful_votes: 987,
  },
  {
    id: '4',
    username: 'data_analyst',
    avatar_url: null,
    level: 8,
    trust_score: 85,
    post_count: 198,
    helpful_votes: 876,
  },
  {
    id: '5',
    username: 'community_builder',
    avatar_url: null,
    level: 7,
    trust_score: 82,
    post_count: 167,
    helpful_votes: 654,
  },
]

const getTrophyColor = (position: number) => {
  switch (position) {
    case 0:
      return '#FFD700' // Gold
    case 1:
      return '#C0C0C0' // Silver
    case 2:
      return '#CD7F32' // Bronze
    default:
      return '#6B7280' // Gray
  }
}

export function TopContributors({
  contributors = mockContributors,
  loading = false,
}: TopContributorsProps) {
  if (loading) {
    return (
      <Card shadow="sm" padding="lg" radius="md" withBorder>
        <Stack gap="md">
          <Group gap="xs">
            <IconTrophy size={20} />
            <Text fw={600}>Loading contributors...</Text>
          </Group>
        </Stack>
      </Card>
    )
  }

  return (
    <Card shadow="sm" padding="lg" radius="md" withBorder>
      <Stack gap="md">
        <Group gap="xs">
          <IconTrophy size={20} style={{ color: '#FFD700' }} />
          <Text fw={600}>Top Contributors</Text>
        </Group>

        <Stack gap="xs">
          {contributors.slice(0, 5).map((contributor, index) => (
            <Link
              key={contributor.id}
              href={`/users/${contributor.username}`}
              style={{ textDecoration: 'none' }}
            >
              <Card
                padding="sm"
                radius="sm"
                withBorder={false}
                style={{
                  backgroundColor:
                    index === 0
                      ? 'rgba(255, 215, 0, 0.05)'
                      : 'transparent',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease',
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.backgroundColor =
                    'var(--mantine-color-gray-0)'
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.backgroundColor =
                    index === 0
                      ? 'rgba(255, 215, 0, 0.05)'
                      : 'transparent'
                }}
              >
                <Group justify="space-between">
                  <Group gap="sm">
                    <div style={{ position: 'relative' }}>
                      <Avatar size="sm" src={contributor.avatar_url}>
                        {contributor.username[0].toUpperCase()}
                      </Avatar>
                      {index < 3 && (
                        <IconTrophy
                          size={14}
                          style={{
                            position: 'absolute',
                            bottom: -2,
                            right: -2,
                            color: getTrophyColor(index),
                            backgroundColor: 'white',
                            borderRadius: '50%',
                          }}
                        />
                      )}
                    </div>
                    <div>
                      <Text fw={500} size="sm">
                        {contributor.username}
                      </Text>
                      <Group gap={4}>
                        <Badge
                          size="xs"
                          variant="light"
                          color="blue"
                          leftSection={<IconStar size={10} />}
                        >
                          Level {contributor.level}
                        </Badge>
                      </Group>
                    </div>
                  </Group>
                  <Text size="xs" c="dimmed">
                    {contributor.helpful_votes.toLocaleString()} 👍
                  </Text>
                </Group>

                <Progress
                  value={contributor.trust_score}
                  size={4}
                  color={
                    contributor.trust_score > 90
                      ? 'green'
                      : contributor.trust_score > 70
                      ? 'blue'
                      : 'yellow'
                  }
                  radius="xl"
                  mt={8}
                />
              </Card>
            </Link>
          ))}
        </Stack>

        <Text
          size="sm"
          c="blue"
          ta="center"
          style={{ cursor: 'pointer' }}
          component={Link}
          href="/leaderboard"
        >
          View full leaderboard →
        </Text>
      </Stack>
    </Card>
  )
}