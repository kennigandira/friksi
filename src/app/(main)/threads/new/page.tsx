import { Container, Title } from '@mantine/core'
import { ThreadCreateForm } from '@/components/threads/ThreadCreateForm'
import { AuthGuard } from '@/components/auth/AuthGuard'

export default function NewThreadPage() {
  return (
    <AuthGuard minLevel={2}>
      <Container size="md">
        <Title order={1} mb="xl">
          Create New Discussion
        </Title>

        <ThreadCreateForm />
      </Container>
    </AuthGuard>
  )
}
