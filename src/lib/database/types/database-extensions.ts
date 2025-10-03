/**
 * Type extensions for database functions that are not yet in generated types
 * These are temporary until the database types are regenerated with the latest schema
 */

import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from './database.types'

/**
 * Extended database type with additional RPC functions
 */
export interface DatabaseWithExtensions extends Database {
  public: Database['public'] & {
    Functions: Database['public']['Functions'] & {
      increment_category_subscribers: {
        Args: {
          category_id: string
          increment: number
        }
        Returns: void
      }
    }
  }
}

/**
 * Type-safe wrapper for RPC functions that are missing from generated types
 */
export function extendedRpc<T extends SupabaseClient>(client: T) {
  return {
    increment_category_subscribers: async (args: { category_id: string; increment: number }) => {
      // Use the untyped rpc method but provide type safety at the wrapper level
      return await (client.rpc as any)('increment_category_subscribers', args)
    }
  }
}