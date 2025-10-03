'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import {
  Stack,
  TextInput,
  Textarea,
  Select,
  Button,
  Group,
  Card,
  Alert,
  Loader,
  Center,
} from '@mantine/core'
import { useForm } from '@mantine/form'
import { IconAlertCircle } from '@tabler/icons-react'
import { useAuth } from '@/hooks/use-auth'
import { ThreadHelpers, getBrowserSupabaseClient } from '@/lib/database'
import { logger } from '@/lib/logger'

interface ThreadCreateFormData {
  title: string
  content: string
  categoryId: string
}

interface Category {
  id: string
  name: string
}

export function ThreadCreateForm() {
  const router = useRouter()
  const { user } = useAuth()

  const [categories, setCategories] = useState<Category[]>([])
  const [loadingCategories, setLoadingCategories] = useState(true)
  const [categoryError, setCategoryError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [submitError, setSubmitError] = useState<string | null>(null)

  const form = useForm<ThreadCreateFormData>({
    initialValues: {
      title: '',
      content: '',
      categoryId: '',
    },
    validate: {
      title: value =>
        value.length < 5 ? 'Title must be at least 5 characters' : null,
      content: value =>
        value.length < 20 ? 'Content must be at least 20 characters' : null,
      categoryId: value => (!value ? 'Please select a category' : null),
    },
  })

  // Fetch categories on mount
  useEffect(() => {
    const fetchCategories = async () => {
      try {
        const supabase = getBrowserSupabaseClient()
        const { data, error } = await supabase
          .from('categories')
          .select('id, name')
          .eq('is_active', true)
          .order('name')

        if (error) throw error

        setCategories(data || [])
      } catch (err) {
        logger.error('Failed to fetch categories:', err)
        setCategoryError('Failed to load categories. Please refresh the page.')
      } finally {
        setLoadingCategories(false)
      }
    }

    fetchCategories()
  }, [])

  const handleSubmit = async (values: ThreadCreateFormData) => {
    // Clear previous errors
    setSubmitError(null)

    // Check authentication
    if (!user) {
      setSubmitError('You must be logged in to create a thread.')
      return
    }

    // Check user level (Level 2+ required)
    const userLevel = user.level ?? 1
    if (userLevel < 2) {
      setSubmitError(
        `You need to be at least Level 2 to create threads. Your current level is ${userLevel}.`
      )
      return
    }

    setSubmitting(true)

    try {
      const { thread, error } = await ThreadHelpers.createThread({
        user_id: user.id,
        category_id: values.categoryId,
        title: values.title.trim(),
        content: values.content.trim(),
      })

      if (error) {
        throw new Error(error)
      }

      if (!thread) {
        throw new Error('Thread creation failed. Please try again.')
      }

      // Success - redirect to the new thread
      router.push(`/threads/${thread.id}`)
    } catch (err) {
      setSubmitError(
        err instanceof Error ? err.message : 'Failed to create thread. Please try again.'
      )
      setSubmitting(false)
    }
  }

  // Show loading spinner while fetching categories
  if (loadingCategories) {
    return (
      <Card p="lg" shadow="sm" withBorder>
        <Center py="xl">
          <Loader size="md" />
        </Center>
      </Card>
    )
  }

  return (
    <Card p="lg" shadow="sm" withBorder>
      <form onSubmit={form.onSubmit(handleSubmit)}>
        <Stack gap="md">
          {/* Display category loading error */}
          {categoryError && (
            <Alert
              icon={<IconAlertCircle size={16} />}
              title="Error"
              color="red"
            >
              {categoryError}
            </Alert>
          )}

          {/* Display submission error */}
          {submitError && (
            <Alert
              icon={<IconAlertCircle size={16} />}
              title="Error"
              color="red"
            >
              {submitError}
            </Alert>
          )}

          <TextInput
            label="Thread Title"
            placeholder="What would you like to discuss?"
            required
            disabled={submitting}
            {...form.getInputProps('title')}
          />

          <Select
            label="Category"
            placeholder="Select a category"
            data={categories.map(cat => ({
              value: cat.id,
              label: cat.name,
            }))}
            required
            disabled={submitting || categories.length === 0}
            {...form.getInputProps('categoryId')}
          />

          <Textarea
            label="Content"
            placeholder="Share your thoughts and start the discussion..."
            minRows={6}
            required
            disabled={submitting}
            {...form.getInputProps('content')}
          />

          <Group justify="flex-end">
            <Button variant="subtle" disabled={submitting}>
              Save as Draft
            </Button>
            <Button type="submit" loading={submitting}>
              Create Thread
            </Button>
          </Group>
        </Stack>
      </form>
    </Card>
  )
}
