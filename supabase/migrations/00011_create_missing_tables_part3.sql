-- ============================================
-- MIGRATION: Create Missing Tables Part 3
-- Analytics, AI Usage, and Enhanced Digests
-- ============================================

-- Enhanced thread summaries with top contributors
ALTER TABLE thread_summaries
ADD COLUMN IF NOT EXISTS top_contributors JSONB; -- Array of user IDs who contributed most

-- Enhanced category digests with more analytics
ALTER TABLE category_digests
ADD COLUMN IF NOT EXISTS notable_discussions JSONB, -- Highlighted interesting debates
ADD COLUMN IF NOT EXISTS new_users INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS community_mood TEXT, -- Overall sentiment analysis
ADD COLUMN IF NOT EXISTS key_concerns JSONB, -- Main topics of discussion
ADD COLUMN IF NOT EXISTS email_sent BOOLEAN DEFAULT false;

-- AI model usage tracking (for cost monitoring)
CREATE TABLE IF NOT EXISTS ai_usage_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model TEXT NOT NULL,
    purpose TEXT CHECK (purpose IN ('summary', 'digest', 'moderation', 'spam_detection')),
    tokens_used INTEGER NOT NULL,
    estimated_cost DECIMAL(10,4),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Enhanced content reports with priority
ALTER TABLE content_reports
ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'critical')),
ADD COLUMN IF NOT EXISTS action_taken TEXT;

-- Update content report types to match plan
ALTER TABLE content_reports
DROP CONSTRAINT IF EXISTS content_reports_report_type_check,
ADD CONSTRAINT content_reports_report_type_check CHECK (report_type IN (
    'spam', 'harassment', 'hate_speech', 'misinformation',
    'low_effort', 'off_topic', 'nsfw', 'copyright', 'other'
));

-- Enhanced user activity with session tracking
ALTER TABLE user_activity
ADD COLUMN IF NOT EXISTS session_id UUID REFERENCES user_sessions(id);

-- Update user activity types to match plan
ALTER TABLE user_activity
DROP CONSTRAINT IF EXISTS user_activity_activity_type_check,
ADD CONSTRAINT user_activity_activity_type_check CHECK (activity_type IN (
    'login', 'logout', 'post_created', 'comment_created',
    'vote_cast', 'report_submitted', 'badge_earned',
    'level_up', 'moderator_action', 'election_vote'
));

-- Category statistics table for analytics dashboard
CREATE TABLE IF NOT EXISTS category_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    stat_date DATE NOT NULL,

    -- Activity metrics
    posts_created INTEGER DEFAULT 0,
    comments_created INTEGER DEFAULT 0,
    votes_cast INTEGER DEFAULT 0,
    unique_visitors INTEGER DEFAULT 0,
    page_views INTEGER DEFAULT 0,

    -- Engagement metrics
    avg_time_on_page INTERVAL,
    bounce_rate DECIMAL(5,2),

    -- Growth metrics
    new_subscribers INTEGER DEFAULT 0,
    unsubscribes INTEGER DEFAULT 0,

    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT unique_daily_stats UNIQUE(category_id, stat_date)
);

-- Enhanced notifications with priority and metadata
ALTER TABLE notifications
ADD COLUMN IF NOT EXISTS metadata JSONB, -- Additional context data
ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high'));

-- Update notification types to match plan
ALTER TABLE notifications
DROP CONSTRAINT IF EXISTS notifications_type_check,
ADD CONSTRAINT notifications_type_check CHECK (type IN (
    'reply', 'mention', 'upvote', 'badge_earned',
    'moderator_action', 'election_started', 'warning_received',
    'level_up', 'thread_hot', 'digest_available'
));

-- Enhanced notification preferences
ALTER TABLE notification_preferences
ADD COLUMN IF NOT EXISTS in_app_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS hot_threads BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS digest_frequency TEXT DEFAULT 'daily' CHECK (digest_frequency IN ('daily', 'weekly', 'never')),
ADD COLUMN IF NOT EXISTS digest_time TIME DEFAULT '09:00:00',
ADD COLUMN IF NOT EXISTS quiet_hours_start TIME,
ADD COLUMN IF NOT EXISTS quiet_hours_end TIME;