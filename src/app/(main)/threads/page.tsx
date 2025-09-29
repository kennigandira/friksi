import { Suspense } from 'react'
import { Title, Group, Button, Container } from '@mantine/core'
import { ThreadListContainer } from '@/components/threads/ThreadListContainer'
import { ThreadSkeleton } from '@/components/threads/ThreadSkeleton'
import { ThreadFilters } from '@/components/threads/ThreadFilters'
import { IconPlus } from '@tabler/icons-react'
import Link from 'next/link'
import { ThreadHelpers } from '@/lib/database/helpers/threads'
import { CategoryHelpers } from '@/lib/database/helpers/categories'

interface ThreadsPageProps {
  searchParams: {
    sort?: 'hot' | 'new' | 'top' | 'controversial'
    category?: string
  }
}

export default async function ThreadsPage({ searchParams }: ThreadsPageProps) {
  const sortBy = searchParams.sort || 'hot'
  const categoryId = searchParams.category || 'all'

  // Fetch threads and categories server-side
  const [threadsResult, categoriesResult] = await Promise.all([
    ThreadHelpers.getAllThreads({
      sortBy,
      categoryId: categoryId === 'all' ? undefined : categoryId,
      limit: 50,
      useServerClient: true,
    }),
    CategoryHelpers.getMainCategories({ useServerClient: true }),
  ])

  if (threadsResult.error) {
    return (
      <Container size="lg">
        <Title order={1} mb="xl">All Discussions</Title>
        <div>Error loading threads: {threadsResult.error}</div>
      </Container>
    )
  }

  return (
    <Container size="lg">
      <Group justify="space-between" mb="xl">
        <Title order={1}>All Discussions</Title>
        <Button
          component={Link}
          href="/threads/new"
          leftSection={<IconPlus size={16} />}
        >
          New Thread
        </Button>
      </Group>

      <ThreadFilters
        categories={categoriesResult.categories || []}
        currentSort={sortBy}
        currentCategory={categoryId}
      />

      <Suspense fallback={<ThreadSkeleton count={10} />}>
        <ThreadListContainer
          threads={threadsResult.threads}
          loading={false}
          showViewToggle={false}
        />
      </Suspense>
    </Container>
  )
}
