'use client'

import { Card, Text, Group, Badge, Button, Stack, Avatar } from '@mantine/core'
import {
  IconUsers,
  IconMessage,
  IconHeart,
  IconHeartFilled,
} from '@tabler/icons-react'
import Link from 'next/link'
import { useState, useTransition } from 'react'
import { CategoryHelpers } from '@/lib/database/helpers/categories'
import { useRouter } from 'next/navigation'

interface CategoryCardProps {
  id: string
  name: string
  slug: string
  description: string
  threadCount: number
  subscriberCount: number
  isSubscribed: boolean
  color?: string | null
  iconUrl?: string | null
  userId?: string
}

export function CategoryCard({
  id,
  name,
  slug,
  description,
  threadCount,
  subscriberCount,
  isSubscribed: initialSubscribed,
  color,
  iconUrl,
  userId,
}: CategoryCardProps) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [isSubscribed, setIsSubscribed] = useState(initialSubscribed)
  const [subCount, setSubCount] = useState(subscriberCount)
  const [isLoading, setIsLoading] = useState(false)

  const handleSubscriptionToggle = async () => {
    // Require authentication
    if (!userId) {
      router.push('/login')
      return
    }

    setIsLoading(true)

    // Optimistic update
    const newStatus = !isSubscribed
    setIsSubscribed(newStatus)
    setSubCount(prev => newStatus ? prev + 1 : Math.max(0, prev - 1))

    try {
      const { success, error } = await CategoryHelpers.toggleSubscription(
        id,
        userId,
        isSubscribed,
        { useServerClient: false }
      )

      if (!success || error) {
        // Revert on error
        setIsSubscribed(isSubscribed)
        setSubCount(subscriberCount)
        console.error('Failed to toggle subscription:', error)
      } else {
        // Trigger server revalidation
        startTransition(() => {
          router.refresh()
        })
      }
    } catch (error) {
      // Revert on error
      setIsSubscribed(isSubscribed)
      setSubCount(subscriberCount)
      console.error('Error toggling subscription:', error)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Card p="md" shadow="sm" withBorder h="100%">
      <Stack justify="space-between" h="100%">
        <div>
          <Group justify="space-between" mb="sm">
            <Group gap="sm">
              {iconUrl && (
                <Avatar
                  src={iconUrl}
                  size="sm"
                  radius="sm"
                  color={color || 'blue'}
                />
              )}
              <Text fw={600} size="lg" style={{ color: color || undefined }}>
                {name}
              </Text>
            </Group>
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
              onClick={handleSubscriptionToggle}
              loading={isLoading}
              disabled={isPending}
            >
              {isSubscribed ? 'Subscribed' : 'Subscribe'}
            </Button>
          </Group>

          <Text size="sm" c="dimmed" mb="md" lineClamp={3}>
            {description || 'No description available'}
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
              <Text size="sm">{subCount} members</Text>
            </Group>
          </Group>

          <Button
            component={Link}
            href={`/category/${slug}`}
            variant="light"
            fullWidth
            style={{
              borderColor: color || undefined,
              color: color || undefined
            }}
          >
            Browse Category
          </Button>
        </div>
      </Stack>
    </Card>
  )
}
