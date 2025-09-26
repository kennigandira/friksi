import type {
  RealtimeChannel,
  RealtimePostgresChangesPayload,
} from '@supabase/supabase-js'
import type { Database, Tables } from '../types/database.types'
import { getBrowserSupabaseClient } from './browser'

export type ThreadUpdate = RealtimePostgresChangesPayload<Tables<'threads'>>
export type CommentUpdate = RealtimePostgresChangesPayload<Tables<'comments'>>
export type VoteUpdate = RealtimePostgresChangesPayload<Tables<'votes'>>

/**
 * Real-time subscription utilities for Friksi platform
 */
export class FriksiRealtime {
  private static channels: Map<string, RealtimeChannel> = new Map()

  /**
   * Subscribe to thread updates
   */
  static subscribeToThread(
    threadId: string,
    callbacks: {
      onThreadUpdate?: (payload: ThreadUpdate) => void
      onCommentInsert?: (payload: CommentUpdate) => void
      onCommentUpdate?: (payload: CommentUpdate) => void
      onVoteInsert?: (payload: VoteUpdate) => void
      onVoteUpdate?: (payload: VoteUpdate) => void
    }
  ): RealtimeChannel {
    const supabase = getBrowserSupabaseClient()
    const channelName = `thread:${threadId}`

    // Remove existing channel if it exists
    this.unsubscribe(channelName)

    const channel = supabase
      .channel(channelName)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'threads',
          filter: `id=eq.${threadId}`,
        },
        payload => callbacks.onThreadUpdate?.(payload as ThreadUpdate)
      )
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'comments',
          filter: `thread_id=eq.${threadId}`,
        },
        payload => callbacks.onCommentInsert?.(payload as CommentUpdate)
      )
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'comments',
          filter: `thread_id=eq.${threadId}`,
        },
        payload => callbacks.onCommentUpdate?.(payload as CommentUpdate)
      )
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'votes',
          filter: `content_type=eq.thread.and.content_id=eq.${threadId}`,
        },
        payload => callbacks.onVoteInsert?.(payload as VoteUpdate)
      )
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'votes',
          filter: `content_type=eq.thread.and.content_id=eq.${threadId}`,
        },
        payload => callbacks.onVoteUpdate?.(payload as VoteUpdate)
      )
      .subscribe()

    this.channels.set(channelName, channel)
    return channel
  }

  /**
   * Subscribe to category updates
   */
  static subscribeToCategory(
    categoryId: string,
    callbacks: {
      onThreadInsert?: (payload: ThreadUpdate) => void
      onThreadUpdate?: (payload: ThreadUpdate) => void
    }
  ): RealtimeChannel {
    const supabase = getBrowserSupabaseClient()
    const channelName = `category:${categoryId}`

    // Remove existing channel if it exists
    this.unsubscribe(channelName)

    const channel = supabase
      .channel(channelName)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'threads',
          filter: `category_id=eq.${categoryId}`,
        },
        payload => callbacks.onThreadInsert?.(payload as ThreadUpdate)
      )
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'threads',
          filter: `category_id=eq.${categoryId}`,
        },
        payload => callbacks.onThreadUpdate?.(payload as ThreadUpdate)
      )
      .subscribe()

    this.channels.set(channelName, channel)
    return channel
  }

  /**
   * Subscribe to voting session updates
   */
  static subscribeToVotingSession(
    sessionId: string,
    callbacks: {
      onSessionUpdate?: (
        payload: RealtimePostgresChangesPayload<Tables<'voting_sessions'>>
      ) => void
      onVoteInsert?: (
        payload: RealtimePostgresChangesPayload<Tables<'user_votes'>>
      ) => void
      onOptionUpdate?: (
        payload: RealtimePostgresChangesPayload<Tables<'voting_options'>>
      ) => void
    }
  ): RealtimeChannel {
    const supabase = getBrowserSupabaseClient()
    const channelName = `voting:${sessionId}`

    // Remove existing channel if it exists
    this.unsubscribe(channelName)

    const channel = supabase
      .channel(channelName)
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'voting_sessions',
          filter: `id=eq.${sessionId}`,
        },
        payload => callbacks.onSessionUpdate?.(payload as any)
      )
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'user_votes',
          filter: `session_id=eq.${sessionId}`,
        },
        payload => callbacks.onVoteInsert?.(payload as any)
      )
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'voting_options',
          filter: `session_id=eq.${sessionId}`,
        },
        payload => callbacks.onOptionUpdate?.(payload as any)
      )
      .subscribe()

    this.channels.set(channelName, channel)
    return channel
  }

  /**
   * Subscribe to user notifications
   */
  static subscribeToUserNotifications(
    userId: string,
    callback: (payload: RealtimePostgresChangesPayload<any>) => void
  ): RealtimeChannel {
    const supabase = getBrowserSupabaseClient()
    const channelName = `user:${userId}:notifications`

    // Remove existing channel if it exists
    this.unsubscribe(channelName)

    const channel = supabase
      .channel(channelName)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'user_activities',
          filter: `user_id=eq.${userId}`,
        },
        callback
      )
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'user_badges',
          filter: `user_id=eq.${userId}`,
        },
        callback
      )
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'users',
          filter: `id=eq.${userId}`,
        },
        callback
      )
      .subscribe()

    this.channels.set(channelName, channel)
    return channel
  }

  /**
   * Subscribe to moderator updates for a category
   */
  static subscribeToModerationActivity(
    categoryId: string,
    callback: (payload: RealtimePostgresChangesPayload<any>) => void
  ): RealtimeChannel {
    const supabase = getBrowserSupabaseClient()
    const channelName = `moderation:${categoryId}`

    // Remove existing channel if it exists
    this.unsubscribe(channelName)

    const channel = supabase
      .channel(channelName)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'reports',
        },
        callback
      )
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'bot_flags',
        },
        callback
      )
      .subscribe()

    this.channels.set(channelName, channel)
    return channel
  }

  /**
   * Unsubscribe from a channel
   */
  static unsubscribe(channelName: string): void {
    const channel = this.channels.get(channelName)
    if (channel) {
      const supabase = getBrowserSupabaseClient()
      supabase.removeChannel(channel)
      this.channels.delete(channelName)
    }
  }

  /**
   * Unsubscribe from all channels
   */
  static unsubscribeAll(): void {
    const supabase = getBrowserSupabaseClient()

    for (const [channelName, channel] of this.channels) {
      supabase.removeChannel(channel)
    }

    this.channels.clear()
  }

  /**
   * Get connection status
   */
  static getConnectionStatus(): string {
    const supabase = getBrowserSupabaseClient()
    return supabase.realtime.connection.state
  }

  /**
   * Get active channels
   */
  static getActiveChannels(): string[] {
    return Array.from(this.channels.keys())
  }
}

// Cleanup on page unload
if (typeof window !== 'undefined') {
  window.addEventListener('beforeunload', () => {
    FriksiRealtime.unsubscribeAll()
  })
}
