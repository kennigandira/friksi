import { createClient } from '@supabase/supabase-js'
import type { Database } from '../types/database.types'

/**
 * Generic Supabase client factory
 * For most use cases, prefer the specific client factories:
 * - getBrowserSupabaseClient() for client-side
 * - createServerSupabaseClient() for server-side with service role
 * - createServerClientWithAuth() for server-side with user auth
 */
export const createSupabaseClient = (
  supabaseUrl: string,
  supabaseKey: string,
  options?: {
    auth?: {
      autoRefreshToken?: boolean
      persistSession?: boolean
      detectSessionInUrl?: boolean
    }
    global?: {
      headers?: Record<string, string>
    }
  }
) => {
  return createClient<Database>(supabaseUrl, supabaseKey, {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: true,
      ...options?.auth,
    },
    global: {
      headers: {
        'X-Client-Info': 'friksi-generic',
        ...options?.global?.headers,
      },
    },
  })
}

export type SupabaseClient = ReturnType<typeof createSupabaseClient>

// Re-export all the specific client types and factories
export * from './browser'
export * from './server'
export * from './auth'
export * from './realtime'
