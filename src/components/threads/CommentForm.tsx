'use client'

import { useState } from 'react'
import { Textarea, Button, Group, Text, Paper } from '@mantine/core'
import { IconSend, IconX } from '@tabler/icons-react'

interface CommentFormProps {
  onSubmit: (content: string) => Promise<{ success: boolean; error?: string }>
  onCancel?: () => void
  initialContent?: string
  placeholder?: string
  submitLabel?: string
  maxLength?: number
}

export function CommentForm({
  onSubmit,
  onCancel,
  initialContent = '',
  placeholder = 'Write a comment...',
  submitLabel = 'Post',
  maxLength = 5000,
}: CommentFormProps) {
  const [content, setContent] = useState(initialContent)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const remainingChars = maxLength - content.length
  const isOverLimit = remainingChars < 0

  const handleSubmit = async () => {
    if (content.trim().length === 0) {
      setError('Comment cannot be empty')
      return
    }

    if (isOverLimit) {
      setError(`Comment is ${Math.abs(remainingChars)} characters over the limit`)
      return
    }

    setIsSubmitting(true)
    setError(null)

    const result = await onSubmit(content.trim())

    if (result.success) {
      setContent('')
    } else {
      setError(result.error || 'Failed to submit comment')
    }

    setIsSubmitting(false)
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    // Submit on Ctrl/Cmd + Enter
    if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) {
      e.preventDefault()
      handleSubmit()
    }
  }

  return (
    <Paper p="sm" withBorder radius="md">
      <Textarea
        value={content}
        onChange={e => setContent(e.currentTarget.value)}
        onKeyDown={handleKeyDown}
        placeholder={placeholder}
        minRows={3}
        maxRows={10}
        disabled={isSubmitting}
        error={error}
        styles={{
          input: {
            fontSize: '14px',
            lineHeight: '1.5',
          },
        }}
      />

      <Group justify="space-between" mt="xs">
        <Group gap="xs">
          <Text size="xs" c={isOverLimit ? 'red' : remainingChars < 100 ? 'orange' : 'dimmed'}>
            {remainingChars.toLocaleString()} characters remaining
          </Text>
          <Text size="xs" c="dimmed">
            Ctrl+Enter to submit
          </Text>
        </Group>

        <Group gap="xs">
          {onCancel && (
            <Button
              variant="subtle"
              size="sm"
              leftSection={<IconX size={14} />}
              onClick={onCancel}
              disabled={isSubmitting}
            >
              Cancel
            </Button>
          )}
          <Button
            size="sm"
            leftSection={<IconSend size={14} />}
            onClick={handleSubmit}
            loading={isSubmitting}
            disabled={content.trim().length === 0 || isOverLimit}
          >
            {submitLabel}
          </Button>
        </Group>
      </Group>
    </Paper>
  )
}