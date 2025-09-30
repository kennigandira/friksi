-- ============================================
-- Migration: 00017_reconcile_schema.sql
-- Add missing tables from schema.sql to migrations
-- ============================================

-- This migration adds 20 tables that exist in schema.sql but were missing from migrations
-- Tables are added in dependency order to respect foreign key constraints

-- ============================================
-- GAMIFICATION & BADGES (foundational tables)
-- ============================================

-- Badge definitions (referenced by user_badges, voting_sessions)
CREATE TABLE IF NOT EXISTS badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  description TEXT NOT NULL,
  icon_url TEXT,

  -- Badge categorization
  type TEXT CHECK (type IN ('activity', 'special', 'monthly', 'achievement')),
  tier TEXT CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')),

  -- Requirements and rewards
  requirements JSONB NOT NULL, -- JSON object with criteria
  points_value INTEGER DEFAULT 0,
  xp_reward INTEGER DEFAULT 0,

  -- Availability
  is_active BOOLEAN DEFAULT true,
  is_secret BOOLEAN DEFAULT false, -- Hidden until earned

  created_at TIMESTAMP DEFAULT NOW()
);

-- User badges (junction table)
CREATE TABLE IF NOT EXISTS user_badges (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  badge_id UUID REFERENCES badges(id) ON DELETE CASCADE,
  awarded_at TIMESTAMP DEFAULT NOW(),
  awarded_for TEXT, -- Optional context (e.g., "Hot thread about climate change")
  PRIMARY KEY (user_id, badge_id)
);

-- XP transactions log
CREATE TABLE IF NOT EXISTS xp_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  reason TEXT NOT NULL,
  source_type TEXT CHECK (source_type IN (
    'post_created', 'comment_created', 'received_upvote',
    'badge_earned', 'daily_login', 'moderation_action'
  )),
  source_id UUID, -- Reference to the source (thread_id, badge_id, etc.)
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- MODERATION SYSTEM
-- ============================================

-- Moderators table (referenced by multiple tables)
CREATE TABLE IF NOT EXISTS moderators (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,

  -- Election details
  elected_at TIMESTAMP DEFAULT NOW(),
  votes_received INTEGER NOT NULL,
  term_starts_at TIMESTAMP DEFAULT NOW(),
  term_ends_at TIMESTAMP,

  -- Status
  is_active BOOLEAN DEFAULT true,
  removal_reason TEXT,

  -- Stats
  actions_count INTEGER DEFAULT 0,
  warnings_issued INTEGER DEFAULT 0,

  CONSTRAINT unique_user_category
    UNIQUE(user_id, category_id)
);

-- Moderation actions log
CREATE TABLE IF NOT EXISTS moderation_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  moderator_id UUID REFERENCES users(id) ON DELETE CASCADE,
  target_user_id UUID REFERENCES users(id),
  target_content_id UUID,
  content_type TEXT CHECK (content_type IN ('thread', 'comment', 'user')),
  action TEXT CHECK (action IN (
    'remove_post', 'lock_thread', 'pin_thread', 'unpin_thread',
    'warn_user', 'ban_user', 'unban_user', 'shadowban_user'
  )),
  reason TEXT,
  metadata JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

-- User warnings
CREATE TABLE IF NOT EXISTS user_warnings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  moderator_id UUID REFERENCES users(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id),
  reason TEXT NOT NULL,
  severity TEXT CHECK (severity IN ('minor', 'moderate', 'severe')),
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Moderator elections
CREATE TABLE IF NOT EXISTS moderator_elections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,

  -- Election type and target
  election_type TEXT CHECK (election_type IN ('new', 'removal')),
  target_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  initiated_by UUID REFERENCES users(id),

  -- Voting
  votes_for INTEGER DEFAULT 0,
  votes_against INTEGER DEFAULT 0,
  eligible_voter_count INTEGER DEFAULT 0,

  -- Status
  status TEXT CHECK (status IN ('active', 'completed', 'cancelled')),
  winner_id UUID REFERENCES users(id),

  -- Timestamps
  started_at TIMESTAMP DEFAULT NOW(),
  ends_at TIMESTAMP NOT NULL,
  completed_at TIMESTAMP
);

-- Election votes
CREATE TABLE IF NOT EXISTS election_votes (
  election_id UUID REFERENCES moderator_elections(id) ON DELETE CASCADE,
  voter_id UUID REFERENCES users(id) ON DELETE CASCADE,
  vote TEXT CHECK (vote IN ('for', 'against')),
  voted_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (election_id, voter_id)
);

-- Moderator bot reports (cross-category)
CREATE TABLE IF NOT EXISTS moderator_bot_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reported_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  moderator_id UUID REFERENCES users(id) ON DELETE CASCADE,
  category_context TEXT, -- Which category they moderate
  reason TEXT NOT NULL,
  evidence JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(reported_user_id, moderator_id)
);

-- ============================================
-- BOT DETECTION & SPAM FIGHTING
-- ============================================

-- Spam patterns for detection
CREATE TABLE IF NOT EXISTS spam_patterns (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pattern_name TEXT NOT NULL,
  pattern_type TEXT CHECK (pattern_type IN ('content', 'behavior', 'timing')),
  pattern_regex TEXT,
  weight DECIMAL(3,2) DEFAULT 1.0,
  match_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Spam detection logs
CREATE TABLE IF NOT EXISTS spam_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content_type TEXT CHECK (content_type IN ('thread', 'comment')),
  content_id UUID NOT NULL,
  spam_score DECIMAL(5,2) NOT NULL,
  patterns_matched JSONB,
  action_taken TEXT CHECK (action_taken IN ('allow', 'flag', 'queue_review', 'block')),
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- VOTING SESSIONS & POLLS
-- ============================================

-- Monthly voting sessions
CREATE TABLE IF NOT EXISTS voting_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  month DATE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,

  -- Special badge for participants
  participation_badge_id UUID REFERENCES badges(id),
  winner_badge_id UUID REFERENCES badges(id),

  -- Status
  status TEXT CHECK (status IN ('pending', 'active', 'completed')),

  -- Results
  total_votes INTEGER DEFAULT 0,
  winner_id UUID REFERENCES users(id),

  -- Timestamps
  starts_at TIMESTAMP,
  ends_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Voting session entries
CREATE TABLE IF NOT EXISTS voting_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID REFERENCES voting_sessions(id) ON DELETE CASCADE,
  nominee_id UUID REFERENCES users(id) ON DELETE CASCADE,
  nomination_reason TEXT,
  votes_received INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Individual votes in sessions
CREATE TABLE IF NOT EXISTS session_votes (
  session_id UUID REFERENCES voting_sessions(id) ON DELETE CASCADE,
  voter_id UUID REFERENCES users(id) ON DELETE CASCADE,
  entry_id UUID REFERENCES voting_entries(id) ON DELETE CASCADE,
  voted_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (session_id, voter_id)
);

-- ============================================
-- AI SUMMARIES
-- ============================================

-- Daily thread summaries
CREATE TABLE IF NOT EXISTS thread_summaries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  thread_id UUID REFERENCES threads(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id),
  summary_text TEXT NOT NULL,
  key_points JSONB, -- Array of key discussion points
  sentiment_score DECIMAL(3,2), -- -1 to 1
  engagement_score DECIMAL(5,2),
  generated_at TIMESTAMP DEFAULT NOW(),
  summary_date DATE DEFAULT CURRENT_DATE
);

-- Category daily digests
CREATE TABLE IF NOT EXISTS category_digests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  digest_date DATE NOT NULL,
  top_threads JSONB NOT NULL, -- Array of thread IDs and summaries
  total_posts INTEGER DEFAULT 0,
  total_comments INTEGER DEFAULT 0,
  active_users INTEGER DEFAULT 0,
  trending_topics JSONB, -- Array of trending keywords
  generated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(category_id, digest_date)
);

-- ============================================
-- REPORTING & ANALYTICS
-- ============================================

-- Content reports (for threads/comments)
CREATE TABLE IF NOT EXISTS content_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content_type TEXT CHECK (content_type IN ('thread', 'comment')),
  content_id UUID NOT NULL,
  report_type TEXT CHECK (report_type IN (
    'spam', 'harassment', 'hate_speech', 'misinformation',
    'low_effort', 'off_topic', 'other'
  )),
  reason TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewing', 'resolved', 'dismissed')),
  moderator_id UUID REFERENCES users(id),
  moderator_notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  resolved_at TIMESTAMP
);

-- User activity tracking
CREATE TABLE IF NOT EXISTS user_activity (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  activity_type TEXT CHECK (activity_type IN (
    'login', 'logout', 'post_created', 'comment_created',
    'vote_cast', 'report_submitted', 'badge_earned'
  )),
  metadata JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- NOTIFICATIONS
-- ============================================

-- User notifications
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  type TEXT CHECK (type IN (
    'reply', 'mention', 'upvote', 'badge_earned',
    'moderator_action', 'election_started', 'warning_received'
  )),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  link TEXT, -- URL to relevant content
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Notification preferences
CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE PRIMARY KEY,
  email_enabled BOOLEAN DEFAULT true,
  push_enabled BOOLEAN DEFAULT false,

  -- Granular preferences
  replies BOOLEAN DEFAULT true,
  mentions BOOLEAN DEFAULT true,
  upvotes BOOLEAN DEFAULT false,
  badges BOOLEAN DEFAULT true,
  moderator_actions BOOLEAN DEFAULT true,
  elections BOOLEAN DEFAULT true,
  digests BOOLEAN DEFAULT true,

  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- INDEXES FOR NEW TABLES
-- ============================================

-- Moderation indexes
CREATE INDEX IF NOT EXISTS idx_moderators_user ON moderators(user_id);
CREATE INDEX IF NOT EXISTS idx_moderators_category ON moderators(category_id);
CREATE INDEX IF NOT EXISTS idx_moderation_logs_moderator ON moderation_logs(moderator_id);
CREATE INDEX IF NOT EXISTS idx_moderation_logs_target_user ON moderation_logs(target_user_id);

-- Notification indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = false;

-- Badge indexes
CREATE INDEX IF NOT EXISTS idx_user_badges_user ON user_badges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_badge ON user_badges(badge_id);

-- Voting indexes
CREATE INDEX IF NOT EXISTS idx_voting_sessions_status ON voting_sessions(status);
CREATE INDEX IF NOT EXISTS idx_voting_entries_session ON voting_entries(session_id);
CREATE INDEX IF NOT EXISTS idx_session_votes_session ON session_votes(session_id);

-- Report indexes
CREATE INDEX IF NOT EXISTS idx_content_reports_status ON content_reports(status);
CREATE INDEX IF NOT EXISTS idx_content_reports_reporter ON content_reports(reporter_id);

-- Activity indexes
CREATE INDEX IF NOT EXISTS idx_user_activity_user ON user_activity(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_created ON user_activity(created_at DESC);

-- Summary indexes
CREATE INDEX IF NOT EXISTS idx_thread_summaries_thread ON thread_summaries(thread_id);
CREATE INDEX IF NOT EXISTS idx_category_digests_category_date ON category_digests(category_id, digest_date DESC);