import { notFound } from 'next/navigation'
import { Container, Title, Text, Group, Button, Stack, Badge, Alert, Paper, Divider, SimpleGrid, Avatar } from '@mantine/core'
import { IconMessage, IconFlame, IconClock, IconTrophy, IconUsers, IconHeart, IconHeartFilled, IconPlus, IconInfoCircle, IconArrowUp } from '@tabler/icons-react'
import Link from 'next/link'
import { CategoryHelpers } from '@/lib/database/helpers/categories'
import { ThreadHelpers } from '@/lib/database/helpers/threads'
import { createServerSupabaseClient } from '@/lib/database/lib/server'
import { ThreadList } from '@/components/threads/ThreadList'

export const revalidate = 60 // Revalidate every 60 seconds

interface CategoryPageProps {
  params: {
    slug: string
  }
  searchParams?: {
    sort?: 'hot' | 'new' | 'top' | 'wilson'
    page?: string
  }
}

export default async function CategoryPage({ params, searchParams }: CategoryPageProps) {
  const { slug } = params
  const rawSort = searchParams?.sort || 'hot'
  // Map wilson to top since ThreadList doesn't support wilson sort
  const sort = rawSort === 'wilson' ? 'top' : (rawSort as 'hot' | 'new' | 'top')
  const page = parseInt(searchParams?.page || '1')
  const limit = 20

  // Get current user
  const supabase = createServerSupabaseClient()
  const { data: { user } } = await supabase.auth.getUser()

  // Fetch category details
  const { category, error: categoryError } = await CategoryHelpers.getCategoryBySlug(
    slug,
    {
      useServerClient: true,
      ...(user?.id && { userId: user.id })
    }
  )

  if (categoryError || !category) {
    notFound()
  }

  // Fetch threads for this category
  const { threads, error: threadsError } = await ThreadHelpers.getThreadsByCategory(
    category.id,
    {
      sortBy: sort,
      limit,
      offset: (page - 1) * limit,
      includeRemoved: false
    }
  )

  // TODO: Get actual total count from database
  const totalCount = 0

  // Calculate pagination
  const totalPages = Math.ceil((totalCount || 0) / limit)
  const hasNextPage = page < totalPages
  const hasPrevPage = page > 1

  // Get subcategories if any exist
  const { categories: subcategories } = await CategoryHelpers.getCategories({
    parentId: category.id,
    useServerClient: true,
    ...(user?.id && { userId: user.id })
  })

  return (
    <Container size="lg">
      {/* Breadcrumb Navigation */}
      <Group gap="xs" mb="md">
        <Link href="/" style={{ textDecoration: 'none', color: 'inherit' }}>
          <Text size="sm" c="dimmed">Home</Text>
        </Link>
        <Text size="sm" c="dimmed">/</Text>
        <Link href="/category" style={{ textDecoration: 'none', color: 'inherit' }}>
          <Text size="sm" c="dimmed">Categories</Text>
        </Link>
        <Text size="sm" c="dimmed">/</Text>
        <Text size="sm" fw={500}>{category.name}</Text>
      </Group>

      {/* Category Header */}
      <Paper p="xl" mb="xl" withBorder>
        <Stack gap="md">
          <Group justify="space-between" align="flex-start">
            <div style={{ flex: 1 }}>
              <Group gap="md" mb="sm">
                {category.icon_url && (
                  <Avatar
                    src={category.icon_url}
                    size="lg"
                    radius="sm"
                    color={category.color || 'blue'}
                  />
                )}
                <div>
                  <Title order={1} style={{ color: category.color || undefined }}>
                    {category.name}
                  </Title>
                  {category.is_locked && (
                    <Badge color="red" size="sm" mt={4}>
                      Locked
                    </Badge>
                  )}
                </div>
              </Group>

              {category.description && (
                <Text size="lg" c="dimmed" mb="md">
                  {category.description}
                </Text>
              )}

              <Group gap="xl">
                <Group gap={4}>
                  <IconMessage size={18} />
                  <Text size="sm">
                    <strong>{category.post_count || 0}</strong> threads
                  </Text>
                </Group>
                <Group gap={4}>
                  <IconUsers size={18} />
                  <Text size="sm">
                    <strong>{category.subscriber_count || 0}</strong> subscribers
                  </Text>
                </Group>
              </Group>
            </div>

            <Stack gap="sm">
              {user ? (
                <>
                  <Button
                    leftSection={category.is_subscribed ? <IconHeartFilled size={18} /> : <IconHeart size={18} />}
                    variant={category.is_subscribed ? "filled" : "outline"}
                    color={category.is_subscribed ? "red" : "blue"}
                  >
                    {category.is_subscribed ? 'Subscribed' : 'Subscribe'}
                  </Button>
                  {!category.is_locked && (
                    <Button
                      component={Link}
                      href={`/threads/new?category=${category.slug}`}
                      leftSection={<IconPlus size={18} />}
                      variant="filled"
                    >
                      Create Thread
                    </Button>
                  )}
                </>
              ) : (
                <Button
                  component={Link}
                  href="/login"
                  variant="filled"
                >
                  Login to Participate
                </Button>
              )}
            </Stack>
          </Group>

          {/* Subcategories if any */}
          {subcategories && subcategories.length > 0 && (
            <>
              <Divider />
              <div>
                <Text fw={500} mb="sm">Subcategories</Text>
                <Group gap="sm">
                  {subcategories.map(subcat => (
                    <Button
                      key={subcat.id}
                      component={Link}
                      href={`/category/${subcat.slug}`}
                      variant="light"
                      size="sm"
                      leftSection={subcat.icon_url && (
                        <Avatar
                          src={subcat.icon_url}
                          size={16}
                          radius="xs"
                        />
                      )}
                      style={{
                        borderColor: subcat.color || undefined,
                        color: subcat.color || undefined
                      }}
                    >
                      {subcat.name}
                      <Badge size="xs" variant="filled" ml={4}>
                        {subcat.post_count || 0}
                      </Badge>
                    </Button>
                  ))}
                </Group>
              </div>
            </>
          )}
        </Stack>
      </Paper>

      {/* Sorting Buttons */}
      <Group mb="xl">
        <Button
          component={Link}
          href={`/category/${slug}?sort=hot`}
          variant={rawSort === 'hot' ? 'filled' : 'light'}
          leftSection={<IconFlame size={16} />}
          size="sm"
        >
          Hot
        </Button>
        <Button
          component={Link}
          href={`/category/${slug}?sort=new`}
          variant={rawSort === 'new' ? 'filled' : 'light'}
          leftSection={<IconClock size={16} />}
          size="sm"
        >
          New
        </Button>
        <Button
          component={Link}
          href={`/category/${slug}?sort=top`}
          variant={rawSort === 'top' ? 'filled' : 'light'}
          leftSection={<IconTrophy size={16} />}
          size="sm"
        >
          Top
        </Button>
        <Button
          component={Link}
          href={`/category/${slug}?sort=wilson`}
          variant={rawSort === 'wilson' ? 'filled' : 'light'}
          leftSection={<IconArrowUp size={16} />}
          size="sm"
        >
          Best
        </Button>
      </Group>

      {/* Threads List */}
      {threadsError ? (
        <Alert
          icon={<IconInfoCircle size={16} />}
          color="red"
          title="Error loading threads"
        >
          <Text>Unable to load threads. Please try again later.</Text>
          <Text size="sm" c="dimmed" mt="xs">
            {threadsError}
          </Text>
        </Alert>
      ) : threads && threads.length > 0 ? (
        <>
          <ThreadList categoryId={category.id} sortBy={sort} />

          {/* Pagination */}
          {totalPages > 1 && (
            <Group justify="center" mt="xl">
              <Button
                component={Link}
                href={`/category/${slug}?sort=${sort}&page=${page - 1}`}
                disabled={!hasPrevPage}
                variant="default"
              >
                Previous
              </Button>
              <Text size="sm" c="dimmed">
                Page {page} of {totalPages}
              </Text>
              <Button
                component={Link}
                href={`/category/${slug}?sort=${sort}&page=${page + 1}`}
                disabled={!hasNextPage}
                variant="default"
              >
                Next
              </Button>
            </Group>
          )}
        </>
      ) : (
        <Paper p="xl" withBorder>
          <Stack align="center" gap="md">
            <IconMessage size={48} style={{ opacity: 0.5 }} />
            <Title order={3} c="dimmed">No threads yet</Title>
            <Text c="dimmed" ta="center">
              Be the first to start a discussion in {category.name}!
            </Text>
            {user && !category.is_locked && (
              <Button
                component={Link}
                href={`/threads/new?category=${category.slug}`}
                leftSection={<IconPlus size={18} />}
                variant="filled"
                mt="md"
              >
                Create First Thread
              </Button>
            )}
          </Stack>
        </Paper>
      )}
    </Container>
  )
}

// Generate metadata for SEO
export async function generateMetadata({ params }: CategoryPageProps) {
  const { category } = await CategoryHelpers.getCategoryBySlug(params.slug, {
    useServerClient: true
  })

  if (!category) {
    return {
      title: 'Category Not Found'
    }
  }

  return {
    title: `${category.name} - Friksi`,
    description: category.description || `Browse threads in ${category.name}`,
    openGraph: {
      title: `${category.name} - Friksi`,
      description: category.description || `Browse threads in ${category.name}`,
      type: 'website'
    }
  }
}