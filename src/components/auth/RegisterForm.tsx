'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import {
  TextInput,
  PasswordInput,
  Button,
  Stack,
  Alert,
  Checkbox,
  Text,
} from '@mantine/core'
import { useForm } from '@mantine/form'
import { IconAlertCircle } from '@tabler/icons-react'
import { useAuth } from '@/hooks/use-auth'

interface RegisterFormData {
  username: string
  email: string
  password: string
  confirmPassword: string
  acceptTerms: boolean
}

export function RegisterForm() {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const { register } = useAuth()
  const router = useRouter()

  const form = useForm<RegisterFormData>({
    initialValues: {
      username: '',
      email: '',
      password: '',
      confirmPassword: '',
      acceptTerms: false,
    },
    validate: {
      username: value => {
        if (value.length < 3) return 'Username must be at least 3 characters'
        if (!/^[a-zA-Z0-9_]+$/.test(value))
          return 'Username can only contain letters, numbers, and underscores'
        return null
      },
      email: value => (/^\S+@\S+$/.test(value) ? null : 'Invalid email'),
      password: value => {
        if (value.length < 8) return 'Password must be at least 8 characters'
        if (!/(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/.test(value)) {
          return 'Password must contain at least one uppercase letter, lowercase letter, and number'
        }
        return null
      },
      confirmPassword: (value, values) =>
        value !== values.password ? 'Passwords do not match' : null,
      acceptTerms: value =>
        value ? null : 'You must accept the terms and conditions',
    },
  })

  const handleSubmit = async (values: RegisterFormData) => {
    setLoading(true)
    setError(null)

    try {
      const result = await register({
        username: values.username,
        email: values.email,
        password: values.password,
      })

      if (result.error) {
        setError(result.error)
      } else {
        router.push('/')
      }
    } catch (err) {
      setError('An unexpected error occurred')
    } finally {
      setLoading(false)
    }
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
          label="Username"
          placeholder="Choose a unique username"
          required
          {...form.getInputProps('username')}
        />

        <TextInput
          label="Email"
          placeholder="your@email.com"
          required
          {...form.getInputProps('email')}
        />

        <PasswordInput
          label="Password"
          placeholder="Create a strong password"
          required
          {...form.getInputProps('password')}
        />

        <PasswordInput
          label="Confirm Password"
          placeholder="Confirm your password"
          required
          {...form.getInputProps('confirmPassword')}
        />

        <Checkbox
          label={
            <Text size="sm">
              I accept the{' '}
              <Text
                component="a"
                href="/terms"
                target="_blank"
                c="blue"
                td="underline"
              >
                Terms of Service
              </Text>{' '}
              and{' '}
              <Text
                component="a"
                href="/privacy"
                target="_blank"
                c="blue"
                td="underline"
              >
                Privacy Policy
              </Text>
            </Text>
          }
          required
          {...form.getInputProps('acceptTerms', { type: 'checkbox' })}
        />

        <Button type="submit" loading={loading} fullWidth>
          Create Account
        </Button>
      </Stack>
    </form>
  )
}
