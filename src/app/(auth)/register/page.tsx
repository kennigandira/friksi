import { Paper, Title, Text, Anchor } from '@mantine/core'
import { RegisterForm } from '@/components/auth/RegisterForm'
import Link from 'next/link'

export default function RegisterPage() {
  return (
    <Paper shadow="xl" p="xl" radius="md" withBorder>
      <Title order={2} ta="center" mb="md">
        Join the Friksi Community
      </Title>

      <Text c="dimmed" size="sm" ta="center" mb="xl">
        Create your account to start participating in civic discussions
      </Text>

      <RegisterForm />

      <Text ta="center" mt="md" size="sm">
        Already have an account?{' '}
        <Anchor component={Link} href="/login" fw={500}>
          Sign in
        </Anchor>
      </Text>
    </Paper>
  )
}
