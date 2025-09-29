'use client'

import { Card, Skeleton, Stack, Group } from '@mantine/core'
import { ViewMode } from './ThreadCard'

interface ThreadSkeletonProps {
  count?: number
  variant?: ViewMode
}

export function ThreadSkeleton({
  count = 1,
  variant = 'card',
}: ThreadSkeletonProps) {
  const skeletons = Array(count).fill(0)

  if (variant === 'compact') {
    return (
      <Stack gap="xs">
        {skeletons.map((_, i) => (
          <Card key={i} shadow="xs" padding="sm" radius="md" withBorder>
            <Group justify="space-between" wrap="nowrap">
              <Stack gap={4} style={{ flex: 1 }}>
                <Group gap="xs">
                  <Skeleton height={20} width={60} radius="sm" />
                  <Skeleton height={20} width={80} radius="sm" />
                </Group>
                <Skeleton height={24} width="70%" />
              </Stack>
              <Group gap="md">
                <Skeleton height={20} width={40} />
                <Skeleton height={20} width={60} />
              </Group>
            </Group>
          </Card>
        ))}
      </Stack>
    )
  }

  return (
    <Stack gap="md">
      {skeletons.map((_, i) => (
        <Card key={i} shadow="sm" padding="lg" radius="md" withBorder>
          <Stack gap="md">
            <Group justify="space-between">
              <Group gap="sm">
                <Skeleton height={24} width={80} radius="sm" />
                <Skeleton height={24} width={100} radius="sm" />
              </Group>
              <Skeleton height={20} width={60} />
            </Group>

            <Skeleton height={28} width="80%" />
            <Skeleton height={20} />
            <Skeleton height={20} />
            <Skeleton height={20} width="60%" />

            <Group justify="space-between">
              <Group gap="xs">
                <Skeleton height={32} width={100} radius="sm" />
              </Group>
              <Group gap="sm">
                <Skeleton height={20} width={80} />
                <Skeleton height={20} width={60} />
              </Group>
            </Group>
          </Stack>
        </Card>
      ))}
    </Stack>
  )
}