'use client'

import Link from 'next/link'
import { Card, Stack, Text, Group, Badge, Progress } from '@mantine/core'
import { IconTrendingUp, IconUsers, IconMessages } from '@tabler/icons-react'

interface TrendingCategory {
  id: string
  name: string
  slug: string
  post_count: number
  subscriber_count: number
  activity_percentage: number
  color?: string
}

interface TrendingCategoriesProps {
  categories?: TrendingCategory[]
  loading?: boolean
}

const mockCategories: TrendingCategory[] = [
  {
    id: '1',
    name: 'Technology',
    slug: 'tech',
    post_count: 2341,
    subscriber_count: 15234,
    activity_percentage: 85,
    color: '#6366f1',
  },
  {
    id: '2',
    name: 'Politics',
    slug: 'politics',
    post_count: 1823,
    subscriber_count: 12456,
    activity_percentage: 72,
    color: '#ef4444',
  },
  {
    id: '3',
    name: 'Science',
    slug: 'science',
    post_count: 1456,
    subscriber_count: 9823,
    activity_percentage: 68,
    color: '#10b981',
  },
  {
    id: '4',
    name: 'Entertainment',
    slug: 'entertainment',
    post_count: 1234,
    subscriber_count: 8456,
    activity_percentage: 60,
    color: '#f59e0b',
  },
  {
    id: '5',
    name: 'Sports',
    slug: 'sports',
    post_count: 987,
    subscriber_count: 7234,
    activity_percentage: 55,
    color: '#8b5cf6',
  },
]

export function TrendingCategories({
  categories = mockCategories,
  loading = false,
}: TrendingCategoriesProps) {
  if (loading) {
    return (
      <Card shadow="sm" padding="lg" radius="md" withBorder>
        <Stack gap="md">
          <Group gap="xs">
            <IconTrendingUp size={20} />
            <Text fw={600}>Loading categories...</Text>
          </Group>
        </Stack>
      </Card>
    )
  }

  return (
    <Card shadow="sm" padding="lg" radius="md" withBorder>
      <Stack gap="md">
        <Group gap="xs">
          <IconTrendingUp size={20} style={{ color: '#f59e0b' }} />
          <Text fw={600}>Trending Categories</Text>
        </Group>

        <Stack gap="sm">
          {categories.slice(0, 5).map((category, index) => (
            <Link
              key={category.id}
              href={`/categories/${category.slug}`}
              style={{ textDecoration: 'none' }}
            >
              <Card
                padding="sm"
                radius="sm"
                withBorder
                style={{
                  borderLeft: `3px solid ${category.color || '#6366f1'}`,
                  cursor: 'pointer',
                  transition: 'all 0.2s ease',
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.transform = 'translateX(4px)'
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.transform = 'translateX(0)'
                }}
              >
                <Stack gap="xs">
                  <Group justify="space-between">
                    <Group gap="xs">
                      <Badge size="xs" color="gray" variant="light">
                        #{index + 1}
                      </Badge>
                      <Text fw={500} size="sm">
                        {category.name}
                      </Text>
                    </Group>
                  </Group>

                  <Progress
                    value={category.activity_percentage}
                    size="xs"
                    color={category.color || 'blue'}
                    radius="xl"
                  />

                  <Group gap="lg">
                    <Group gap={4}>
                      <IconMessages size={14} />
                      <Text size="xs" c="dimmed">
                        {category.post_count.toLocaleString()}
                      </Text>
                    </Group>
                    <Group gap={4}>
                      <IconUsers size={14} />
                      <Text size="xs" c="dimmed">
                        {category.subscriber_count.toLocaleString()}
                      </Text>
                    </Group>
                  </Group>
                </Stack>
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
          href="/categories"
        >
          View all categories →
        </Text>
      </Stack>
    </Card>
  )
}