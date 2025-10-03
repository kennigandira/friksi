import { createClient } from '@supabase/supabase-js'
import type { Database } from '../types/database.types'

/**
 * Browser/Client-side Supabase client
 * Uses anon key and respects Row Level Security
 */
export const createBrowserSupabaseClient = (options?: {
  supabaseUrl?: string
  supabaseAnonKey?: string
}) => {
  const supabaseUrl =
    options?.supabaseUrl || process.env['NEXT_PUBLIC_SUPABASE_URL']
  const supabaseAnonKey =
    options?.supabaseAnonKey || process.env['NEXT_PUBLIC_SUPABASE_ANON_KEY']

  if (!supabaseUrl || !supabaseAnonKey) {
    throw new Error(
      'Missing required Supabase environment variables: NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY'
    )
  }

  return createClient<Database>(supabaseUrl, supabaseAnonKey, {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: true,
      flowType: 'pkce', // More secure flow for web apps
    },
    realtime: {
      params: {
        eventsPerSecond: 10, // Rate limit for real-time updates
      },
    },
    global: {
      headers: {
        'X-Client-Info': 'friksi-browser',
      },
    },
  })
}

/**
 * Create a singleton instance for browser usage
 * This ensures we only create one client instance
 */
let browserClient: ReturnType<typeof createBrowserSupabaseClient> | null = null

export const getBrowserSupabaseClient = () => {
  if (typeof window === 'undefined') {
    throw new Error(
      'getBrowserSupabaseClient can only be used in browser environment'
    )
  }

  if (!browserClient) {
    browserClient = createBrowserSupabaseClient()
  }

  return browserClient
}

export type BrowserSupabaseClient = ReturnType<
  typeof createBrowserSupabaseClient
>
