'use client'

import { useState } from 'react'
import {
  Paper,
  Group,
  Text,
  Avatar,
  ActionIcon,
  Collapse,
  Stack,
  Button,
  Menu,
  Badge,
} from '@mantine/core'
import {
  IconArrowUp,
  IconArrowDown,
  IconCornerDownRight,
  IconChevronDown,
  IconChevronUp,
  IconDots,
  IconEdit,
  IconTrash,
  IconFlag,
} from '@tabler/icons-react'
import { NestedComment } from '@/lib/database/helpers/comments'
import { TrustIndicator } from './TrustIndicator'
import { useAuth } from '@/hooks/useAuth'
import { useVoting } from '@/hooks/useVoting'
import { formatDistanceToNow } from 'date-fns'
import { CommentForm } from './CommentForm'

interface CommentItemProps {
  comment: NestedComment
  depth: number
  onReply?: (parentId: string, content: string) => Promise<{ success: boolean; error?: string }>
  onEdit?: (commentId: string, content: string) => Promise<{ success: boolean; error?: string }>
  onDelete?: (commentId: string) => Promise<{ success: boolean; error?: string }>
  onLoadMore?: (commentId: string) => void
  maxDepth?: number
}

export function CommentItem({
  comment,
  depth,
  onReply,
  onEdit,
  onDelete,
  onLoadMore,
  maxDepth = 4,
}: CommentItemProps) {
  const { user } = useAuth()
  const [isCollapsed, setIsCollapsed] = useState(false)
  const [showReplyForm, setShowReplyForm] = useState(false)
  const [isEditing, setIsEditing] = useState(false)

  const { stats, upvote, downvote, userVote } = useVoting({
    contentId: comment.id,
    contentType: 'comment',
    initialUpvotes: comment.upvotes,
    initialDownvotes: comment.downvotes,
  })

  const isOwner = user?.id === comment.user_id
  const isDeleted = comment.is_deleted || comment.content === '[deleted]'
  const hasReplies = comment.replies && comment.replies.length > 0

  // Calculate indentation based on depth (max 3 levels visually)
  const visualDepth = Math.min(depth, maxDepth - 1)
  const indentSize = visualDepth * 24 // 24px per level on desktop

  const handleReply = async (content: string) => {
    if (onReply) {
      const result = await onReply(comment.id, content)
      if (result.success) {
        setShowReplyForm(false)
      }
      return result
    }
    return { success: false, error: 'Reply handler not provided' }
  }

  const handleEdit = async (content: string) => {
    if (onEdit) {
      const result = await onEdit(comment.id, content)
      if (result.success) {
        setIsEditing(false)
      }
      return result
    }
    return { success: false, error: 'Edit handler not provided' }
  }

  const handleDelete = async () => {
    if (confirm('Are you sure you want to delete this comment?') && onDelete) {
      await onDelete(comment.id)
    }
  }

  return (
    <div
      style={{ marginLeft: depth > 0 ? `${indentSize}px` : 0 }}
      className="relative"
      role="comment"
      aria-label={`Comment by ${comment.users?.username || 'Unknown'}`}
    >
      {/* Thread line for visual hierarchy */}
      {depth > 0 && depth <= maxDepth && (
        <div
          className="absolute left-0 top-0 bottom-0 w-px bg-gray-200 dark:bg-gray-700"
          style={{ left: '-12px' }}
          aria-hidden="true"
        />
      )}

      <Paper
        p="sm"
        shadow={depth === 0 ? 'xs' : undefined}
        withBorder={depth === 0}
        radius="md"
        className="mb-3"
      >
        {/* Comment header */}
        <Group justify="space-between" mb="xs">
          <Group gap="xs">
            {!isDeleted && comment.users && (
              <>
                <Avatar size="sm" src={comment.users.avatar_url}>
                  {comment.users.username[0]?.toUpperCase()}
                </Avatar>
                <Text size="sm" fw={500}>
                  {comment.users.username}
                </Text>
                <TrustIndicator
                  trustScore={(comment.users as any).trust_score || 50}
                  botFlags={(comment.users as any).bot_flags || 0}
                  isBot={comment.users.is_bot}
                  level={comment.users.level}
                />
              </>
            )}
            {isDeleted && (
              <Text size="sm" c="dimmed" fs="italic">
                [deleted]
              </Text>
            )}
            <Text size="xs" c="dimmed">
              {formatDistanceToNow(new Date(comment.created_at), { addSuffix: true })}
            </Text>
            {comment.edited_at && (
              <Text size="xs" c="dimmed" fs="italic">
                (edited)
              </Text>
            )}
          </Group>

          <Group gap={4}>
            {hasReplies && (
              <ActionIcon
                variant="subtle"
                size="sm"
                onClick={() => setIsCollapsed(!isCollapsed)}
                aria-label={isCollapsed ? 'Expand replies' : 'Collapse replies'}
              >
                {isCollapsed ? <IconChevronDown size={14} /> : <IconChevronUp size={14} />}
              </ActionIcon>
            )}

            {!isDeleted && (
              <Menu position="bottom-end">
                <Menu.Target>
                  <ActionIcon variant="subtle" size="sm">
                    <IconDots size={14} />
                  </ActionIcon>
                </Menu.Target>
                <Menu.Dropdown>
                  {isOwner && (
                    <>
                      <Menu.Item
                        leftSection={<IconEdit size={14} />}
                        onClick={() => setIsEditing(true)}
                      >
                        Edit
                      </Menu.Item>
                      <Menu.Item
                        leftSection={<IconTrash size={14} />}
                        color="red"
                        onClick={handleDelete}
                      >
                        Delete
                      </Menu.Item>
                    </>
                  )}
                  {!isOwner && (
                    <Menu.Item leftSection={<IconFlag size={14} />} color="red">
                      Report
                    </Menu.Item>
                  )}
                </Menu.Dropdown>
              </Menu>
            )}
          </Group>
        </Group>

        {/* Comment content */}
        {!isEditing ? (
          <Text size="sm" mb="sm" style={{ whiteSpace: 'pre-wrap' }}>
            {comment.content}
          </Text>
        ) : (
          <CommentForm
            initialContent={comment.content}
            onSubmit={handleEdit}
            onCancel={() => setIsEditing(false)}
            submitLabel="Save"
            placeholder="Edit your comment..."
          />
        )}

        {/* Actions */}
        {!isDeleted && !isEditing && (
          <Group gap="xs">
            <Group gap={4}>
              <ActionIcon
                variant={userVote === 'upvote' ? 'filled' : 'subtle'}
                color={userVote === 'upvote' ? 'orange' : 'gray'}
                size="sm"
                onClick={() => upvote()}
                aria-label="Upvote"
              >
                <IconArrowUp size={14} />
              </ActionIcon>
              <Text size="sm" fw={600} c={stats.score > 0 ? 'orange' : stats.score < 0 ? 'blue' : undefined}>
                {stats.score}
              </Text>
              <ActionIcon
                variant={userVote === 'downvote' ? 'filled' : 'subtle'}
                color={userVote === 'downvote' ? 'blue' : 'gray'}
                size="sm"
                onClick={() => downvote()}
                aria-label="Downvote"
              >
                <IconArrowDown size={14} />
              </ActionIcon>
            </Group>

            {depth < maxDepth && (
              <Button
                variant="subtle"
                size="xs"
                leftSection={<IconCornerDownRight size={14} />}
                onClick={() => setShowReplyForm(!showReplyForm)}
              >
                Reply
              </Button>
            )}

            {hasReplies && (
              <Text size="xs" c="dimmed">
                {comment.replyCount} {comment.replyCount === 1 ? 'reply' : 'replies'}
              </Text>
            )}
          </Group>
        )}

        {/* Reply form */}
        {showReplyForm && (
          <div className="mt-3">
            <CommentForm
              onSubmit={handleReply}
              onCancel={() => setShowReplyForm(false)}
              placeholder="Write a reply..."
              submitLabel="Reply"
            />
          </div>
        )}
      </Paper>

      {/* Nested replies */}
      <Collapse in={!isCollapsed}>
        {hasReplies && (
          <Stack gap={0}>
            {comment.replies!.map(reply => (
              <CommentItem
                key={reply.id}
                comment={reply}
                depth={depth + 1}
                onReply={onReply}
                onEdit={onEdit}
                onDelete={onDelete}
                onLoadMore={onLoadMore}
                maxDepth={maxDepth}
              />
            ))}
          </Stack>
        )}

        {/* Load more replies button for deep threads */}
        {depth >= maxDepth && comment.replyCount > (comment.replies?.length || 0) && (
          <Button
            variant="subtle"
            size="xs"
            onClick={() => onLoadMore?.(comment.id)}
            style={{ marginLeft: `${indentSize}px` }}
          >
            Continue this thread ({comment.replyCount - (comment.replies?.length || 0)} more replies)
          </Button>
        )}
      </Collapse>
    </div>
  )
}