'use client'

import { useState, useEffect, useCallback } from 'react'
import { ThreadHelpers, Thread } from '@/lib/database/helpers/threads'

interface UseHotThreadsOptions {
  limit?: number
  offset?: number
  autoRefresh?: boolean
  refreshInterval?: number
}

export function useHotThreads(options: UseHotThreadsOptions = {}) {
  const {
    limit = 20,
    offset = 0,
    autoRefresh = false,
    refreshInterval = 60000, // 1 minute
  } = options

  const [threads, setThreads] = useState<Thread[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [hasMore, setHasMore] = useState(true)

  const fetchThreads = useCallback(
    async (isLoadMore = false) => {
      try {
        if (!isLoadMore) {
          setLoading(true)
        }

        const currentOffset = isLoadMore ? threads.length : offset
        const { threads: fetchedThreads, error: fetchError } =
          await ThreadHelpers.getHotThreads({
            limit,
            offset: currentOffset,
          })

        if (fetchError) {
          setError(fetchError)
          return
        }

        if (isLoadMore) {
          setThreads((prev) => [...prev, ...fetchedThreads])
        } else {
          setThreads(fetchedThreads)
        }

        setHasMore(fetchedThreads.length === limit)
        setError(null)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to fetch threads')
      } finally {
        setLoading(false)
      }
    },
    [limit, offset, threads.length]
  )

  const loadMore = useCallback(() => {
    if (!loading && hasMore) {
      fetchThreads(true)
    }
  }, [loading, hasMore, fetchThreads])

  const handleVote = useCallback(
    async (threadId: string, voteType: 'upvote' | 'downvote') => {
      // For now, just optimistically update the UI
      // In production, this would call the actual vote API
      setThreads((prevThreads) =>
        prevThreads.map((thread) => {
          if (thread.id === threadId) {
            return {
              ...thread,
              upvotes:
                voteType === 'upvote' ? thread.upvotes + 1 : thread.upvotes,
              downvotes:
                voteType === 'downvote'
                  ? thread.downvotes + 1
                  : thread.downvotes,
            }
          }
          return thread
        })
      )
    },
    []
  )

  useEffect(() => {
    fetchThreads()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    if (autoRefresh) {
      const interval = setInterval(() => {
        fetchThreads()
      }, refreshInterval)

      return () => clearInterval(interval)
    }
  }, [autoRefresh, refreshInterval, fetchThreads])

  return {
    threads,
    loading,
    error,
    hasMore,
    loadMore,
    refresh: () => fetchThreads(),
    handleVote,
  }
}