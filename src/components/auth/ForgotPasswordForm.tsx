'use client'

import { useState } from 'react'
import { TextInput, Button, Stack, Alert, Text } from '@mantine/core'
import { useForm } from '@mantine/form'
import { IconAlertCircle, IconCheck } from '@tabler/icons-react'
import { useAuth } from '@/hooks/use-auth'

interface ForgotPasswordFormData {
  email: string
}

export function ForgotPasswordForm() {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState(false)
  const { resetPassword } = useAuth()

  const form = useForm<ForgotPasswordFormData>({
    initialValues: {
      email: '',
    },
    validate: {
      email: value => (/^\S+@\S+$/.test(value) ? null : 'Invalid email'),
    },
  })

  const handleSubmit = async (values: ForgotPasswordFormData) => {
    setLoading(true)
    setError(null)

    try {
      const result = await resetPassword(values.email)

      if (result.error) {
        setError(result.error)
      } else {
        setSuccess(true)
      }
    } catch (err) {
      setError('An unexpected error occurred')
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <Alert icon={<IconCheck size={16} />} color="green">
        <Text fw={500} mb="xs">
          Reset link sent!
        </Text>
        <Text size="sm">
          We&apos;ve sent a password reset link to your email address. Please check
          your inbox and follow the instructions.
        </Text>
      </Alert>
    )
  }

  return (
    <form onSubmit={form.onSubmit(handleSubmit)}>
      <Stack gap="md">
        {error && (
          <Alert icon={<IconAlertCircle size={16} />} color="red">
            {error}
          </Alert>
        )}

        <TextInput
          label="Email Address"
          placeholder="Enter your email address"
          required
          {...form.getInputProps('email')}
        />

        <Button type="submit" loading={loading} fullWidth>
          Send Reset Link
        </Button>
      </Stack>
    </form>
  )
}
