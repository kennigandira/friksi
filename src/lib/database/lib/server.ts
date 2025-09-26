import { createClient } from '@supabase/supabase-js'
import type { Database } from '../types/database.types'

/**
 * Server-side Supabase client with service role key
 * Use for administrative operations and bypassing RLS
 * WARNING: This client bypasses Row Level Security - use carefully!
 */
export const createServerSupabaseClient = (options?: {
  supabaseUrl?: string
  supabaseServiceKey?: string
}) => {
  const supabaseUrl =
    options?.supabaseUrl || process.env.NEXT_PUBLIC_SUPABASE_URL
  const supabaseServiceKey =
    options?.supabaseServiceKey || process.env.SUPABASE_SERVICE_ROLE_KEY

  if (!supabaseUrl || !supabaseServiceKey) {
    throw new Error(
      'Missing required Supabase environment variables: NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY'
    )
  }

  return createClient<Database>(supabaseUrl, supabaseServiceKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
    global: {
      headers: {
        'X-Client-Info': 'friksi-server',
      },
    },
  })
}

/**
 * Server-side client for authenticated operations
 * Uses the anon key but can be configured with user JWT
 */
export const createServerClientWithAuth = (
  accessToken?: string,
  options?: {
    supabaseUrl?: string
    supabaseAnonKey?: string
  }
) => {
  const supabaseUrl =
    options?.supabaseUrl || process.env.NEXT_PUBLIC_SUPABASE_URL
  const supabaseAnonKey =
    options?.supabaseAnonKey || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

  if (!supabaseUrl || !supabaseAnonKey) {
    throw new Error(
      'Missing required Supabase environment variables: NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY'
    )
  }

  const client = createClient<Database>(supabaseUrl, supabaseAnonKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
    global: {
      headers: {
        'X-Client-Info': 'friksi-server-auth',
        ...(accessToken && { Authorization: `Bearer ${accessToken}` }),
      },
    },
  })

  return client
}

export type ServerSupabaseClient = ReturnType<typeof createServerSupabaseClient>
export type ServerSupabaseClientWithAuth = ReturnType<
  typeof createServerClientWithAuth
>
