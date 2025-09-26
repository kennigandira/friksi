import { Title, Group, Button, Select, Container } from '@mantine/core'
import { ThreadList } from '@/components/threads/ThreadList'
import { IconPlus } from '@tabler/icons-react'
import Link from 'next/link'

export default function ThreadsPage() {
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

      <Group mb="lg">
        <Select
          placeholder="Sort by"
          data={[
            { value: 'hot', label: 'Hot' },
            { value: 'new', label: 'New' },
            { value: 'top', label: 'Top' },
            { value: 'controversial', label: 'Controversial' },
          ]}
          defaultValue="hot"
        />
        <Select
          placeholder="Filter by category"
          data={[
            { value: 'all', label: 'All Categories' },
            { value: 'technology', label: 'Technology' },
            { value: 'politics', label: 'Politics' },
            { value: 'science', label: 'Science' },
          ]}
          defaultValue="all"
        />
      </Group>

      <ThreadList sortBy="hot" />
    </Container>
  )
}
