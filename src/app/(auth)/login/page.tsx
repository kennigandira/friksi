import { Paper, Title, Text, Anchor } from '@mantine/core'
import { LoginForm } from '@/components/auth/LoginForm'
import Link from 'next/link'

export default function LoginPage() {
  return (
    <Paper shadow="xl" p="xl" radius="md" withBorder>
      <Title order={2} ta="center" mb="md">
        Welcome back to Friksi
      </Title>

      <Text c="dimmed" size="sm" ta="center" mb="xl">
        Sign in to continue your civic engagement
      </Text>

      <LoginForm />

      <Text ta="center" mt="md" size="sm">
        Don&apos;t have an account?{' '}
        <Anchor component={Link} href="/register" fw={500}>
          Create account
        </Anchor>
      </Text>

      <Text ta="center" mt="xs" size="sm">
        <Anchor component={Link} href="/forgot-password" c="dimmed">
          Forgot your password?
        </Anchor>
      </Text>
    </Paper>
  )
}
