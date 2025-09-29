'use client'

import { Stack, Paper, Title, SegmentedControl, Group, Text, Loader, Center, Button } from '@mantine/core'
import { IconTrendingUp, IconClock, IconFlame, IconMessagePlus } from '@tabler/icons-react'
import { CommentItem } from './CommentItem'
import { CommentForm } from './CommentForm'
import { useComments } from '@/hooks/useComments'
import { useAuth } from '@/hooks/useAuth'

interface CommentSectionProps {
  threadId: string
}

export function CommentSection({ threadId }: CommentSectionProps) {
  const { user } = useAuth()
  const {
    comments,
    loading,
    error,
    sortBy,
    setSortBy,
    loadingMore,
    hasMore,
    loadMore,
    addComment,
    updateComment,
    deleteComment,
    loadReplies,
  } = useComments({ threadId })

  const sortOptions = [
    { value: 'best', label: 'Best', icon: <IconTrendingUp size={14} /> },
    { value: 'new', label: 'New', icon: <IconClock size={14} /> },
    { value: 'controversial', label: 'Hot', icon: <IconFlame size={14} /> },
  ]

  const handleAddComment = async (content: string) => {
    return await addComment(content)
  }

  const handleReply = async (parentId: string, content: string) => {
    return await addComment(content, parentId)
  }

  const handleEdit = async (commentId: string, content: string) => {
    return await updateComment(commentId, content)
  }

  const handleDelete = async (commentId: string) => {
    return await deleteComment(commentId)
  }

  const handleLoadReplies = (commentId: string) => {
    loadReplies(commentId)
  }

  return (
    <Stack gap="md" mt="lg">
      {/* Comment section header */}
      <Paper p="md" withBorder radius="md">
        <Group justify="space-between" mb="md">
          <Title order={3} size="h4">
            Comments ({comments.length})
          </Title>

          <SegmentedControl
            value={sortBy}
            onChange={value => setSortBy(value as 'best' | 'new' | 'controversial')}
            data={sortOptions.map(opt => ({
              value: opt.value,
              label: (
                <Group gap={4}>
                  {opt.icon}
                  <span>{opt.label}</span>
                </Group>
              ),
            }))}
            size="xs"
          />
        </Group>

        {/* Comment form */}
        {user ? (
          <CommentForm
            onSubmit={handleAddComment}
            placeholder="Share your thoughts..."
            submitLabel="Post Comment"
          />
        ) : (
          <Paper p="md" withBorder radius="md" bg="gray.0">
            <Group>
              <IconMessagePlus size={20} className="text-gray-500" />
              <Text size="sm" c="dimmed">
                Please log in to comment
              </Text>
            </Group>
          </Paper>
        )}
      </Paper>

      {/* Comments list */}
      {loading ? (
        <Center py="xl">
          <Loader size="lg" />
        </Center>
      ) : error ? (
        <Paper p="md" withBorder radius="md">
          <Text c="red" size="sm">
            Error loading comments: {error}
          </Text>
        </Paper>
      ) : comments.length === 0 ? (
        <Paper p="xl" withBorder radius="md">
          <Center>
            <Stack align="center" gap="xs">
              <IconMessagePlus size={32} className="text-gray-400" />
              <Text c="dimmed" size="sm">
                No comments yet. Be the first to share your thoughts!
              </Text>
            </Stack>
          </Center>
        </Paper>
      ) : (
        <>
          <Stack gap={0}>
            {comments.map(comment => (
              <CommentItem
                key={comment.id}
                comment={comment}
                depth={0}
                onReply={handleReply}
                onEdit={handleEdit}
                onDelete={handleDelete}
                onLoadMore={handleLoadReplies}
              />
            ))}
          </Stack>

          {/* Load more button */}
          {hasMore && (
            <Center>
              <Button
                variant="subtle"
                onClick={loadMore}
                loading={loadingMore}
                disabled={loadingMore}
              >
                Load more comments
              </Button>
            </Center>
          )}
        </>
      )}
    </Stack>
  )
}