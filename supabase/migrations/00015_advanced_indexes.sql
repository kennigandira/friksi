-- ============================================
-- MIGRATION: Advanced Indexes for Performance
-- Comprehensive indexing strategy from the plan
-- ============================================

-- Enhanced user indexes with case-insensitive and filtered indexes
CREATE INDEX IF NOT EXISTS idx_users_username_lower ON users(LOWER(username));
CREATE INDEX IF NOT EXISTS idx_users_email_lower ON users(LOWER(email));
CREATE INDEX IF NOT EXISTS idx_users_level ON users(level) WHERE account_status = 'active';
CREATE INDEX IF NOT EXISTS idx_users_trust_score ON users(trust_score DESC) WHERE account_status = 'active';
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);

-- Enhanced category indexes with LTREE support
CREATE INDEX IF NOT EXISTS idx_categories_active ON categories(is_active) WHERE is_active = true;

-- Enhanced thread indexes with composite and filtered indexes
CREATE INDEX IF NOT EXISTS idx_threads_hot ON threads(is_hot, hot_score DESC) WHERE is_removed = false;
CREATE INDEX IF NOT EXISTS idx_threads_category_created ON threads(category_id, created_at DESC) WHERE is_removed = false;
CREATE INDEX IF NOT EXISTS idx_threads_last_activity ON threads(last_activity_at DESC) WHERE is_removed = false;

-- Enhanced comment indexes
CREATE INDEX IF NOT EXISTS idx_comments_thread_created ON comments(thread_id, created_at);

-- Bot detection specialized indexes
CREATE INDEX IF NOT EXISTS idx_bot_detection_strikes ON bot_detection(strikes) WHERE strikes >= 2;
CREATE INDEX IF NOT EXISTS idx_bot_reports_reported_user ON bot_reports(reported_user_id) WHERE status = 'pending';

-- Enhanced moderation indexes
CREATE INDEX IF NOT EXISTS idx_moderators_user ON moderators(user_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_moderators_category ON moderators(category_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_moderation_logs_created ON moderation_logs(created_at DESC);

-- Enhanced notification indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_created ON notifications(user_id, created_at DESC);

-- Enhanced report indexes
CREATE INDEX IF NOT EXISTS idx_content_reports_pending ON content_reports(created_at)
    WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_content_reports_content ON content_reports(content_type, content_id);

-- New indexes for tables we added
CREATE INDEX IF NOT EXISTS idx_thread_edits_thread ON thread_edits(thread_id);
CREATE INDEX IF NOT EXISTS idx_thread_edits_user ON thread_edits(user_id);

CREATE INDEX IF NOT EXISTS idx_temporary_bans_user ON temporary_bans(user_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_temporary_bans_expires ON temporary_bans(expires_at) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_user_badges_user ON user_badges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_badge ON user_badges(badge_id);

CREATE INDEX IF NOT EXISTS idx_xp_transactions_user ON xp_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_xp_transactions_created ON xp_transactions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_polls_thread ON polls(thread_id);
CREATE INDEX IF NOT EXISTS idx_poll_votes_poll ON poll_votes(poll_id);

CREATE INDEX IF NOT EXISTS idx_category_stats_category_date ON category_stats(category_id, stat_date);
CREATE INDEX IF NOT EXISTS idx_ai_usage_logs_created ON ai_usage_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_usage_logs_purpose ON ai_usage_logs(purpose);