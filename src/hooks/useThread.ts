'use client'

import { useState, useEffect } from 'react'
import { Thread, ThreadHelpers } from '@/lib/database/helpers/threads'
import { FriksiRealtime, ThreadUpdate } from '@/lib/database/lib/realtime'

interface UseThreadProps {
  threadId: string
  initialThread?: Thread
}

export function useThread({ threadId, initialThread }: UseThreadProps) {
  const [thread, setThread] = useState<Thread | null>(initialThread || null)
  const [loading, setLoading] = useState(!initialThread)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    // Load thread if not provided
    if (!initialThread) {
      const loadThread = async () => {
        const { thread: fetchedThread, error: fetchError } =
          await ThreadHelpers.getThread(threadId)

        if (fetchError) {
          setError(fetchError)
        } else {
          setThread(fetchedThread)
        }
        setLoading(false)
      }

      loadThread()
    }

    // Subscribe to real-time updates
    const channel = FriksiRealtime.subscribeToThread(threadId, {
      onThreadUpdate: (payload: ThreadUpdate) => {
        if (payload.eventType === 'UPDATE' && payload.new) {
          setThread(payload.new as Thread)
        }
      },
    })

    return () => {
      FriksiRealtime.unsubscribe(`thread:${threadId}`)
    }
  }, [threadId, initialThread])

  const updateThread = async (updates: Partial<Thread>) => {
    if (!thread) return { success: false, error: 'Thread not loaded' }

    const { thread: updatedThread, error: updateError } =
      await ThreadHelpers.updateThread(threadId, updates)

    if (updateError) {
      return { success: false, error: updateError }
    }

    if (updatedThread) {
      setThread(updatedThread)
    }

    return { success: true, thread: updatedThread }
  }

  const deleteThread = async () => {
    const { success, error: deleteError } = await ThreadHelpers.deleteThread(
      threadId
    )

    if (deleteError) {
      return { success: false, error: deleteError }
    }

    return { success }
  }

  return {
    thread,
    loading,
    error,
    updateThread,
    deleteThread,
    reload: async () => {
      setLoading(true)
      const { thread: reloadedThread, error: reloadError } =
        await ThreadHelpers.getThread(threadId)
      if (reloadError) {
        setError(reloadError)
      } else {
        setThread(reloadedThread)
      }
      setLoading(false)
    },
  }
}