'use client'

import { Suspense } from 'react'
import { Container, Grid, Stack, Title, Card, Text } from '@mantine/core'
import { IconFlame } from '@tabler/icons-react'
import { ThreadListContainer } from '@/components/threads/ThreadListContainer'
import { ThreadSkeleton } from '@/components/threads/ThreadSkeleton'
import { TrendingCategories } from '@/components/homepage/TrendingCategories'
import { TopContributors } from '@/components/homepage/TopContributors'
import { useHotThreads } from '@/hooks/useHotThreads'

export default function HomePage() {
  const { threads, loading, error, hasMore, loadMore, handleVote } = useHotThreads({
    limit: 20,
    autoRefresh: true,
    refreshInterval: 60000, // Refresh every minute
  })

  return (
    <Container size="xl" py="xl">
      <Grid gutter="lg">
        {/* Main Feed */}
        <Grid.Col span={{ base: 12, md: 8 }}>
          <Stack gap="lg">
            {/* Hero Section */}
            <Card shadow="sm" padding="lg" radius="md" withBorder>
              <Title order={1}>
                <IconFlame
                  size={32}
                  style={{
                    display: 'inline-block',
                    verticalAlign: 'middle',
                    marginRight: 8,
                    color: '#FF6B6B',
                  }}
                />
                Hot Discussions
              </Title>
            </Card>

            {/* Thread List */}
            <Suspense fallback={<ThreadSkeleton count={5} />}>
              <ThreadListContainer
                threads={threads}
                loading={loading}
                showViewToggle
                onVote={handleVote}
                onLoadMore={loadMore}
                hasMore={hasMore}
              />
            </Suspense>

            {error && (
              <Card shadow="sm" padding="md" radius="md" withBorder>
                <Text color="red">Error loading threads: {error}</Text>
              </Card>
            )}
          </Stack>
        </Grid.Col>

        {/* Sidebar */}
        <Grid.Col span={{ base: 12, md: 4 }}>
          <Stack gap="lg">
            <Suspense
              fallback={
                <Card shadow="sm" padding="lg" radius="md" withBorder>
                  <ThreadSkeleton count={1} />
                </Card>
              }
            >
              <TrendingCategories />
            </Suspense>

            <Suspense
              fallback={
                <Card shadow="sm" padding="lg" radius="md" withBorder>
                  <ThreadSkeleton count={1} />
                </Card>
              }
            >
              <TopContributors />
            </Suspense>
          </Stack>
        </Grid.Col>
      </Grid>
    </Container>
  )
}
