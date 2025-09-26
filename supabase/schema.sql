-- ============================================
-- COMPLETE DATABASE SCHEMA
-- Category-Based Discussion Platform with
-- Anti-Bot, Democratic Moderation & Gamification
-- ============================================

-- Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "ltree";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================
-- USERS & AUTHENTICATION
-- ============================================

-- Main users table with trust metrics
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT, -- Optional if using Supabase Auth
  avatar_url TEXT,
  bio TEXT,

  -- Level and experience system
  level INTEGER DEFAULT 1,
  xp INTEGER DEFAULT 0,

  -- Trust and reputation
  trust_score DECIMAL(5,2) DEFAULT 50.00,
  post_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  helpful_votes INTEGER DEFAULT 0,

  -- Account status
  account_status TEXT DEFAULT 'active'
    CHECK (account_status IN ('active', 'restricted', 'shadowbanned', 'banned')),

  -- Timestamps
  last_active TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Trust score calculation factors
CREATE TABLE trust_factors (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE PRIMARY KEY,
  account_age_days INTEGER GENERATED ALWAYS AS
    (EXTRACT(DAY FROM NOW() - (SELECT created_at FROM users WHERE id = user_id))) STORED,
  verified_email BOOLEAN DEFAULT false,
  verified_phone BOOLEAN DEFAULT false,
  positive_interactions INTEGER DEFAULT 0,
  negative_interactions INTEGER DEFAULT 0,
  moderator_warnings INTEGER DEFAULT 0,
  successful_reports INTEGER DEFAULT 0,
  false_reports INTEGER DEFAULT 0,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- User sessions for authentication
CREATE TABLE user_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  ip_address INET,
  user_agent TEXT,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- CATEGORIES (Self-referencing for hierarchy)
-- ============================================

-- Categories table with parent reference for subcategories
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  parent_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  description TEXT,
  icon_url TEXT,
  color TEXT DEFAULT '#6366f1',
  post_count INTEGER DEFAULT 0,
  subscriber_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  is_default BOOLEAN DEFAULT false, -- Show to all new users
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(parent_id, slug) -- Unique slug within same parent
);

-- Helper function to get category hierarchy path
CREATE OR REPLACE FUNCTION get_category_path(category_id UUID)
RETURNS TEXT AS $$
WITH RECURSIVE category_path AS (
  SELECT id, name, parent_id, name::TEXT as path
  FROM categories
  WHERE id = category_id

  UNION ALL

  SELECT c.id, c.name, c.parent_id,
         cp.path || ' > ' || c.name
  FROM categories c
  INNER JOIN category_path cp ON c.id = cp.parent_id
)
SELECT path FROM category_path WHERE parent_id IS NULL;
$$ LANGUAGE SQL;

-- User subscriptions to categories
CREATE TABLE category_subscriptions (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  notification_enabled BOOLEAN DEFAULT true,
  subscribed_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (user_id, category_id)
);

-- Category rules
CREATE TABLE category_rules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  rule_number INTEGER NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- THREADS/POSTS
-- ============================================

-- Main threads/posts table
CREATE TABLE threads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) NOT NULL,

  -- Content
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  content_html TEXT, -- Sanitized HTML version

  -- Metadata
  upvotes INTEGER DEFAULT 0,
  downvotes INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  view_count INTEGER DEFAULT 0,

  -- Scoring for hot threads
  hot_score DECIMAL(10,4) DEFAULT 0,
  is_hot BOOLEAN DEFAULT false,

  -- Moderation
  is_pinned BOOLEAN DEFAULT false,
  is_locked BOOLEAN DEFAULT false,
  is_removed BOOLEAN DEFAULT false,
  removal_reason TEXT,

  -- Spam detection
  spam_score DECIMAL(5,2) DEFAULT 0,
  is_spam BOOLEAN DEFAULT false,

  -- Timestamps
  edited_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Thread votes
CREATE TABLE thread_votes (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  thread_id UUID REFERENCES threads(id) ON DELETE CASCADE,
  vote_type TEXT NOT NULL CHECK (vote_type IN ('upvote', 'downvote')),
  voted_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (user_id, thread_id)
);

-- ============================================
-- COMMENTS (with LTREE for nested structure)
-- ============================================

-- Comments with hierarchical structure
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  thread_id UUID REFERENCES threads(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,

  -- Content
  content TEXT NOT NULL,
  content_html TEXT, -- Sanitized HTML

  -- Hierarchical path using LTREE
  path LTREE NOT NULL,
  depth INTEGER DEFAULT 0,

  -- Metadata
  upvotes INTEGER DEFAULT 0,
  downvotes INTEGER DEFAULT 0,

  -- Moderation
  is_removed BOOLEAN DEFAULT false,
  removal_reason TEXT,

  -- Timestamps
  edited_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Comment votes
CREATE TABLE comment_votes (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  vote_type TEXT NOT NULL CHECK (vote_type IN ('upvote', 'downvote')),
  voted_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (user_id, comment_id)
);

-- ============================================
-- BOT DETECTION & SPAM FIGHTING
-- ============================================

-- Bot detection tracking
CREATE TABLE bot_detection (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE PRIMARY KEY,
  short_post_count INTEGER DEFAULT 0,
  total_post_count INTEGER DEFAULT 0,
  short_post_percentage DECIMAL(5,2) GENERATED ALWAYS AS
    (CASE WHEN total_post_count > 0
      THEN (short_post_count::DECIMAL / total_post_count) * 100
      ELSE 0 END) STORED,
  bot_reports_count INTEGER DEFAULT 0,
  moderator_reports_count INTEGER DEFAULT 0,

  -- Behavioral metrics
  posting_frequency DECIMAL(5,2) DEFAULT 0, -- posts per hour
  duplicate_content_ratio DECIMAL(5,2) DEFAULT 0,

  -- Scoring
  bot_score DECIMAL(5,2) DEFAULT 0,
  is_bot BOOLEAN DEFAULT false,

  -- Timestamps
  last_evaluated TIMESTAMP DEFAULT NOW(),
  flagged_at TIMESTAMP,
  banned_at TIMESTAMP
);

-- User bot reports
CREATE TABLE bot_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reported_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  reporter_id UUID REFERENCES users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  evidence JSONB,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'confirmed', 'dismissed')),
  created_at TIMESTAMP DEFAULT NOW(),
  reviewed_at TIMESTAMP,
  UNIQUE(reported_user_id, reporter_id)
);

-- Moderator bot reports (cross-category)
CREATE TABLE moderator_bot_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reported_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  moderator_id UUID REFERENCES users(id) ON DELETE CASCADE,
  category_context TEXT, -- Which category they moderate
  reason TEXT NOT NULL,
  evidence JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(reported_user_id, moderator_id)
);

-- Spam patterns for detection
CREATE TABLE spam_patterns (
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
CREATE TABLE spam_logs (
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
-- MODERATION SYSTEM
-- ============================================

-- Moderators (up to 5 per category)
CREATE TABLE moderators (
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

-- Moderator elections
CREATE TABLE moderator_elections (
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
CREATE TABLE election_votes (
  election_id UUID REFERENCES moderator_elections(id) ON DELETE CASCADE,
  voter_id UUID REFERENCES users(id) ON DELETE CASCADE,
  vote TEXT CHECK (vote IN ('for', 'against')),
  voted_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (election_id, voter_id)
);

-- Moderation actions log
CREATE TABLE moderation_logs (
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
CREATE TABLE user_warnings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  moderator_id UUID REFERENCES users(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id),
  reason TEXT NOT NULL,
  severity TEXT CHECK (severity IN ('minor', 'moderate', 'severe')),
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- GAMIFICATION & BADGES
-- ============================================

-- Badge definitions
CREATE TABLE badges (
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
CREATE TABLE user_badges (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  badge_id UUID REFERENCES badges(id) ON DELETE CASCADE,
  awarded_at TIMESTAMP DEFAULT NOW(),
  awarded_for TEXT, -- Optional context (e.g., "Hot thread about climate change")
  PRIMARY KEY (user_id, badge_id)
);

-- XP transactions log
CREATE TABLE xp_transactions (
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
-- VOTING SESSIONS & POLLS
-- ============================================

-- Monthly voting sessions
CREATE TABLE voting_sessions (
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
CREATE TABLE voting_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID REFERENCES voting_sessions(id) ON DELETE CASCADE,
  nominee_id UUID REFERENCES users(id) ON DELETE CASCADE,
  nomination_reason TEXT,
  votes_received INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Individual votes in sessions
CREATE TABLE session_votes (
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
CREATE TABLE thread_summaries (
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
CREATE TABLE category_digests (
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
CREATE TABLE content_reports (
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
CREATE TABLE user_activity (
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
CREATE TABLE notifications (
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
CREATE TABLE notification_preferences (
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
-- INDEXES FOR PERFORMANCE
-- ============================================

-- User indexes
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_level ON users(level);
CREATE INDEX idx_users_status ON users(account_status);
CREATE INDEX idx_users_created_at ON users(created_at DESC);

-- Category indexes
CREATE INDEX idx_categories_slug ON categories(slug);
CREATE INDEX idx_categories_parent ON categories(parent_id);

-- Thread indexes
CREATE INDEX idx_threads_user ON threads(user_id);
CREATE INDEX idx_threads_category ON threads(category_id);
CREATE INDEX idx_threads_hot ON threads(is_hot, hot_score DESC);
CREATE INDEX idx_threads_created ON threads(created_at DESC);
CREATE INDEX idx_threads_not_removed ON threads(is_removed) WHERE is_removed = false;

-- Comment indexes (including LTREE)
CREATE INDEX idx_comments_thread ON comments(thread_id);
CREATE INDEX idx_comments_user ON comments(user_id);
CREATE INDEX idx_comments_parent ON comments(parent_id);
CREATE INDEX idx_comments_path_gist ON comments USING GIST (path);
CREATE INDEX idx_comments_created ON comments(created_at);

-- Bot detection indexes
CREATE INDEX idx_bot_detection_score ON bot_detection(bot_score);
CREATE INDEX idx_bot_detection_is_bot ON bot_detection(is_bot);
CREATE INDEX idx_bot_reports_reported_user ON bot_reports(reported_user_id);

-- Moderation indexes
CREATE INDEX idx_moderators_user ON moderators(user_id);
CREATE INDEX idx_moderators_category ON moderators(category_id);
CREATE INDEX idx_moderation_logs_moderator ON moderation_logs(moderator_id);
CREATE INDEX idx_moderation_logs_target_user ON moderation_logs(target_user_id);

-- Voting indexes
CREATE INDEX idx_thread_votes_thread ON thread_votes(thread_id);
CREATE INDEX idx_comment_votes_comment ON comment_votes(comment_id);

-- Notification indexes
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = false;

-- ============================================
-- FUNCTIONS AND TRIGGERS
-- ============================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_threads_updated_at BEFORE UPDATE ON threads
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Calculate hot score for threads
CREATE OR REPLACE FUNCTION calculate_hot_score(upvotes INTEGER, downvotes INTEGER, created_at TIMESTAMP)
RETURNS DECIMAL AS $$
DECLARE
    score INTEGER;
    order_val DECIMAL;
    sign_val INTEGER;
    seconds DECIMAL;
    epoch CONSTANT INTEGER := 1134028003; -- Reddit epoch
BEGIN
    score := upvotes - downvotes;
    order_val := LOG(10, GREATEST(ABS(score), 1));

    IF score > 0 THEN sign_val := 1;
    ELSIF score < 0 THEN sign_val := -1;
    ELSE sign_val := 0;
    END IF;

    seconds := EXTRACT(EPOCH FROM created_at) - epoch;
    RETURN sign_val * order_val + seconds / 45000;
END;
$$ LANGUAGE plpgsql;

-- Auto-calculate comment path
CREATE OR REPLACE FUNCTION calculate_comment_path()
RETURNS TRIGGER AS $$
DECLARE
    parent_path LTREE;
BEGIN
    IF NEW.parent_id IS NULL THEN
        NEW.path = NEW.id::TEXT::LTREE;
        NEW.depth = 0;
    ELSE
        SELECT path, depth INTO parent_path, NEW.depth
        FROM comments
        WHERE id = NEW.parent_id;

        NEW.path = parent_path || NEW.id::TEXT;
        NEW.depth = NEW.depth + 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_comment_path BEFORE INSERT ON comments
    FOR EACH ROW EXECUTE FUNCTION calculate_comment_path();

-- Increment post counts
CREATE OR REPLACE FUNCTION increment_post_counts()
RETURNS TRIGGER AS $$
BEGIN
    -- Update category post count
    UPDATE categories
    SET post_count = post_count + 1
    WHERE id = NEW.category_id;

    -- Update parent category post count if exists
    UPDATE categories
    SET post_count = post_count + 1
    WHERE id = (SELECT parent_id FROM categories WHERE id = NEW.category_id);

    -- Update user post count
    UPDATE users
    SET post_count = post_count + 1
    WHERE id = NEW.user_id;

    -- Update bot detection
    INSERT INTO bot_detection (user_id, total_post_count, short_post_count)
    VALUES (NEW.user_id, 1, CASE WHEN LENGTH(NEW.content) < 40 THEN 1 ELSE 0 END)
    ON CONFLICT (user_id) DO UPDATE SET
        total_post_count = bot_detection.total_post_count + 1,
        short_post_count = bot_detection.short_post_count +
            CASE WHEN LENGTH(NEW.content) < 40 THEN 1 ELSE 0 END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER increment_thread_counts AFTER INSERT ON threads
    FOR EACH ROW EXECUTE FUNCTION increment_post_counts();

-- ============================================
-- INITIAL DATA SEEDS
-- ============================================

-- Default categories
INSERT INTO categories (name, slug, description, is_default) VALUES
    ('General Discussion', 'general', 'General topics and conversations', true),
    ('Technology', 'tech', 'Technology news and discussions', true),
    ('Politics', 'politics', 'Political discussions and debates', false),
    ('Science', 'science', 'Scientific discoveries and research', true),
    ('Entertainment', 'entertainment', 'Movies, TV, music, and more', true),
    ('Sports', 'sports', 'Sports news and discussions', false);

-- Example subcategories (using parent_id)
INSERT INTO categories (name, slug, description, parent_id)
SELECT 'Programming', 'programming', 'Software development discussions', id
FROM categories WHERE slug = 'tech';

INSERT INTO categories (name, slug, description, parent_id)
SELECT 'Web Development', 'webdev', 'Frontend, backend, and full-stack development', id
FROM categories WHERE slug = 'programming';

INSERT INTO categories (name, slug, description, parent_id)
SELECT 'Mobile Development', 'mobile', 'iOS, Android, and cross-platform development', id
FROM categories WHERE slug = 'programming';

-- Default badges
INSERT INTO badges (name, description, type, tier, requirements, points_value, xp_reward) VALUES
    ('First Post', 'Created your first thread', 'achievement', 'bronze',
     '{"posts": 1}', 10, 10),
    ('Active Contributor', 'Posted 10 times', 'activity', 'silver',
     '{"posts": 10}', 25, 25),
    ('Hot Thread Creator', 'Created a hot thread', 'special', 'gold',
     '{"hot_threads": 1}', 100, 100),
    ('Helpful Member', 'Received 50 helpful votes', 'achievement', 'silver',
     '{"helpful_votes": 50}', 50, 50),
    ('Spam Fighter', 'Successfully reported 10 spam posts', 'special', 'silver',
     '{"successful_reports": 10}', 50, 50),
    ('Trusted Member', 'Achieved trust score of 80+', 'achievement', 'platinum',
     '{"trust_score": 80}', 200, 200);

-- Default spam patterns
INSERT INTO spam_patterns (pattern_name, pattern_type, pattern_regex, weight) VALUES
    ('Repeated Characters', 'content', '(.)\\1{10,}', 1.5),
    ('Excessive Links', 'content', '(https?://[^\\s]+){3,}', 2.0),
    ('Crypto Scams', 'content', '(?:bitcoin|ethereum|nft).*(?:free|giveaway|click)', 3.0),
    ('All Caps', 'content', '^[A-Z\\s]{20,}$', 1.2);

-- ============================================
-- MAINTENANCE QUERIES
-- ============================================

-- Clean up old sessions
-- Run periodically (e.g., daily via cron)
-- DELETE FROM user_sessions WHERE expires_at < NOW();

-- Update hot threads
-- Run every hour
-- UPDATE threads
-- SET hot_score = calculate_hot_score(upvotes, downvotes, created_at),
--     is_hot = (calculate_hot_score(upvotes, downvotes, created_at) > 5)
-- WHERE created_at > NOW() - INTERVAL '7 days';

-- Archive old notifications
-- Run monthly
-- DELETE FROM notifications
-- WHERE created_at < NOW() - INTERVAL '90 days'
-- AND is_read = true;
