import { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '../types/database.types'

/**
 * Type-safe Supabase client
 * Note: We use a looser type to avoid `never` inference issues with table operations
 */
export type TypedSupabaseClient = SupabaseClient<Database>

/**
 * Type-safe table helpers
 */
export type Tables = Database['public']['Tables']
export type TableName = keyof Tables
export type TableRow<T extends TableName> = Tables[T]['Row']
export type TableInsert<T extends TableName> = Tables[T]['Insert']
export type TableUpdate<T extends TableName> = Tables[T]['Update']

/**
 * Type-safe query builder
 * Converts an untyped Supabase client to a typed one
 * Note: This is a type assertion that doesn't change runtime behavior
 */
export function getTypedClient(client: SupabaseClient | SupabaseClient<Database>): SupabaseClient<Database> {
  return client as SupabaseClient<Database>
}

/**
 * Type-safe table access
 */
export function typedFrom<T extends TableName>(
  client: TypedSupabaseClient,
  table: T
) {
  return client.from(table)
}