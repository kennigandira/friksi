'use client'

import { Card, Text, Group, Badge, Button, Stack } from '@mantine/core'
import {
  IconUsers,
  IconMessage,
  IconHeart,
  IconHeartFilled,
} from '@tabler/icons-react'
import Link from 'next/link'

interface CategoryCardProps {
  name: string
  slug: string
  description: string
  threadCount: number
  subscriberCount: number
  isSubscribed: boolean
}

export function CategoryCard({
  name,
  slug,
  description,
  threadCount,
  subscriberCount,
  isSubscribed,
}: CategoryCardProps) {
  return (
    <Card p="md" shadow="sm" withBorder h="100%">
      <Stack justify="space-between" h="100%">
        <div>
          <Group justify="space-between" mb="sm">
            <Text fw={600} size="lg">
              {name}
            </Text>
            <Button
              variant="subtle"
              size="xs"
              leftSection={
                isSubscribed ? (
                  <IconHeartFilled size={14} />
                ) : (
                  <IconHeart size={14} />
                )
              }
              color={isSubscribed ? 'red' : 'gray'}
            >
              {isSubscribed ? 'Subscribed' : 'Subscribe'}
            </Button>
          </Group>

          <Text size="sm" c="dimmed" mb="md" lineClamp={3}>
            {description}
          </Text>
        </div>

        <div>
          <Group mb="md" gap="lg">
            <Group gap={4}>
              <IconMessage size={16} />
              <Text size="sm">{threadCount} threads</Text>
            </Group>

            <Group gap={4}>
              <IconUsers size={16} />
              <Text size="sm">{subscriberCount} members</Text>
            </Group>
          </Group>

          <Button
            component={Link}
            href={`/category/${slug}`}
            variant="light"
            fullWidth
          >
            Browse Category
          </Button>
        </div>
      </Stack>
    </Card>
  )
}
