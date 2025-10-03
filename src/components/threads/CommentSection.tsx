'use client'

import { useEffect, useState } from 'react'
import {
  Stack,
  Card,
  Text,
  Textarea,
  Button,
  Group,
  Avatar,
  ActionIcon,
  Skeleton,
  Alert,
  Badge,
} from '@mantine/core'
import { IconArrowUp, IconArrowDown, IconCornerDownRight, IconAlertCircle } from '@tabler/icons-react'
import { CommentHelpers, type NestedComment } from '@/lib/database'
import { useAuth } from '@/hooks/use-auth'
import { notifications } from '@mantine/notifications'
import { logger } from '@/lib/logger'

interface CommentSectionProps {
  threadId: string
}

export function CommentSection({ threadId }: CommentSectionProps) {
  const { user } = useAuth()
  const [comments, setComments] = useState<NestedComment[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [commentContent, setCommentContent] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [replyingTo, setReplyingTo] = useState<string | null>(null)
  const [replyContent, setReplyContent] = useState('')

  // Fetch comments on mount
  useEffect(() => {
    fetchComments()
  }, [threadId])

  const fetchComments = async () => {
    try {
      setLoading(true)
      setError(null)

      const { comments: fetchedComments, error: fetchError } =
        await CommentHelpers.getThreadComments(threadId, {
          sortBy: 'best',
          maxDepth: 10,
        })

      if (fetchError) {
        setError(fetchError)
        logger.error('Failed to fetch comments:', fetchError)
        return
      }

      setComments(fetchedComments)
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to load comments'
      setError(errorMessage)
      logger.error('Error fetching comments:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleSubmitComment = async () => {
    if (!user) {
      notifications.show({
        title: 'Authentication required',
        message: 'Please log in to post comments',
        color: 'yellow',
      })
      return
    }

    if (!commentContent.trim()) {
      return
    }

    try {
      setSubmitting(true)

      const { comment, error } = await CommentHelpers.createComment({
        thread_id: threadId,
        user_id: user.id,
        content: commentContent.trim(),
        parent_id: null,
      })

      if (error) {
        notifications.show({
          title: 'Error',
          message: error,
          color: 'red',
        })
        return
      }

      notifications.show({
        title: 'Success',
        message: 'Comment posted successfully',
        color: 'green',
      })

      setCommentContent('')
      await fetchComments() // Refresh comments
    } catch (err) {
      logger.error('Error posting comment:', err)
      notifications.show({
        title: 'Error',
        message: 'Failed to post comment',
        color: 'red',
      })
    } finally {
      setSubmitting(false)
    }
  }

  const handleSubmitReply = async (parentId: string) => {
    if (!user) {
      notifications.show({
        title: 'Authentication required',
        message: 'Please log in to post replies',
        color: 'yellow',
      })
      return
    }

    if (!replyContent.trim()) {
      return
    }

    try {
      setSubmitting(true)

      const { comment, error } = await CommentHelpers.createComment({
        thread_id: threadId,
        user_id: user.id,
        content: replyContent.trim(),
        parent_id: parentId,
      })

      if (error) {
        notifications.show({
          title: 'Error',
          message: error,
          color: 'red',
        })
        return
      }

      notifications.show({
        title: 'Success',
        message: 'Reply posted successfully',
        color: 'green',
      })

      setReplyContent('')
      setReplyingTo(null)
      await fetchComments() // Refresh comments
    } catch (err) {
      logger.error('Error posting reply:', err)
      notifications.show({
        title: 'Error',
        message: 'Failed to post reply',
        color: 'red',
      })
    } finally {
      setSubmitting(false)
    }
  }

  const renderComment = (comment: NestedComment, depth = 0) => {
    const author = comment.users || { username: 'Unknown', avatar_url: null, level: 1 }
    const maxDepth = 5 // Maximum visible nesting depth

    return (
      <Stack key={comment.id} gap="sm" ml={depth < maxDepth ? depth * 32 : maxDepth * 32}>
        <Card p="md" shadow="xs" withBorder>
          <Group gap="sm" mb="sm">
            <Avatar size="sm" src={author.avatar_url}>
              {author.username[0]?.toUpperCase()}
            </Avatar>
            <Text size="sm" fw={500}>
              {author.username}
            </Text>
            {author.level && (
              <Badge size="xs" color="blue">
                Level {author.level}
              </Badge>
            )}
            <Text size="xs" c="dimmed">
              {comment.created_at ? new Date(comment.created_at).toLocaleDateString() : ''}
            </Text>
            {comment.edited_at && (
              <Text size="xs" c="dimmed" fs="italic">
                (edited)
              </Text>
            )}
          </Group>

          <Text mb="sm" style={{ whiteSpace: 'pre-wrap' }}>
            {comment.is_removed ? (
              <Text c="dimmed" fs="italic">[Comment removed]</Text>
            ) : (
              comment.content
            )}
          </Text>

          {!comment.is_removed && (
            <Group gap="xs">
              <Group gap={4}>
                <ActionIcon variant="subtle" size="sm">
                  <IconArrowUp size={12} />
                </ActionIcon>
                <Text size="sm">{(comment.upvotes || 0) - (comment.downvotes || 0)}</Text>
                <ActionIcon variant="subtle" size="sm">
                  <IconArrowDown size={12} />
                </ActionIcon>
              </Group>

              <ActionIcon
                variant="subtle"
                size="sm"
                onClick={() => setReplyingTo(replyingTo === comment.id ? null : comment.id)}
              >
                <IconCornerDownRight size={12} />
              </ActionIcon>
              <Text size="xs" c="dimmed">Reply</Text>
            </Group>
          )}

          {replyingTo === comment.id && (
            <Stack gap="sm" mt="md">
              <Textarea
                placeholder="Write your reply..."
                value={replyContent}
                onChange={(e) => setReplyContent(e.target.value)}
                minRows={2}
              />
              <Group gap="xs">
                <Button
                  size="xs"
                  onClick={() => handleSubmitReply(comment.id)}
                  loading={submitting}
                  disabled={!replyContent.trim()}
                >
                  Post Reply
                </Button>
                <Button
                  size="xs"
                  variant="subtle"
                  onClick={() => {
                    setReplyingTo(null)
                    setReplyContent('')
                  }}
                >
                  Cancel
                </Button>
              </Group>
            </Stack>
          )}
        </Card>

        {comment.replies && comment.replies.length > 0 && (
          <>
            {comment.replies.map((reply: NestedComment) => renderComment(reply, depth + 1))}
          </>
        )}

        {comment.replyCount > (comment.replies?.length || 0) && depth >= maxDepth && (
          <Text size="xs" c="dimmed" ml={32}>
            {comment.replyCount - (comment.replies?.length || 0)} more {comment.replyCount - (comment.replies?.length || 0) === 1 ? 'reply' : 'replies'}
          </Text>
        )}
      </Stack>
    )
  }

  if (loading) {
    return (
      <Stack gap="lg">
        <Card p="md" shadow="sm" withBorder>
          <Skeleton height={80} mb="md" />
          <Skeleton height={32} width={100} />
        </Card>
        <Stack gap="md">
          {[1, 2, 3].map((i) => (
            <Card key={i} p="md" shadow="xs" withBorder>
              <Group gap="sm" mb="sm">
                <Skeleton height={32} circle />
                <Skeleton height={16} width={80} />
                <Skeleton height={14} width={60} />
              </Group>
              <Skeleton height={60} />
              <Group gap="xs" mt="sm">
                <Skeleton height={24} width={80} />
                <Skeleton height={24} width={60} />
              </Group>
            </Card>
          ))}
        </Stack>
      </Stack>
    )
  }

  if (error) {
    return (
      <Alert icon={<IconAlertCircle size={16} />} color="red">
        Failed to load comments: {error}
      </Alert>
    )
  }

  return (
    <Stack gap="lg">
      <Card p="md" shadow="sm" withBorder>
        <Textarea
          placeholder={user ? "Add a comment..." : "Please log in to comment"}
          minRows={3}
          mb="md"
          value={commentContent}
          onChange={(e) => setCommentContent(e.target.value)}
          disabled={!user || submitting}
        />
        <Group justify="flex-end">
          <Button
            onClick={handleSubmitComment}
            disabled={!user || !commentContent.trim() || submitting}
            loading={submitting}
          >
            Post Comment
          </Button>
        </Group>
      </Card>

      {comments.length === 0 ? (
        <Card p="xl" shadow="xs" withBorder>
          <Text ta="center" c="dimmed">
            No comments yet. Be the first to comment!
          </Text>
        </Card>
      ) : (
        <Stack gap="md">
          {comments.map(comment => renderComment(comment))}
        </Stack>
      )}
    </Stack>
  )
}