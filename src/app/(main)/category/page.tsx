import {
  Container,
  Title,
  SimpleGrid,
  Alert,
  Text,
} from '@mantine/core'
import { IconInfoCircle } from '@tabler/icons-react'
import { CategoryCard } from '@/components/threads/CategoryCard'
import { CategoryHelpers } from '@/lib/database/helpers/categories'
import { createServerSupabaseClient } from '@/lib/database/lib/server'

export const revalidate = 60 // Revalidate every 60 seconds

export default async function CategoriesPage() {
  // Get the current user (if authenticated) using our existing server client
  const supabase = createServerSupabaseClient()
  const { data: { user } } = await supabase.auth.getUser()

  // Fetch categories from database with subscription status
  const { categories, error } = await CategoryHelpers.getCategories({
    useServerClient: true,
    userId: user?.id,
    parentId: null, // Only get top-level categories
  })

  if (error) {
    return (
      <Container size="lg">
        <Title order={1} mb="xl">
          Discussion Categories
        </Title>
        <Alert icon={<IconInfoCircle size={16} />} color="red" title="Error loading categories">
          <Text>Unable to load categories. Please try again later.</Text>
          <Text size="sm" c="dimmed" mt="xs">{error}</Text>
        </Alert>
      </Container>
    )
  }

  // If no categories exist, show a message
  if (categories.length === 0) {
    return (
      <Container size="lg">
        <Title order={1} mb="xl">
          Discussion Categories
        </Title>
        <Alert icon={<IconInfoCircle size={16} />} color="blue">
          <Text>No categories available yet. Check back soon!</Text>
        </Alert>
      </Container>
    )
  }

  return (
    <Container size="lg">
      <Title order={1} mb="xl">
        Discussion Categories
      </Title>

      <SimpleGrid cols={{ base: 1, sm: 2, lg: 3 }} spacing="lg">
        {categories.map((category) => (
          <CategoryCard
            key={category.id}
            id={category.id}
            name={category.name}
            slug={category.slug}
            description={category.description || ''}
            threadCount={category.post_count || 0}
            subscriberCount={category.subscriber_count || 0}
            isSubscribed={category.is_subscribed || false}
            color={category.color}
            iconUrl={category.icon_url}
            userId={user?.id}
          />
        ))}
      </SimpleGrid>
    </Container>
  )
}
