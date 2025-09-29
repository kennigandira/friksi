import { getBrowserSupabaseClient } from '../lib/browser'
import { createServerSupabaseClient } from '../lib/server'
import type { Tables } from '../types/database.types'

export type Category = Tables<'categories'>

/**
 * Category management utilities
 */
export class CategoryHelpers {
  /**
   * Get all categories
   */
  static async getCategories(
    options: {
      includeInactive?: boolean
      useServerClient?: boolean
    } = {}
  ): Promise<{ categories: Category[]; error: string | null }> {
    try {
      const supabase = options.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      let query = supabase
        .from('categories')
        .select('*')
        .order('post_count', { ascending: false })

      if (!options.includeInactive) {
        query = query.eq('is_active', true)
      }

      const { data: categories, error } = await query

      if (error) {
        return { categories: [], error: error.message }
      }

      return { categories: categories || [], error: null }
    } catch (error) {
      return {
        categories: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Get main categories (no parent)
   */
  static async getMainCategories(
    options: {
      useServerClient?: boolean
    } = {}
  ): Promise<{ categories: Category[]; error: string | null }> {
    try {
      const supabase = options.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      const { data: categories, error } = await supabase
        .from('categories')
        .select('*')
        .is('parent_id', null)
        .eq('is_active', true)
        .order('post_count', { ascending: false })

      if (error) {
        return { categories: [], error: error.message }
      }

      return { categories: categories || [], error: null }
    } catch (error) {
      return {
        categories: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }
}