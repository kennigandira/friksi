'use client'

import {
  Stack,
  TextInput,
  Textarea,
  Select,
  Button,
  Group,
  Card,
} from '@mantine/core'
import { useForm } from '@mantine/form'

interface ThreadCreateFormData {
  title: string
  content: string
  categoryId: string
}

export function ThreadCreateForm() {
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

  const handleSubmit = (values: ThreadCreateFormData) => {
    console.log('Creating thread:', values)
    // TODO: Implement thread creation
  }

  return (
    <Card p="lg" shadow="sm" withBorder>
      <form onSubmit={form.onSubmit(handleSubmit)}>
        <Stack gap="md">
          <TextInput
            label="Thread Title"
            placeholder="What would you like to discuss?"
            required
            {...form.getInputProps('title')}
          />

          <Select
            label="Category"
            placeholder="Select a category"
            data={[
              { value: 'technology', label: 'Technology' },
              { value: 'politics', label: 'Politics' },
              { value: 'science', label: 'Science' },
              { value: 'environment', label: 'Environment' },
              { value: 'local', label: 'Local Issues' },
            ]}
            required
            {...form.getInputProps('categoryId')}
          />

          <Textarea
            label="Content"
            placeholder="Share your thoughts and start the discussion..."
            minRows={6}
            required
            {...form.getInputProps('content')}
          />

          <Group justify="flex-end">
            <Button variant="subtle">Save as Draft</Button>
            <Button type="submit">Create Thread</Button>
          </Group>
        </Stack>
      </form>
    </Card>
  )
}
