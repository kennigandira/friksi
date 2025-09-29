'use client'

import { useState, useEffect, useCallback } from 'react'
import {
  CommentHelpers,
  NestedComment,
  CommentInsert,
} from '@/lib/database/helpers/comments'
import { FriksiRealtime, CommentUpdate } from '@/lib/database/lib/realtime'
import { useAuth } from './useAuth'

type SortOption = 'best' | 'new' | 'controversial'

interface UseCommentsProps {
  threadId: string
  maxDepth?: number
  limit?: number
}

export function useComments({
  threadId,
  maxDepth = 10,
  limit = 100,
}: UseCommentsProps) {
  const { user } = useAuth()
  const [comments, setComments] = useState<NestedComment[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [sortBy, setSortBy] = useState<SortOption>('best')
  const [loadingMore, setLoadingMore] = useState(false)
  const [hasMore, setHasMore] = useState(false)

  // Load comments
  const loadComments = useCallback(
    async (append = false) => {
      if (!append) setLoading(true)
      else setLoadingMore(true)

      const { comments: fetchedComments, error: fetchError } =
        await CommentHelpers.getThreadComments(threadId, {
          sortBy,
          maxDepth,
          limit,
        })

      if (fetchError) {
        setError(fetchError)
      } else {
        if (append) {
          setComments(prev => [...prev, ...fetchedComments])
        } else {
          setComments(fetchedComments)
        }
        setHasMore(fetchedComments.length === limit)
      }

      setLoading(false)
      setLoadingMore(false)
    },
    [threadId, sortBy, maxDepth, limit]
  )

  // Initial load and reload on sort change
  useEffect(() => {
    loadComments()
  }, [loadComments])

  // Subscribe to real-time updates
  useEffect(() => {
    const channel = FriksiRealtime.subscribeToThread(threadId, {
      onCommentInsert: (payload: CommentUpdate) => {
        if (payload.eventType === 'INSERT' && payload.new) {
          // Add new comment to the list
          const newComment = payload.new as NestedComment
          setComments(prev => {
            // If it's a reply, find parent and add to replies
            if (newComment.parent_id) {
              return updateCommentInTree(prev, newComment.parent_id, parent => ({
                ...parent,
                replies: [...(parent.replies || []), newComment],
                replyCount: parent.replyCount + 1,
              }))
            }
            // If it's a top-level comment, add to root
            return [newComment, ...prev]
          })
        }
      },
      onCommentUpdate: (payload: CommentUpdate) => {
        if (payload.eventType === 'UPDATE' && payload.new) {
          const updatedComment = payload.new as NestedComment
          setComments(prev =>
            updateCommentInTree(prev, updatedComment.id, () => updatedComment)
          )
        }
      },
    })

    return () => {
      FriksiRealtime.unsubscribe(`thread:${threadId}`)
    }
  }, [threadId])

  // Add a new comment
  const addComment = async (
    content: string,
    parentId?: string
  ): Promise<{ success: boolean; error?: string }> => {
    if (!user) {
      return { success: false, error: 'You must be logged in to comment' }
    }

    const commentData: Omit<
      CommentInsert,
      'id' | 'created_at' | 'updated_at' | 'path' | 'depth'
    > = {
      thread_id: threadId,
      user_id: user.id,
      parent_id: parentId || null,
      content,
      upvotes: 0,
      downvotes: 0,
      wilson_score: 0,
      is_removed: false,
      is_deleted: false,
    }

    const { comment, error: createError } = await CommentHelpers.createComment(
      commentData
    )

    if (createError) {
      return { success: false, error: createError }
    }

    return { success: true }
  }

  // Update a comment
  const updateComment = async (
    commentId: string,
    content: string
  ): Promise<{ success: boolean; error?: string }> => {
    const { comment, error: updateError } = await CommentHelpers.updateComment(
      commentId,
      { content }
    )

    if (updateError) {
      return { success: false, error: updateError }
    }

    return { success: true }
  }

  // Delete a comment
  const deleteComment = async (
    commentId: string
  ): Promise<{ success: boolean; error?: string }> => {
    const { success, error: deleteError } = await CommentHelpers.deleteComment(
      commentId
    )

    if (deleteError) {
      return { success: false, error: deleteError }
    }

    return { success }
  }

  // Load replies for a specific comment
  const loadReplies = async (commentId: string) => {
    const { comment, error: repliesError } =
      await CommentHelpers.getCommentWithReplies(commentId, { maxDepth: 5 })

    if (repliesError) {
      return { success: false, error: repliesError }
    }

    if (comment) {
      setComments(prev =>
        updateCommentInTree(prev, commentId, () => comment)
      )
    }

    return { success: true }
  }

  return {
    comments,
    loading,
    error,
    sortBy,
    setSortBy,
    loadingMore,
    hasMore,
    loadMore: () => loadComments(true),
    reload: () => loadComments(),
    addComment,
    updateComment,
    deleteComment,
    loadReplies,
  }
}

// Helper function to update a comment in the tree
function updateCommentInTree(
  comments: NestedComment[],
  commentId: string,
  updater: (comment: NestedComment) => NestedComment
): NestedComment[] {
  return comments.map(comment => {
    if (comment.id === commentId) {
      return updater(comment)
    }
    if (comment.replies && comment.replies.length > 0) {
      return {
        ...comment,
        replies: updateCommentInTree(comment.replies, commentId, updater),
      }
    }
    return comment
  })
}