-- ============================================
-- INITIAL SCHEMA MIGRATION FOR FRIKSI
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
CREATE TABLE IF NOT EXISTS users (
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
CREATE TABLE IF NOT EXISTS trust_factors (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE PRIMARY KEY,
  verified_email BOOLEAN DEFAULT false,
  verified_phone BOOLEAN DEFAULT false,
  positive_interactions INTEGER DEFAULT 0,
  negative_interactions INTEGER DEFAULT 0,
  moderator_warnings INTEGER DEFAULT 0,
  successful_reports INTEGER DEFAULT 0,
  false_reports INTEGER DEFAULT 0,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- View for trust factors with calculated account age
CREATE OR REPLACE VIEW trust_factors_with_age AS
SELECT 
  tf.*,
  EXTRACT(DAY FROM NOW() - u.created_at)::INTEGER AS account_age_days
FROM trust_factors tf
JOIN users u ON tf.user_id = u.id;

-- User sessions for authentication (optional with Supabase Auth)
CREATE TABLE IF NOT EXISTS user_sessions (
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
CREATE TABLE IF NOT EXISTS categories (
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

-- User subscriptions to categories
CREATE TABLE IF NOT EXISTS category_subscriptions (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  notification_enabled BOOLEAN DEFAULT true,
  subscribed_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (user_id, category_id)
);

-- Category rules
CREATE TABLE IF NOT EXISTS category_rules (
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
CREATE TABLE IF NOT EXISTS threads (
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
CREATE TABLE IF NOT EXISTS thread_votes (
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
CREATE TABLE IF NOT EXISTS comments (
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
CREATE TABLE IF NOT EXISTS comment_votes (
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
CREATE TABLE IF NOT EXISTS bot_detection (
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
CREATE TABLE IF NOT EXISTS bot_reports (
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

-- Basic indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_level ON users(level);
CREATE INDEX IF NOT EXISTS idx_categories_slug ON categories(slug);
CREATE INDEX IF NOT EXISTS idx_categories_parent ON categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_threads_user ON threads(user_id);
CREATE INDEX IF NOT EXISTS idx_threads_category ON threads(category_id);
CREATE INDEX IF NOT EXISTS idx_threads_hot ON threads(is_hot, hot_score DESC);
CREATE INDEX IF NOT EXISTS idx_comments_thread ON comments(thread_id);
CREATE INDEX IF NOT EXISTS idx_comments_path_gist ON comments USING GIST (path);
CREATE INDEX IF NOT EXISTS idx_bot_detection_score ON bot_detection(bot_score);
CREATE INDEX IF NOT EXISTS idx_thread_votes_thread ON thread_votes(thread_id);
CREATE INDEX IF NOT EXISTS idx_comment_votes_comment ON comment_votes(comment_id);