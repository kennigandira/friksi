import { getBrowserSupabaseClient } from '../lib/browser'
import { createServerSupabaseClient } from '../lib/server'
import type { Tables, TablesInsert, TablesUpdate } from '../types/database.types'
import { extendedRpc } from '../types/database-extensions'

export type Category = Tables<'categories'>
export type CategoryInsert = TablesInsert<'categories'>
export type CategoryUpdate = TablesUpdate<'categories'>
export type CategorySubscription = Tables<'category_subscriptions'>

// Extended category type with subscription status
export interface CategoryWithSubscription extends Category {
  is_subscribed?: boolean
  subscription?: CategorySubscription | null
}

/**
 * Category management utilities
 */
export class CategoryHelpers {
  /**
   * Get all active categories with counts and optional subscription status
   */
  static async getCategories(
    options?: {
      useServerClient?: boolean
      userId?: string
      parentId?: string | null
      includeInactive?: boolean
    }
  ): Promise<{ categories: CategoryWithSubscription[]; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      // Build the base query
      let query = supabase
        .from('categories')
        .select(`
          *,
          category_subscriptions!left(
            user_id,
            notification_enabled,
            subscribed_at
          )
        `)

      // Apply filters
      if (!options?.includeInactive) {
        query = query.eq('is_active', true)
      }

      // Filter by parent_id if specified
      if (options?.parentId !== undefined) {
        query = options?.parentId === null
          ? query.is('parent_id', null)
          : query.eq('parent_id', options.parentId)
      }

      // Order by subscriber count and post count for relevance
      query = query.order('subscriber_count', { ascending: false })
        .order('post_count', { ascending: false })

      const { data: categories, error } = await query

      if (error) {
        return { categories: [], error: error.message }
      }

      // Process categories to add subscription status
      const processedCategories: CategoryWithSubscription[] = categories?.map(cat => {
        const subscriptions = cat.category_subscriptions as any[]
        const userSubscription = options?.userId
          ? subscriptions?.find((sub: any) => sub.user_id === options.userId)
          : null

        return {
          ...cat,
          is_subscribed: !!userSubscription,
          subscription: userSubscription || null,
          category_subscriptions: undefined // Remove raw subscription data
        } as CategoryWithSubscription
      }) || []

      return { categories: processedCategories, error: null }
    } catch (error) {
      return {
        categories: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Get categories for authenticated user with subscription status
   */
  static async getCategoriesWithAuth(
    userId: string,
    options?: {
      useServerClient?: boolean
    }
  ): Promise<{ categories: CategoryWithSubscription[]; error: string | null }> {
    return this.getCategories({ ...options, userId })
  }

  /**
   * Get a single category by slug
   */
  static async getCategoryBySlug(
    slug: string,
    options?: {
      useServerClient?: boolean
      userId?: string
    }
  ): Promise<{ category: CategoryWithSubscription | null; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      const query = supabase
        .from('categories')
        .select(`
          *,
          category_subscriptions!left(
            user_id,
            notification_enabled,
            subscribed_at
          )
        `)
        .eq('slug', slug)
        .single()

      const { data: category, error } = await query

      if (error) {
        if (error.code === 'PGRST116') {
          return { category: null, error: 'Category not found' }
        }
        return { category: null, error: error.message }
      }

      // Process category to add subscription status
      const subscriptions = (category as any).category_subscriptions as any[]
      const userSubscription = options?.userId
        ? subscriptions?.find((sub: any) => sub.user_id === options.userId)
        : null

      const processedCategory: CategoryWithSubscription = {
        ...category,
        is_subscribed: !!userSubscription,
        subscription: userSubscription || null,
        category_subscriptions: undefined
      } as CategoryWithSubscription

      return { category: processedCategory, error: null }
    } catch (error) {
      return {
        category: null,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Subscribe to a category
   */
  static async subscribeToCategory(
    categoryId: string,
    userId: string,
    options?: {
      notificationEnabled?: boolean
      useServerClient?: boolean
      headers?: HeadersInit
    }
  ): Promise<{ subscription: CategorySubscription | null; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      const { data: subscription, error } = await supabase
        .from('category_subscriptions')
        .insert({
          category_id: categoryId,
          user_id: userId,
          notification_enabled: options?.notificationEnabled ?? true,
        })
        .select()
        .single()

      if (error) {
        // Handle duplicate subscription
        if (error.code === '23505') {
          return { subscription: null, error: 'Already subscribed to this category' }
        }
        return { subscription: null, error: error.message }
      }

      // Update subscriber count
      await extendedRpc(supabase).increment_category_subscribers({
        category_id: categoryId,
        increment: 1
      })

      return { subscription, error: null }
    } catch (error) {
      return {
        subscription: null,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Unsubscribe from a category
   */
  static async unsubscribeFromCategory(
    categoryId: string,
    userId: string,
    options?: {
      useServerClient?: boolean
      headers?: HeadersInit
    }
  ): Promise<{ success: boolean; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      const { error } = await supabase
        .from('category_subscriptions')
        .delete()
        .eq('category_id', categoryId)
        .eq('user_id', userId)

      if (error) {
        return { success: false, error: error.message }
      }

      // Update subscriber count
      await extendedRpc(supabase).increment_category_subscribers({
        category_id: categoryId,
        increment: -1
      })

      return { success: true, error: null }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Toggle subscription status
   */
  static async toggleSubscription(
    categoryId: string,
    userId: string,
    currentlySubscribed: boolean,
    options?: {
      useServerClient?: boolean
      headers?: HeadersInit
    }
  ): Promise<{ success: boolean; newStatus: boolean; error: string | null }> {
    if (currentlySubscribed) {
      const { success, error } = await this.unsubscribeFromCategory(
        categoryId,
        userId,
        options
      )
      return { success, newStatus: !success, error }
    } else {
      const { subscription, error } = await this.subscribeToCategory(
        categoryId,
        userId,
        options
      )
      return { success: !!subscription, newStatus: !!subscription, error }
    }
  }

  /**
   * Get user's subscribed categories
   */
  static async getUserSubscriptions(
    userId: string,
    options?: {
      useServerClient?: boolean
    }
  ): Promise<{ categories: Category[]; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      const { data, error } = await supabase
        .from('category_subscriptions')
        .select(`
          categories (*)
        `)
        .eq('user_id', userId)

      if (error) {
        return { categories: [], error: error.message }
      }

      const categories = data?.map(item => (item as any).categories).filter(Boolean) || []
      return { categories, error: null }
    } catch (error) {
      return {
        categories: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Update category notification preferences
   */
  static async updateNotificationPreference(
    categoryId: string,
    userId: string,
    enabled: boolean,
    options?: {
      useServerClient?: boolean
    }
  ): Promise<{ success: boolean; error: string | null }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      const { error } = await supabase
        .from('category_subscriptions')
        .update({ notification_enabled: enabled })
        .eq('category_id', categoryId)
        .eq('user_id', userId)

      if (error) {
        return { success: false, error: error.message }
      }

      return { success: true, error: null }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }

  /**
   * Get category hierarchy (parent and children)
   */
  static async getCategoryHierarchy(
    categoryId: string,
    options?: {
      useServerClient?: boolean
    }
  ): Promise<{
    category: Category | null
    parent: Category | null
    children: Category[]
    error: string | null
  }> {
    try {
      const supabase = options?.useServerClient
        ? createServerSupabaseClient()
        : getBrowserSupabaseClient()

      // Get the category itself
      const { data: category, error: categoryError } = await supabase
        .from('categories')
        .select('*')
        .eq('id', categoryId)
        .single()

      if (categoryError) {
        return { category: null, parent: null, children: [], error: categoryError.message }
      }

      // Get parent if exists
      let parent: Category | null = null
      if (category.parent_id) {
        const { data: parentData } = await supabase
          .from('categories')
          .select('*')
          .eq('id', category.parent_id)
          .single()

        parent = parentData
      }

      // Get children
      const { data: children } = await supabase
        .from('categories')
        .select('*')
        .eq('parent_id', categoryId)
        .eq('is_active', true)
        .order('name')

      return {
        category,
        parent,
        children: children || [],
        error: null
      }
    } catch (error) {
      return {
        category: null,
        parent: null,
        children: [],
        error: error instanceof Error ? error.message : 'Unknown error',
      }
    }
  }
}