export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      badges: {
        Row: {
          created_at: string | null
          description: string
          icon_url: string | null
          id: string
          is_active: boolean | null
          is_secret: boolean | null
          name: string
          points_value: number | null
          requirements: Json
          tier: string | null
          type: string | null
          xp_reward: number | null
        }
        Insert: {
          created_at?: string | null
          description: string
          icon_url?: string | null
          id?: string
          is_active?: boolean | null
          is_secret?: boolean | null
          name: string
          points_value?: number | null
          requirements: Json
          tier?: string | null
          type?: string | null
          xp_reward?: number | null
        }
        Update: {
          created_at?: string | null
          description?: string
          icon_url?: string | null
          id?: string
          is_active?: boolean | null
          is_secret?: boolean | null
          name?: string
          points_value?: number | null
          requirements?: Json
          tier?: string | null
          type?: string | null
          xp_reward?: number | null
        }
        Relationships: []
      }
      bot_detection: {
        Row: {
          banned_at: string | null
          bot_reports_count: number | null
          bot_score: number | null
          duplicate_content_ratio: number | null
          failed_captcha_count: number | null
          flagged_at: string | null
          is_bot: boolean | null
          last_evaluated: string | null
          moderator_reports_count: number | null
          posting_frequency: number | null
          short_post_count: number | null
          short_post_percentage: number | null
          strikes: number | null
          total_post_count: number | null
          user_id: string
        }
        Insert: {
          banned_at?: string | null
          bot_reports_count?: number | null
          bot_score?: number | null
          duplicate_content_ratio?: number | null
          failed_captcha_count?: number | null
          flagged_at?: string | null
          is_bot?: boolean | null
          last_evaluated?: string | null
          moderator_reports_count?: number | null
          posting_frequency?: number | null
          short_post_count?: number | null
          short_post_percentage?: number | null
          strikes?: number | null
          total_post_count?: number | null
          user_id: string
        }
        Update: {
          banned_at?: string | null
          bot_reports_count?: number | null
          bot_score?: number | null
          duplicate_content_ratio?: number | null
          failed_captcha_count?: number | null
          flagged_at?: string | null
          is_bot?: boolean | null
          last_evaluated?: string | null
          moderator_reports_count?: number | null
          posting_frequency?: number | null
          short_post_count?: number | null
          short_post_percentage?: number | null
          strikes?: number | null
          total_post_count?: number | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "bot_detection_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      bot_reports: {
        Row: {
          created_at: string | null
          evidence: Json | null
          id: string
          reason: string
          reported_user_id: string | null
          reporter_id: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          status: string | null
        }
        Insert: {
          created_at?: string | null
          evidence?: Json | null
          id?: string
          reason: string
          reported_user_id?: string | null
          reporter_id?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string | null
        }
        Update: {
          created_at?: string | null
          evidence?: Json | null
          id?: string
          reason?: string
          reported_user_id?: string | null
          reporter_id?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          status?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "bot_reports_reported_user_id_fkey"
            columns: ["reported_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bot_reports_reporter_id_fkey"
            columns: ["reporter_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bot_reports_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      categories: {
        Row: {
          color: string | null
          created_at: string | null
          depth: number | null
          description: string | null
          icon_url: string | null
          id: string
          is_active: boolean | null
          is_default: boolean | null
          is_locked: boolean | null
          min_level_to_comment: number | null
          min_level_to_post: number | null
          name: string
          parent_id: string | null
          path: unknown | null
          post_count: number | null
          slug: string
          subscriber_count: number | null
          updated_at: string | null
        }
        Insert: {
          color?: string | null
          created_at?: string | null
          depth?: number | null
          description?: string | null
          icon_url?: string | null
          id?: string
          is_active?: boolean | null
          is_default?: boolean | null
          is_locked?: boolean | null
          min_level_to_comment?: number | null
          min_level_to_post?: number | null
          name: string
          parent_id?: string | null
          path?: unknown | null
          post_count?: number | null
          slug: string
          subscriber_count?: number | null
          updated_at?: string | null
        }
        Update: {
          color?: string | null
          created_at?: string | null
          depth?: number | null
          description?: string | null
          icon_url?: string | null
          id?: string
          is_active?: boolean | null
          is_default?: boolean | null
          is_locked?: boolean | null
          min_level_to_comment?: number | null
          min_level_to_post?: number | null
          name?: string
          parent_id?: string | null
          path?: unknown | null
          post_count?: number | null
          slug?: string
          subscriber_count?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "categories_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
        ]
      }
      category_digests: {
        Row: {
          active_users: number | null
          category_id: string | null
          digest_date: string
          generated_at: string | null
          id: string
          top_threads: Json
          total_comments: number | null
          total_posts: number | null
          trending_topics: Json | null
        }
        Insert: {
          active_users?: number | null
          category_id?: string | null
          digest_date: string
          generated_at?: string | null
          id?: string
          top_threads: Json
          total_comments?: number | null
          total_posts?: number | null
          trending_topics?: Json | null
        }
        Update: {
          active_users?: number | null
          category_id?: string | null
          digest_date?: string
          generated_at?: string | null
          id?: string
          top_threads?: Json
          total_comments?: number | null
          total_posts?: number | null
          trending_topics?: Json | null
        }
        Relationships: [
          {
            foreignKeyName: "category_digests_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
        ]
      }
      category_rules: {
        Row: {
          category_id: string | null
          created_at: string | null
          description: string
          id: string
          rule_number: number
          title: string
        }
        Insert: {
          category_id?: string | null
          created_at?: string | null
          description: string
          id?: string
          rule_number: number
          title: string
        }
        Update: {
          category_id?: string | null
          created_at?: string | null
          description?: string
          id?: string
          rule_number?: number
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "category_rules_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
        ]
      }
      category_subscriptions: {
        Row: {
          category_id: string
          notification_enabled: boolean | null
          subscribed_at: string | null
          user_id: string
        }
        Insert: {
          category_id: string
          notification_enabled?: boolean | null
          subscribed_at?: string | null
          user_id: string
        }
        Update: {
          category_id?: string
          notification_enabled?: boolean | null
          subscribed_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "category_subscriptions_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "category_subscriptions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      comment_votes: {
        Row: {
          comment_id: string
          user_id: string
          vote_type: string
          voted_at: string | null
        }
        Insert: {
          comment_id: string
          user_id: string
          vote_type: string
          voted_at?: string | null
        }
        Update: {
          comment_id?: string
          user_id?: string
          vote_type?: string
          voted_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "comment_votes_comment_id_fkey"
            columns: ["comment_id"]
            isOneToOne: false
            referencedRelation: "comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comment_votes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      comments: {
        Row: {
          content: string
          content_html: string | null
          created_at: string | null
          depth: number | null
          downvotes: number | null
          edit_count: number | null
          edited_at: string | null
          id: string
          is_removed: boolean | null
          parent_id: string | null
          path: unknown
          removal_reason: string | null
          removed_at: string | null
          removed_by: string | null
          thread_id: string | null
          updated_at: string | null
          upvotes: number | null
          user_id: string | null
        }
        Insert: {
          content: string
          content_html?: string | null
          created_at?: string | null
          depth?: number | null
          downvotes?: number | null
          edit_count?: number | null
          edited_at?: string | null
          id?: string
          is_removed?: boolean | null
          parent_id?: string | null
          path: unknown
          removal_reason?: string | null
          removed_at?: string | null
          removed_by?: string | null
          thread_id?: string | null
          updated_at?: string | null
          upvotes?: number | null
          user_id?: string | null
        }
        Update: {
          content?: string
          content_html?: string | null
          created_at?: string | null
          depth?: number | null
          downvotes?: number | null
          edit_count?: number | null
          edited_at?: string | null
          id?: string
          is_removed?: boolean | null
          parent_id?: string | null
          path?: unknown
          removal_reason?: string | null
          removed_at?: string | null
          removed_by?: string | null
          thread_id?: string | null
          updated_at?: string | null
          upvotes?: number | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "comments_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "comments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_removed_by_fkey"
            columns: ["removed_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_thread_id_fkey"
            columns: ["thread_id"]
            isOneToOne: false
            referencedRelation: "threads"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      content_reports: {
        Row: {
          content_id: string
          content_type: string | null
          created_at: string | null
          id: string
          moderator_id: string | null
          moderator_notes: string | null
          reason: string | null
          report_type: string | null
          reporter_id: string | null
          resolved_at: string | null
          status: string | null
        }
        Insert: {
          content_id: string
          content_type?: string | null
          created_at?: string | null
          id?: string
          moderator_id?: string | null
          moderator_notes?: string | null
          reason?: string | null
          report_type?: string | null
          reporter_id?: string | null
          resolved_at?: string | null
          status?: string | null
        }
        Update: {
          content_id?: string
          content_type?: string | null
          created_at?: string | null
          id?: string
          moderator_id?: string | null
          moderator_notes?: string | null
          reason?: string | null
          report_type?: string | null
          reporter_id?: string | null
          resolved_at?: string | null
          status?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "content_reports_moderator_id_fkey"
            columns: ["moderator_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "content_reports_reporter_id_fkey"
            columns: ["reporter_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      election_votes: {
        Row: {
          election_id: string
          vote: string | null
          voted_at: string | null
          voter_id: string
        }
        Insert: {
          election_id: string
          vote?: string | null
          voted_at?: string | null
          voter_id: string
        }
        Update: {
          election_id?: string
          vote?: string | null
          voted_at?: string | null
          voter_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "election_votes_election_id_fkey"
            columns: ["election_id"]
            isOneToOne: false
            referencedRelation: "moderator_elections"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "election_votes_voter_id_fkey"
            columns: ["voter_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      moderation_logs: {
        Row: {
          action: string | null
          content_type: string | null
          created_at: string | null
          id: string
          metadata: Json | null
          moderator_id: string | null
          reason: string | null
          target_content_id: string | null
          target_user_id: string | null
        }
        Insert: {
          action?: string | null
          content_type?: string | null
          created_at?: string | null
          id?: string
          metadata?: Json | null
          moderator_id?: string | null
          reason?: string | null
          target_content_id?: string | null
          target_user_id?: string | null
        }
        Update: {
          action?: string | null
          content_type?: string | null
          created_at?: string | null
          id?: string
          metadata?: Json | null
          moderator_id?: string | null
          reason?: string | null
          target_content_id?: string | null
          target_user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "moderation_logs_moderator_id_fkey"
            columns: ["moderator_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "moderation_logs_target_user_id_fkey"
            columns: ["target_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      moderator_bot_reports: {
        Row: {
          category_context: string | null
          created_at: string | null
          evidence: Json | null
          id: string
          moderator_id: string | null
          reason: string
          reported_user_id: string | null
        }
        Insert: {
          category_context?: string | null
          created_at?: string | null
          evidence?: Json | null
          id?: string
          moderator_id?: string | null
          reason: string
          reported_user_id?: string | null
        }
        Update: {
          category_context?: string | null
          created_at?: string | null
          evidence?: Json | null
          id?: string
          moderator_id?: string | null
          reason?: string
          reported_user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "moderator_bot_reports_moderator_id_fkey"
            columns: ["moderator_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "moderator_bot_reports_reported_user_id_fkey"
            columns: ["reported_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      moderator_elections: {
        Row: {
          category_id: string | null
          completed_at: string | null
          election_type: string | null
          eligible_voter_count: number | null
          ends_at: string
          id: string
          initiated_by: string | null
          started_at: string | null
          status: string | null
          target_user_id: string | null
          votes_against: number | null
          votes_for: number | null
          winner_id: string | null
        }
        Insert: {
          category_id?: string | null
          completed_at?: string | null
          election_type?: string | null
          eligible_voter_count?: number | null
          ends_at: string
          id?: string
          initiated_by?: string | null
          started_at?: string | null
          status?: string | null
          target_user_id?: string | null
          votes_against?: number | null
          votes_for?: number | null
          winner_id?: string | null
        }
        Update: {
          category_id?: string | null
          completed_at?: string | null
          election_type?: string | null
          eligible_voter_count?: number | null
          ends_at?: string
          id?: string
          initiated_by?: string | null
          started_at?: string | null
          status?: string | null
          target_user_id?: string | null
          votes_against?: number | null
          votes_for?: number | null
          winner_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "moderator_elections_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "moderator_elections_initiated_by_fkey"
            columns: ["initiated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "moderator_elections_target_user_id_fkey"
            columns: ["target_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "moderator_elections_winner_id_fkey"
            columns: ["winner_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      moderators: {
        Row: {
          actions_count: number | null
          category_id: string | null
          elected_at: string | null
          id: string
          is_active: boolean | null
          removal_reason: string | null
          term_ends_at: string | null
          term_starts_at: string | null
          user_id: string | null
          votes_received: number
          warnings_issued: number | null
        }
        Insert: {
          actions_count?: number | null
          category_id?: string | null
          elected_at?: string | null
          id?: string
          is_active?: boolean | null
          removal_reason?: string | null
          term_ends_at?: string | null
          term_starts_at?: string | null
          user_id?: string | null
          votes_received: number
          warnings_issued?: number | null
        }
        Update: {
          actions_count?: number | null
          category_id?: string | null
          elected_at?: string | null
          id?: string
          is_active?: boolean | null
          removal_reason?: string | null
          term_ends_at?: string | null
          term_starts_at?: string | null
          user_id?: string | null
          votes_received?: number
          warnings_issued?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "moderators_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "moderators_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_preferences: {
        Row: {
          badges: boolean | null
          digests: boolean | null
          elections: boolean | null
          email_enabled: boolean | null
          mentions: boolean | null
          moderator_actions: boolean | null
          push_enabled: boolean | null
          replies: boolean | null
          updated_at: string | null
          upvotes: boolean | null
          user_id: string
        }
        Insert: {
          badges?: boolean | null
          digests?: boolean | null
          elections?: boolean | null
          email_enabled?: boolean | null
          mentions?: boolean | null
          moderator_actions?: boolean | null
          push_enabled?: boolean | null
          replies?: boolean | null
          updated_at?: string | null
          upvotes?: boolean | null
          user_id: string
        }
        Update: {
          badges?: boolean | null
          digests?: boolean | null
          elections?: boolean | null
          email_enabled?: boolean | null
          mentions?: boolean | null
          moderator_actions?: boolean | null
          push_enabled?: boolean | null
          replies?: boolean | null
          updated_at?: string | null
          upvotes?: boolean | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notification_preferences_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          content: string
          created_at: string | null
          id: string
          is_read: boolean | null
          link: string | null
          read_at: string | null
          title: string
          type: string | null
          user_id: string | null
        }
        Insert: {
          content: string
          created_at?: string | null
          id?: string
          is_read?: boolean | null
          link?: string | null
          read_at?: string | null
          title: string
          type?: string | null
          user_id?: string | null
        }
        Update: {
          content?: string
          created_at?: string | null
          id?: string
          is_read?: boolean | null
          link?: string | null
          read_at?: string | null
          title?: string
          type?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      schema_migrations: {
        Row: {
          applied_at: string | null
          description: string | null
          version: number
        }
        Insert: {
          applied_at?: string | null
          description?: string | null
          version: number
        }
        Update: {
          applied_at?: string | null
          description?: string | null
          version?: number
        }
        Relationships: []
      }
      session_votes: {
        Row: {
          entry_id: string | null
          session_id: string
          voted_at: string | null
          voter_id: string
        }
        Insert: {
          entry_id?: string | null
          session_id: string
          voted_at?: string | null
          voter_id: string
        }
        Update: {
          entry_id?: string | null
          session_id?: string
          voted_at?: string | null
          voter_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "session_votes_entry_id_fkey"
            columns: ["entry_id"]
            isOneToOne: false
            referencedRelation: "voting_entries"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "session_votes_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "voting_sessions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "session_votes_voter_id_fkey"
            columns: ["voter_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      spam_logs: {
        Row: {
          action_taken: string | null
          content_id: string
          content_type: string | null
          created_at: string | null
          id: string
          patterns_matched: Json | null
          spam_score: number
          user_id: string | null
        }
        Insert: {
          action_taken?: string | null
          content_id: string
          content_type?: string | null
          created_at?: string | null
          id?: string
          patterns_matched?: Json | null
          spam_score: number
          user_id?: string | null
        }
        Update: {
          action_taken?: string | null
          content_id?: string
          content_type?: string | null
          created_at?: string | null
          id?: string
          patterns_matched?: Json | null
          spam_score?: number
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "spam_logs_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      spam_patterns: {
        Row: {
          created_at: string | null
          id: string
          is_active: boolean | null
          match_count: number | null
          pattern_name: string
          pattern_regex: string | null
          pattern_type: string | null
          weight: number | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          is_active?: boolean | null
          match_count?: number | null
          pattern_name: string
          pattern_regex?: string | null
          pattern_type?: string | null
          weight?: number | null
        }
        Update: {
          created_at?: string | null
          id?: string
          is_active?: boolean | null
          match_count?: number | null
          pattern_name?: string
          pattern_regex?: string | null
          pattern_type?: string | null
          weight?: number | null
        }
        Relationships: []
      }
      thread_summaries: {
        Row: {
          category_id: string | null
          engagement_score: number | null
          generated_at: string | null
          id: string
          key_points: Json | null
          sentiment_score: number | null
          summary_date: string | null
          summary_text: string
          thread_id: string | null
        }
        Insert: {
          category_id?: string | null
          engagement_score?: number | null
          generated_at?: string | null
          id?: string
          key_points?: Json | null
          sentiment_score?: number | null
          summary_date?: string | null
          summary_text: string
          thread_id?: string | null
        }
        Update: {
          category_id?: string | null
          engagement_score?: number | null
          generated_at?: string | null
          id?: string
          key_points?: Json | null
          sentiment_score?: number | null
          summary_date?: string | null
          summary_text?: string
          thread_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "thread_summaries_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "thread_summaries_thread_id_fkey"
            columns: ["thread_id"]
            isOneToOne: false
            referencedRelation: "threads"
            referencedColumns: ["id"]
          },
        ]
      }
      thread_votes: {
        Row: {
          thread_id: string
          user_id: string
          vote_type: string
          voted_at: string | null
        }
        Insert: {
          thread_id: string
          user_id: string
          vote_type: string
          voted_at?: string | null
        }
        Update: {
          thread_id?: string
          user_id?: string
          vote_type?: string
          voted_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "thread_votes_thread_id_fkey"
            columns: ["thread_id"]
            isOneToOne: false
            referencedRelation: "threads"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "thread_votes_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      threads: {
        Row: {
          category_id: string
          comment_count: number | null
          content: string
          content_html: string | null
          created_at: string | null
          downvotes: number | null
          edit_count: number | null
          edited_at: string | null
          hot_score: number | null
          id: string
          is_hot: boolean | null
          is_locked: boolean | null
          is_pinned: boolean | null
          is_removed: boolean | null
          is_spam: boolean | null
          last_activity_at: string | null
          removal_reason: string | null
          removed_at: string | null
          removed_by: string | null
          spam_score: number | null
          title: string
          updated_at: string | null
          upvotes: number | null
          user_id: string | null
          view_count: number | null
        }
        Insert: {
          category_id: string
          comment_count?: number | null
          content: string
          content_html?: string | null
          created_at?: string | null
          downvotes?: number | null
          edit_count?: number | null
          edited_at?: string | null
          hot_score?: number | null
          id?: string
          is_hot?: boolean | null
          is_locked?: boolean | null
          is_pinned?: boolean | null
          is_removed?: boolean | null
          is_spam?: boolean | null
          last_activity_at?: string | null
          removal_reason?: string | null
          removed_at?: string | null
          removed_by?: string | null
          spam_score?: number | null
          title: string
          updated_at?: string | null
          upvotes?: number | null
          user_id?: string | null
          view_count?: number | null
        }
        Update: {
          category_id?: string
          comment_count?: number | null
          content?: string
          content_html?: string | null
          created_at?: string | null
          downvotes?: number | null
          edit_count?: number | null
          edited_at?: string | null
          hot_score?: number | null
          id?: string
          is_hot?: boolean | null
          is_locked?: boolean | null
          is_pinned?: boolean | null
          is_removed?: boolean | null
          is_spam?: boolean | null
          last_activity_at?: string | null
          removal_reason?: string | null
          removed_at?: string | null
          removed_by?: string | null
          spam_score?: number | null
          title?: string
          updated_at?: string | null
          upvotes?: number | null
          user_id?: string | null
          view_count?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "threads_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "threads_removed_by_fkey"
            columns: ["removed_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "threads_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      trust_factors: {
        Row: {
          false_reports: number | null
          moderator_warnings: number | null
          negative_interactions: number | null
          positive_interactions: number | null
          successful_reports: number | null
          updated_at: string | null
          user_id: string
          verified_email: boolean | null
          verified_phone: boolean | null
        }
        Insert: {
          false_reports?: number | null
          moderator_warnings?: number | null
          negative_interactions?: number | null
          positive_interactions?: number | null
          successful_reports?: number | null
          updated_at?: string | null
          user_id: string
          verified_email?: boolean | null
          verified_phone?: boolean | null
        }
        Update: {
          false_reports?: number | null
          moderator_warnings?: number | null
          negative_interactions?: number | null
          positive_interactions?: number | null
          successful_reports?: number | null
          updated_at?: string | null
          user_id?: string
          verified_email?: boolean | null
          verified_phone?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "trust_factors_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_activity: {
        Row: {
          activity_type: string | null
          created_at: string | null
          id: string
          ip_address: unknown | null
          metadata: Json | null
          user_agent: string | null
          user_id: string | null
        }
        Insert: {
          activity_type?: string | null
          created_at?: string | null
          id?: string
          ip_address?: unknown | null
          metadata?: Json | null
          user_agent?: string | null
          user_id?: string | null
        }
        Update: {
          activity_type?: string | null
          created_at?: string | null
          id?: string
          ip_address?: unknown | null
          metadata?: Json | null
          user_agent?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "user_activity_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_badges: {
        Row: {
          awarded_at: string | null
          awarded_for: string | null
          badge_id: string
          user_id: string
        }
        Insert: {
          awarded_at?: string | null
          awarded_for?: string | null
          badge_id: string
          user_id: string
        }
        Update: {
          awarded_at?: string | null
          awarded_for?: string | null
          badge_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_badges_badge_id_fkey"
            columns: ["badge_id"]
            isOneToOne: false
            referencedRelation: "badges"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_badges_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_sessions: {
        Row: {
          created_at: string | null
          expires_at: string
          id: string
          ip_address: unknown | null
          token: string
          user_agent: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          expires_at: string
          id?: string
          ip_address?: unknown | null
          token: string
          user_agent?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          expires_at?: string
          id?: string
          ip_address?: unknown | null
          token?: string
          user_agent?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "user_sessions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_warnings: {
        Row: {
          category_id: string | null
          created_at: string | null
          expires_at: string | null
          id: string
          moderator_id: string | null
          reason: string
          severity: string | null
          user_id: string | null
        }
        Insert: {
          category_id?: string | null
          created_at?: string | null
          expires_at?: string | null
          id?: string
          moderator_id?: string | null
          reason: string
          severity?: string | null
          user_id?: string | null
        }
        Update: {
          category_id?: string | null
          created_at?: string | null
          expires_at?: string | null
          id?: string
          moderator_id?: string | null
          reason?: string
          severity?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "user_warnings_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_warnings_moderator_id_fkey"
            columns: ["moderator_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_warnings_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      users: {
        Row: {
          account_status: string | null
          avatar_url: string | null
          ban_expires_at: string | null
          ban_reason: string | null
          bio: string | null
          comment_count: number | null
          created_at: string | null
          email: string
          helpful_votes: number | null
          id: string
          last_active: string | null
          level: number | null
          password_hash: string | null
          post_count: number | null
          trust_score: number | null
          updated_at: string | null
          username: string
          xp: number | null
        }
        Insert: {
          account_status?: string | null
          avatar_url?: string | null
          ban_expires_at?: string | null
          ban_reason?: string | null
          bio?: string | null
          comment_count?: number | null
          created_at?: string | null
          email: string
          helpful_votes?: number | null
          id?: string
          last_active?: string | null
          level?: number | null
          password_hash?: string | null
          post_count?: number | null
          trust_score?: number | null
          updated_at?: string | null
          username: string
          xp?: number | null
        }
        Update: {
          account_status?: string | null
          avatar_url?: string | null
          ban_expires_at?: string | null
          ban_reason?: string | null
          bio?: string | null
          comment_count?: number | null
          created_at?: string | null
          email?: string
          helpful_votes?: number | null
          id?: string
          last_active?: string | null
          level?: number | null
          password_hash?: string | null
          post_count?: number | null
          trust_score?: number | null
          updated_at?: string | null
          username?: string
          xp?: number | null
        }
        Relationships: []
      }
      voting_entries: {
        Row: {
          created_at: string | null
          id: string
          nomination_reason: string | null
          nominee_id: string | null
          session_id: string | null
          votes_received: number | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          nomination_reason?: string | null
          nominee_id?: string | null
          session_id?: string | null
          votes_received?: number | null
        }
        Update: {
          created_at?: string | null
          id?: string
          nomination_reason?: string | null
          nominee_id?: string | null
          session_id?: string | null
          votes_received?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "voting_entries_nominee_id_fkey"
            columns: ["nominee_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "voting_entries_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "voting_sessions"
            referencedColumns: ["id"]
          },
        ]
      }
      voting_sessions: {
        Row: {
          created_at: string | null
          description: string | null
          ends_at: string | null
          id: string
          month: string
          participation_badge_id: string | null
          starts_at: string | null
          status: string | null
          title: string
          total_votes: number | null
          winner_badge_id: string | null
          winner_id: string | null
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          ends_at?: string | null
          id?: string
          month: string
          participation_badge_id?: string | null
          starts_at?: string | null
          status?: string | null
          title: string
          total_votes?: number | null
          winner_badge_id?: string | null
          winner_id?: string | null
        }
        Update: {
          created_at?: string | null
          description?: string | null
          ends_at?: string | null
          id?: string
          month?: string
          participation_badge_id?: string | null
          starts_at?: string | null
          status?: string | null
          title?: string
          total_votes?: number | null
          winner_badge_id?: string | null
          winner_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "voting_sessions_participation_badge_id_fkey"
            columns: ["participation_badge_id"]
            isOneToOne: false
            referencedRelation: "badges"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "voting_sessions_winner_badge_id_fkey"
            columns: ["winner_badge_id"]
            isOneToOne: false
            referencedRelation: "badges"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "voting_sessions_winner_id_fkey"
            columns: ["winner_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      xp_transactions: {
        Row: {
          amount: number
          created_at: string | null
          id: string
          reason: string
          source_id: string | null
          source_type: string | null
          user_id: string | null
        }
        Insert: {
          amount: number
          created_at?: string | null
          id?: string
          reason: string
          source_id?: string | null
          source_type?: string | null
          user_id?: string | null
        }
        Update: {
          amount?: number
          created_at?: string | null
          id?: string
          reason?: string
          source_id?: string | null
          source_type?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "xp_transactions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      trust_factors_with_age: {
        Row: {
          account_age_days: number | null
          false_reports: number | null
          moderator_warnings: number | null
          negative_interactions: number | null
          positive_interactions: number | null
          successful_reports: number | null
          updated_at: string | null
          user_id: string | null
          verified_email: boolean | null
          verified_phone: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "trust_factors_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Functions: {
      _ltree_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      _ltree_gist_options: {
        Args: { "": unknown }
        Returns: undefined
      }
      archive_old_notifications: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      award_xp: {
        Args: {
          action_type: string
          reference_content_id?: string
          reference_content_type?: string
          target_user_id: string
        }
        Returns: undefined
      }
      calculate_hot_score: {
        Args:
          | { created_at: string; downvotes: number; upvotes: number }
          | { created_at: string; downvotes: number; upvotes: number }
        Returns: number
      }
      calculate_user_level: {
        Args: { xp_amount: number }
        Returns: number
      }
      calculate_wilson_score: {
        Args: { confidence?: number; downvotes: number; upvotes: number }
        Returns: number
      }
      check_bot_criteria: {
        Args: { target_user_id: string }
        Returns: number
      }
      cleanup_expired_sessions: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      evaluate_bot_status: {
        Args: { user_id_param: string }
        Returns: {
          bot_score: number
          is_bot: boolean
          strikes: number
        }[]
      }
      generate_comment_path: {
        Args: { parent_comment_id?: string }
        Returns: unknown
      }
      get_category_path: {
        Args: { category_id: string }
        Returns: string
      }
      get_thread_stats: {
        Args: { thread_uuid: string }
        Returns: Json
      }
      get_user_stats: {
        Args: { user_uuid: string }
        Returns: Json
      }
      get_xp_for_action: {
        Args: { action_type: string }
        Returns: number
      }
      gtrgm_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gtrgm_decompress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gtrgm_in: {
        Args: { "": unknown }
        Returns: unknown
      }
      gtrgm_options: {
        Args: { "": unknown }
        Returns: undefined
      }
      gtrgm_out: {
        Args: { "": unknown }
        Returns: unknown
      }
      lca: {
        Args: { "": unknown[] }
        Returns: unknown
      }
      lquery_in: {
        Args: { "": unknown }
        Returns: unknown
      }
      lquery_out: {
        Args: { "": unknown }
        Returns: unknown
      }
      lquery_recv: {
        Args: { "": unknown }
        Returns: unknown
      }
      lquery_send: {
        Args: { "": unknown }
        Returns: string
      }
      ltree_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      ltree_decompress: {
        Args: { "": unknown }
        Returns: unknown
      }
      ltree_gist_in: {
        Args: { "": unknown }
        Returns: unknown
      }
      ltree_gist_options: {
        Args: { "": unknown }
        Returns: undefined
      }
      ltree_gist_out: {
        Args: { "": unknown }
        Returns: unknown
      }
      ltree_in: {
        Args: { "": unknown }
        Returns: unknown
      }
      ltree_out: {
        Args: { "": unknown }
        Returns: unknown
      }
      ltree_recv: {
        Args: { "": unknown }
        Returns: unknown
      }
      ltree_send: {
        Args: { "": unknown }
        Returns: string
      }
      ltree2text: {
        Args: { "": unknown }
        Returns: string
      }
      ltxtq_in: {
        Args: { "": unknown }
        Returns: unknown
      }
      ltxtq_out: {
        Args: { "": unknown }
        Returns: unknown
      }
      ltxtq_recv: {
        Args: { "": unknown }
        Returns: unknown
      }
      ltxtq_send: {
        Args: { "": unknown }
        Returns: string
      }
      nlevel: {
        Args: { "": unknown }
        Returns: number
      }
      recalculate_trust_scores: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      search_threads: {
        Args: {
          category_filter?: string
          limit_count?: number
          offset_count?: number
          search_query: string
        }
        Returns: {
          author_username: string
          category_name: string
          content: string
          created_at: string
          hot_score: number
          id: string
          rank: number
          title: string
        }[]
      }
      set_limit: {
        Args: { "": number }
        Returns: number
      }
      show_limit: {
        Args: Record<PropertyKey, never>
        Returns: number
      }
      show_trgm: {
        Args: { "": string }
        Returns: string[]
      }
      text2ltree: {
        Args: { "": string }
        Returns: unknown
      }
      update_bot_status: {
        Args: { target_user_id: string }
        Returns: undefined
      }
      update_hot_threads: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {},
  },
} as const

// ============================================
// Custom Type Exports
// ============================================

// User level type (1-5)
export type UserLevel = 1 | 2 | 3 | 4 | 5

// Account status type
export type AccountStatus = 'active' | 'restricted' | 'shadowbanned' | 'banned'

// Vote type
export type VoteType = 'upvote' | 'downvote'

// Content type for votes/reports
export type ContentType = 'thread' | 'comment'

// Bot classification
export type BotClassification = 'human' | 'suspicious' | 'bot'

