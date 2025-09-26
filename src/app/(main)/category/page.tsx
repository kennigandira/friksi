import {
  Container,
  Title,
  SimpleGrid,
  Card,
  Text,
  Badge,
  Group,
} from '@mantine/core'
import { CategoryCard } from '@/components/threads/CategoryCard'

export default function CategoriesPage() {
  return (
    <Container size="lg">
      <Title order={1} mb="xl">
        Discussion Categories
      </Title>

      <SimpleGrid cols={{ base: 1, sm: 2, lg: 3 }} spacing="lg">
        <CategoryCard
          name="Technology"
          slug="technology"
          description="Discuss the latest in tech, programming, and innovation"
          threadCount={234}
          subscriberCount={1250}
          isSubscribed={false}
        />

        <CategoryCard
          name="Politics"
          slug="politics"
          description="Civil political discussions and policy debates"
          threadCount={189}
          subscriberCount={890}
          isSubscribed={true}
        />

        <CategoryCard
          name="Science"
          slug="science"
          description="Scientific discoveries, research, and discussions"
          threadCount={156}
          subscriberCount={720}
          isSubscribed={false}
        />

        <CategoryCard
          name="Environment"
          slug="environment"
          description="Climate change, sustainability, and environmental topics"
          threadCount={98}
          subscriberCount={540}
          isSubscribed={true}
        />

        <CategoryCard
          name="Local Issues"
          slug="local"
          description="Discuss issues affecting your local community"
          threadCount={67}
          subscriberCount={320}
          isSubscribed={false}
        />

        <CategoryCard
          name="Education"
          slug="education"
          description="Educational policy, school systems, and learning"
          threadCount={45}
          subscriberCount={280}
          isSubscribed={false}
        />
      </SimpleGrid>
    </Container>
  )
}
