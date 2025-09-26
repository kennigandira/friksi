export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string
          username: string
          email: string
          password_hash: string | null
          avatar_url: string | null
          bio: string | null
          level: number
          xp: number
          trust_score: number
          post_count: number
          comment_count: number
          helpful_votes: number
          account_status: 'active' | 'restricted' | 'shadowbanned' | 'banned'
          is_bot: boolean
          bot_flags: number
          last_active: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          username: string
          email: string
          password_hash?: string | null
          avatar_url?: string | null
          bio?: string | null
          level?: number
          xp?: number
          trust_score?: number
          post_count?: number
          comment_count?: number
          helpful_votes?: number
          account_status?: 'active' | 'restricted' | 'shadowbanned' | 'banned'
          is_bot?: boolean
          bot_flags?: number
          last_active?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          username?: string
          email?: string
          password_hash?: string | null
          avatar_url?: string | null
          bio?: string | null
          level?: number
          xp?: number
          trust_score?: number
          post_count?: number
          comment_count?: number
          helpful_votes?: number
          account_status?: 'active' | 'restricted' | 'shadowbanned' | 'banned'
          is_bot?: boolean
          bot_flags?: number
          last_active?: string
          created_at?: string
          updated_at?: string
        }
      }
      trust_factors: {
        Row: {
          user_id: string
          account_age_days: number
          verified_email: boolean
          verified_phone: boolean
          positive_interactions: number
          negative_interactions: number
          moderator_warnings: number
          successful_reports: number
          false_reports: number
          updated_at: string
        }
        Insert: {
          user_id: string
          verified_email?: boolean
          verified_phone?: boolean
          positive_interactions?: number
          negative_interactions?: number
          moderator_warnings?: number
          successful_reports?: number
          false_reports?: number
          updated_at?: string
        }
        Update: {
          user_id?: string
          verified_email?: boolean
          verified_phone?: boolean
          positive_interactions?: number
          negative_interactions?: number
          moderator_warnings?: number
          successful_reports?: number
          false_reports?: number
          updated_at?: string
        }
      }
      user_sessions: {
        Row: {
          id: string
          user_id: string
          token: string
          ip_address: string | null
          user_agent: string | null
          expires_at: string
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          token: string
          ip_address?: string | null
          user_agent?: string | null
          expires_at: string
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          token?: string
          ip_address?: string | null
          user_agent?: string | null
          expires_at?: string
          created_at?: string
        }
      }
      categories: {
        Row: {
          id: string
          parent_id: string | null
          name: string
          slug: string
          description: string | null
          icon_url: string | null
          path: string
          level: number
          thread_count: number
          subscriber_count: number
          is_active: boolean
          is_default: boolean
          created_by: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          parent_id?: string | null
          name: string
          slug: string
          description?: string | null
          icon_url?: string | null
          path?: string
          level?: number
          thread_count?: number
          subscriber_count?: number
          is_active?: boolean
          is_default?: boolean
          created_by: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          parent_id?: string | null
          name?: string
          slug?: string
          description?: string | null
          icon_url?: string | null
          path?: string
          level?: number
          thread_count?: number
          subscriber_count?: number
          is_active?: boolean
          is_default?: boolean
          created_by?: string
          created_at?: string
          updated_at?: string
        }
      }
      category_subscriptions: {
        Row: {
          user_id: string
          category_id: string
          notification_enabled: boolean
          subscribed_at: string
        }
        Insert: {
          user_id: string
          category_id: string
          notification_enabled?: boolean
          subscribed_at?: string
        }
        Update: {
          user_id?: string
          category_id?: string
          notification_enabled?: boolean
          subscribed_at?: string
        }
      }
      threads: {
        Row: {
          id: string
          user_id: string
          category_id: string
          title: string
          content: string | null
          content_html: string | null
          upvotes: number
          downvotes: number
          comment_count: number
          view_count: number
          hot_score: number
          wilson_score: number
          is_pinned: boolean
          is_locked: boolean
          is_removed: boolean
          is_deleted: boolean
          is_spam: boolean
          removal_reason: string | null
          edited_at: string | null
          last_activity_at: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          category_id: string
          title: string
          content?: string | null
          content_html?: string | null
          upvotes?: number
          downvotes?: number
          comment_count?: number
          view_count?: number
          hot_score?: number
          wilson_score?: number
          is_pinned?: boolean
          is_locked?: boolean
          is_removed?: boolean
          is_deleted?: boolean
          is_spam?: boolean
          removal_reason?: string | null
          edited_at?: string | null
          last_activity_at?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          category_id?: string
          title?: string
          content?: string | null
          content_html?: string | null
          upvotes?: number
          downvotes?: number
          comment_count?: number
          view_count?: number
          hot_score?: number
          wilson_score?: number
          is_pinned?: boolean
          is_locked?: boolean
          is_removed?: boolean
          is_deleted?: boolean
          is_spam?: boolean
          removal_reason?: string | null
          edited_at?: string | null
          last_activity_at?: string
          created_at?: string
          updated_at?: string
        }
      }
      comments: {
        Row: {
          id: string
          thread_id: string
          user_id: string
          parent_id: string | null
          content: string
          content_html: string | null
          path: string
          depth: number
          upvotes: number
          downvotes: number
          wilson_score: number
          is_removed: boolean
          is_deleted: boolean
          removal_reason: string | null
          edited_at: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          thread_id: string
          user_id: string
          parent_id?: string | null
          content: string
          content_html?: string | null
          path?: string
          depth?: number
          upvotes?: number
          downvotes?: number
          wilson_score?: number
          is_removed?: boolean
          is_deleted?: boolean
          removal_reason?: string | null
          edited_at?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          thread_id?: string
          user_id?: string
          parent_id?: string | null
          content?: string
          content_html?: string | null
          path?: string
          depth?: number
          upvotes?: number
          downvotes?: number
          wilson_score?: number
          is_removed?: boolean
          is_deleted?: boolean
          removal_reason?: string | null
          edited_at?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      votes: {
        Row: {
          id: string
          user_id: string
          content_type: 'thread' | 'comment'
          content_id: string
          vote_type: 'upvote' | 'downvote'
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          content_type: 'thread' | 'comment'
          content_id: string
          vote_type: 'upvote' | 'downvote'
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          content_type?: 'thread' | 'comment'
          content_id?: string
          vote_type?: 'upvote' | 'downvote'
          created_at?: string
        }
      }
      thread_votes: {
        Row: {
          user_id: string
          thread_id: string
          vote_type: 'upvote' | 'downvote'
          voted_at: string
        }
        Insert: {
          user_id: string
          thread_id: string
          vote_type: 'upvote' | 'downvote'
          voted_at?: string
        }
        Update: {
          user_id?: string
          thread_id?: string
          vote_type?: 'upvote' | 'downvote'
          voted_at?: string
        }
      }
      comment_votes: {
        Row: {
          user_id: string
          comment_id: string
          vote_type: 'upvote' | 'downvote'
          voted_at: string
        }
        Insert: {
          user_id: string
          comment_id: string
          vote_type: 'upvote' | 'downvote'
          voted_at?: string
        }
        Update: {
          user_id?: string
          comment_id?: string
          vote_type?: 'upvote' | 'downvote'
          voted_at?: string
        }
      }
      badges: {
        Row: {
          id: string
          name: string
          description: string
          icon_url: string | null
          type: 'activity' | 'special' | 'monthly' | 'achievement'
          tier: 'bronze' | 'silver' | 'gold' | 'platinum'
          requirements: Json
          points_value: number
          xp_reward: number
          awarded_count: number
          is_active: boolean
          is_secret: boolean
          created_at: string
        }
        Insert: {
          id?: string
          name: string
          description: string
          icon_url?: string | null
          type: 'activity' | 'special' | 'monthly' | 'achievement'
          tier: 'bronze' | 'silver' | 'gold' | 'platinum'
          requirements: Json
          points_value?: number
          xp_reward?: number
          awarded_count?: number
          is_active?: boolean
          is_secret?: boolean
          created_at?: string
        }
        Update: {
          id?: string
          name?: string
          description?: string
          icon_url?: string | null
          type?: 'activity' | 'special' | 'monthly' | 'achievement'
          tier?: 'bronze' | 'silver' | 'gold' | 'platinum'
          requirements?: Json
          points_value?: number
          xp_reward?: number
          awarded_count?: number
          is_active?: boolean
          is_secret?: boolean
          created_at?: string
        }
      }
      user_badges: {
        Row: {
          user_id: string
          badge_id: string
          awarded_at: string
          awarded_for: string | null
        }
        Insert: {
          user_id: string
          badge_id: string
          awarded_at?: string
          awarded_for?: string | null
        }
        Update: {
          user_id?: string
          badge_id?: string
          awarded_at?: string
          awarded_for?: string | null
        }
      }
      user_levels: {
        Row: {
          level: number
          name: string
          required_xp: number
          permissions: Json
          created_at: string
        }
        Insert: {
          level: number
          name: string
          required_xp: number
          permissions: Json
          created_at?: string
        }
        Update: {
          level?: number
          name?: string
          required_xp?: number
          permissions?: Json
          created_at?: string
        }
      }
      moderators: {
        Row: {
          id: string
          user_id: string
          category_id: string
          elected_at: string
          votes_received: number
          term_starts_at: string
          term_ends_at: string | null
          is_active: boolean
          removal_reason: string | null
          actions_count: number
          warnings_issued: number
        }
        Insert: {
          id?: string
          user_id: string
          category_id: string
          elected_at?: string
          votes_received: number
          term_starts_at?: string
          term_ends_at?: string | null
          is_active?: boolean
          removal_reason?: string | null
          actions_count?: number
          warnings_issued?: number
        }
        Update: {
          id?: string
          user_id?: string
          category_id?: string
          elected_at?: string
          votes_received?: number
          term_starts_at?: string
          term_ends_at?: string | null
          is_active?: boolean
          removal_reason?: string | null
          actions_count?: number
          warnings_issued?: number
        }
      }
      reports: {
        Row: {
          id: string
          reporter_id: string
          content_type: 'thread' | 'comment' | 'user'
          content_id: string | null
          reported_user_id: string | null
          report_type:
            | 'spam'
            | 'harassment'
            | 'hate_speech'
            | 'misinformation'
            | 'low_effort'
            | 'off_topic'
            | 'other'
            | 'bot_suspected'
          reason: string
          evidence: Json | null
          status: 'pending' | 'reviewing' | 'resolved' | 'dismissed'
          resolved_by: string | null
          resolution_action: string | null
          created_at: string
          resolved_at: string | null
        }
        Insert: {
          id?: string
          reporter_id: string
          content_type: 'thread' | 'comment' | 'user'
          content_id?: string | null
          reported_user_id?: string | null
          report_type:
            | 'spam'
            | 'harassment'
            | 'hate_speech'
            | 'misinformation'
            | 'low_effort'
            | 'off_topic'
            | 'other'
            | 'bot_suspected'
          reason: string
          evidence?: Json | null
          status?: 'pending' | 'reviewing' | 'resolved' | 'dismissed'
          resolved_by?: string | null
          resolution_action?: string | null
          created_at?: string
          resolved_at?: string | null
        }
        Update: {
          id?: string
          reporter_id?: string
          content_type?: 'thread' | 'comment' | 'user'
          content_id?: string | null
          reported_user_id?: string | null
          report_type?:
            | 'spam'
            | 'harassment'
            | 'hate_speech'
            | 'misinformation'
            | 'low_effort'
            | 'off_topic'
            | 'other'
            | 'bot_suspected'
          reason?: string
          evidence?: Json | null
          status?: 'pending' | 'reviewing' | 'resolved' | 'dismissed'
          resolved_by?: string | null
          resolution_action?: string | null
          created_at?: string
          resolved_at?: string | null
        }
      }
      bot_detection: {
        Row: {
          user_id: string
          total_post_count: number
          short_post_count: number
          short_post_percentage: number
          avg_post_length: number
          posting_frequency: number
          duplicate_content_ratio: number
          bot_score: number
          criteria_met: number
          last_evaluated: string
          flagged_at: string | null
        }
        Insert: {
          user_id: string
          total_post_count?: number
          short_post_count?: number
          avg_post_length?: number
          posting_frequency?: number
          duplicate_content_ratio?: number
          bot_score?: number
          criteria_met?: number
          last_evaluated?: string
          flagged_at?: string | null
        }
        Update: {
          user_id?: string
          total_post_count?: number
          short_post_count?: number
          avg_post_length?: number
          posting_frequency?: number
          duplicate_content_ratio?: number
          bot_score?: number
          criteria_met?: number
          last_evaluated?: string
          flagged_at?: string | null
        }
      }
      bot_flags: {
        Row: {
          id: string
          user_id: string
          criteria: number
          flagged_by: string
          reason: string | null
          evidence: Json | null
          is_validated: boolean
          validated_by: string | null
          created_at: string
          validated_at: string | null
        }
        Insert: {
          id?: string
          user_id: string
          criteria: number
          flagged_by: string
          reason?: string | null
          evidence?: Json | null
          is_validated?: boolean
          validated_by?: string | null
          created_at?: string
          validated_at?: string | null
        }
        Update: {
          id?: string
          user_id?: string
          criteria?: number
          flagged_by?: string
          reason?: string | null
          evidence?: Json | null
          is_validated?: boolean
          validated_by?: string | null
          created_at?: string
          validated_at?: string | null
        }
      }
      voting_sessions: {
        Row: {
          id: string
          title: string
          description: string | null
          category_id: string | null
          session_type: 'general' | 'moderator_election' | 'category_feature'
          status: 'pending' | 'active' | 'completed' | 'cancelled'
          min_level_required: number
          total_votes: number
          eligible_voters: number
          created_by: string
          start_date: string
          end_date: string
          created_at: string
        }
        Insert: {
          id?: string
          title: string
          description?: string | null
          category_id?: string | null
          session_type: 'general' | 'moderator_election' | 'category_feature'
          status?: 'pending' | 'active' | 'completed' | 'cancelled'
          min_level_required: number
          total_votes?: number
          eligible_voters?: number
          created_by: string
          start_date: string
          end_date: string
          created_at?: string
        }
        Update: {
          id?: string
          title?: string
          description?: string | null
          category_id?: string | null
          session_type?: 'general' | 'moderator_election' | 'category_feature'
          status?: 'pending' | 'active' | 'completed' | 'cancelled'
          min_level_required?: number
          total_votes?: number
          eligible_voters?: number
          created_by?: string
          start_date?: string
          end_date?: string
          created_at?: string
        }
      }
      voting_options: {
        Row: {
          id: string
          session_id: string
          option_text: string
          description: string | null
          vote_count: number
          created_at: string
        }
        Insert: {
          id?: string
          session_id: string
          option_text: string
          description?: string | null
          vote_count?: number
          created_at?: string
        }
        Update: {
          id?: string
          session_id?: string
          option_text?: string
          description?: string | null
          vote_count?: number
          created_at?: string
        }
      }
      user_votes: {
        Row: {
          session_id: string
          user_id: string
          option_id: string
          voted_at: string
        }
        Insert: {
          session_id: string
          user_id: string
          option_id: string
          voted_at?: string
        }
        Update: {
          session_id?: string
          user_id?: string
          option_id?: string
          voted_at?: string
        }
      }
      moderator_elections: {
        Row: {
          id: string
          category_id: string
          position_count: number
          nomination_start: string
          nomination_end: string
          voting_start: string
          voting_end: string
          status:
            | 'upcoming'
            | 'nomination'
            | 'voting'
            | 'completed'
            | 'cancelled'
          total_votes: number
          eligible_voters: number
          created_at: string
        }
        Insert: {
          id?: string
          category_id: string
          position_count: number
          nomination_start: string
          nomination_end: string
          voting_start: string
          voting_end: string
          status?:
            | 'upcoming'
            | 'nomination'
            | 'voting'
            | 'completed'
            | 'cancelled'
          total_votes?: number
          eligible_voters?: number
          created_at?: string
        }
        Update: {
          id?: string
          category_id?: string
          position_count?: number
          nomination_start?: string
          nomination_end?: string
          voting_start?: string
          voting_end?: string
          status?:
            | 'upcoming'
            | 'nomination'
            | 'voting'
            | 'completed'
            | 'cancelled'
          total_votes?: number
          eligible_voters?: number
          created_at?: string
        }
      }
      user_activities: {
        Row: {
          id: string
          user_id: string
          activity_type:
            | 'login'
            | 'logout'
            | 'thread_created'
            | 'comment_created'
            | 'vote_cast'
            | 'report_submitted'
            | 'badge_earned'
            | 'level_up'
          metadata: Json | null
          ip_address: string | null
          user_agent: string | null
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          activity_type:
            | 'login'
            | 'logout'
            | 'thread_created'
            | 'comment_created'
            | 'vote_cast'
            | 'report_submitted'
            | 'badge_earned'
            | 'level_up'
          metadata?: Json | null
          ip_address?: string | null
          user_agent?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          activity_type?:
            | 'login'
            | 'logout'
            | 'thread_created'
            | 'comment_created'
            | 'vote_cast'
            | 'report_submitted'
            | 'badge_earned'
            | 'level_up'
          metadata?: Json | null
          ip_address?: string | null
          user_agent?: string | null
          created_at?: string
        }
      }
      xp_transactions: {
        Row: {
          id: string
          user_id: string
          amount: number
          reason: string
          source_type:
            | 'thread_created'
            | 'comment_created'
            | 'upvote_received'
            | 'downvote_received'
            | 'voted'
            | 'daily_login'
            | 'moderate_action'
            | 'report_validated'
            | 'election_participation'
          source_id: string | null
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          amount: number
          reason: string
          source_type:
            | 'thread_created'
            | 'comment_created'
            | 'upvote_received'
            | 'downvote_received'
            | 'voted'
            | 'daily_login'
            | 'moderate_action'
            | 'report_validated'
            | 'election_participation'
          source_id?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          amount?: number
          reason?: string
          source_type?:
            | 'thread_created'
            | 'comment_created'
            | 'upvote_received'
            | 'downvote_received'
            | 'voted'
            | 'daily_login'
            | 'moderate_action'
            | 'report_validated'
            | 'election_participation'
          source_id?: string | null
          created_at?: string
        }
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      calculate_hot_score: {
        Args: {
          upvotes: number
          downvotes: number
          created_at: string
        }
        Returns: number
      }
      calculate_wilson_score: {
        Args: {
          upvotes: number
          downvotes: number
          confidence?: number
        }
        Returns: number
      }
      get_xp_for_action: {
        Args: {
          action_type: string
        }
        Returns: number
      }
      calculate_user_level: {
        Args: {
          xp_amount: number
        }
        Returns: number
      }
      award_xp: {
        Args: {
          target_user_id: string
          action_type: string
          reference_content_type?: string
          reference_content_id?: string
        }
        Returns: undefined
      }
      check_bot_criteria: {
        Args: {
          target_user_id: string
        }
        Returns: number
      }
      update_bot_status: {
        Args: {
          target_user_id: string
        }
        Returns: undefined
      }
      generate_comment_path: {
        Args: {
          parent_comment_id?: string
        }
        Returns: string
      }
      get_thread_stats: {
        Args: {
          thread_uuid: string
        }
        Returns: Json
      }
      get_user_stats: {
        Args: {
          user_uuid: string
        }
        Returns: Json
      }
      search_threads: {
        Args: {
          search_query: string
          category_filter?: string
          limit_count?: number
          offset_count?: number
        }
        Returns: {
          id: string
          title: string
          content: string
          category_name: string
          author_username: string
          hot_score: number
          created_at: string
          rank: number
        }[]
      }
      user_has_level: {
        Args: {
          required_level: number
        }
        Returns: boolean
      }
      is_moderator: {
        Args: Record<PropertyKey, never>
        Returns: boolean
      }
      is_moderator_of_category: {
        Args: {
          category_uuid: string
        }
        Returns: boolean
      }
      owns_content: {
        Args: {
          content_author_id: string
        }
        Returns: boolean
      }
    }
    Enums: {
      account_status: 'active' | 'restricted' | 'shadowbanned' | 'banned'
      vote_type: 'upvote' | 'downvote'
      content_type: 'thread' | 'comment'
      report_type:
        | 'spam'
        | 'harassment'
        | 'hate_speech'
        | 'misinformation'
        | 'low_effort'
        | 'off_topic'
        | 'other'
        | 'bot_suspected'
      badge_type: 'activity' | 'special' | 'monthly' | 'achievement'
      badge_tier: 'bronze' | 'silver' | 'gold' | 'platinum'
      session_type: 'general' | 'moderator_election' | 'category_feature'
      session_status: 'pending' | 'active' | 'completed' | 'cancelled'
      election_status:
        | 'upcoming'
        | 'nomination'
        | 'voting'
        | 'completed'
        | 'cancelled'
      activity_type:
        | 'login'
        | 'logout'
        | 'thread_created'
        | 'comment_created'
        | 'vote_cast'
        | 'report_submitted'
        | 'badge_earned'
        | 'level_up'
      xp_source_type:
        | 'thread_created'
        | 'comment_created'
        | 'upvote_received'
        | 'downvote_received'
        | 'voted'
        | 'daily_login'
        | 'moderate_action'
        | 'report_validated'
        | 'election_participation'
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

// Helper types for easier usage
export type Tables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Row']
export type TablesInsert<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Insert']
export type TablesUpdate<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Update']
export type Enums<T extends keyof Database['public']['Enums']> =
  Database['public']['Enums'][T]
export type Functions<T extends keyof Database['public']['Functions']> =
  Database['public']['Functions'][T]

// Commonly used types
export type User = Tables<'users'>
export type Thread = Tables<'threads'>
export type Comment = Tables<'comments'>
export type Category = Tables<'categories'>
export type Vote = Tables<'votes'>
export type Badge = Tables<'badges'>
export type Moderator = Tables<'moderators'>
export type VotingSession = Tables<'voting_sessions'>

// Utility types
export type UserLevel = 1 | 2 | 3 | 4 | 5
export type AccountStatus = Enums<'account_status'>
export type VoteType = Enums<'vote_type'>
export type ContentType = Enums<'content_type'>
