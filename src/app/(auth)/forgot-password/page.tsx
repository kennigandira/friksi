import { Paper, Title, Text, Anchor } from '@mantine/core'
import { ForgotPasswordForm } from '@/components/auth/ForgotPasswordForm'
import Link from 'next/link'

export default function ForgotPasswordPage() {
  return (
    <Paper shadow="xl" p="xl" radius="md" withBorder>
      <Title order={2} ta="center" mb="md">
        Reset Your Password
      </Title>

      <Text c="dimmed" size="sm" ta="center" mb="xl">
        Enter your email address and we&apos;ll send you a link to reset your
        password
      </Text>

      <ForgotPasswordForm />

      <Text ta="center" mt="md" size="sm">
        Remember your password?{' '}
        <Anchor component={Link} href="/login" fw={500}>
          Sign in
        </Anchor>
      </Text>
    </Paper>
  )
}
