-- ============================================
-- MIGRATION: Create Missing Tables Part 2 (TEMPORARILY DISABLED)
-- Polls, Level Unlocks, and Analytics
-- ============================================

/*

-- Enhanced badges with missing columns
ALTER TABLE badges
ADD COLUMN IF NOT EXISTS trust_bonus DECIMAL(3,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS max_awards INTEGER DEFAULT 1;

-- Update badge type constraint to include 'moderator' and 'diamond' tier
ALTER TABLE badges
DROP CONSTRAINT IF EXISTS badges_type_check,
ADD CONSTRAINT badges_type_check
    CHECK (type IN ('activity', 'special', 'monthly', 'achievement', 'moderator'));

ALTER TABLE badges
DROP CONSTRAINT IF EXISTS badges_tier_check,
ADD CONSTRAINT badges_tier_check
    CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum', 'diamond'));

-- Enhanced user_badges with awarded_by tracking
ALTER TABLE user_badges
DROP CONSTRAINT IF EXISTS user_badges_pkey,
ADD COLUMN IF NOT EXISTS id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
ADD COLUMN IF NOT EXISTS awarded_by TEXT CHECK (awarded_by IN ('system', 'moderator', 'election'));

-- Add new constraint for user_badges
ALTER TABLE user_badges
ADD CONSTRAINT unique_badge_per_context UNIQUE(user_id, badge_id, awarded_for);

-- Enhanced XP transactions with balance tracking
ALTER TABLE xp_transactions
ADD COLUMN IF NOT EXISTS balance_after INTEGER NOT NULL DEFAULT 0;

-- Update XP transaction source types
ALTER TABLE xp_transactions
DROP CONSTRAINT IF EXISTS xp_transactions_source_type_check,
ADD CONSTRAINT xp_transactions_source_type_check CHECK (source_type IN (
    'post_created', 'comment_created', 'received_upvote', 'gave_upvote',
    'badge_earned', 'daily_login', 'moderation_action', 'report_confirmed',
    'election_participation', 'monthly_bonus'
));

-- Level unlock notifications
CREATE TABLE IF NOT EXISTS level_unlocks (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    level INTEGER NOT NULL,
    unlocked_at TIMESTAMP DEFAULT NOW(),
    features_unlocked JSONB, -- Array of newly available features
    PRIMARY KEY (user_id, level)
);

-- Enhanced voting sessions
ALTER TABLE voting_sessions
ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES categories(id), -- NULL for site-wide
ADD COLUMN IF NOT EXISTS session_type TEXT CHECK (session_type IN ('user_of_month', 'best_thread', 'custom')),
ADD COLUMN IF NOT EXISTS runner_up_id UUID;

-- Update voting sessions month column to be unique
ALTER TABLE voting_sessions
ADD CONSTRAINT unique_monthly_session UNIQUE(month);

-- Enhanced voting entries for different entry types
ALTER TABLE voting_entries
DROP COLUMN IF EXISTS nominee_id,
ADD COLUMN IF NOT EXISTS entry_type TEXT CHECK (entry_type IN ('user', 'thread', 'comment')),
ADD COLUMN IF NOT EXISTS entry_id UUID NOT NULL, -- References user/thread/comment based on type
ADD COLUMN IF NOT EXISTS nominated_by UUID REFERENCES users(id);

-- General polls table
CREATE TABLE IF NOT EXISTS polls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    thread_id UUID REFERENCES threads(id) ON DELETE CASCADE,
    created_by UUID REFERENCES users(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    options JSONB NOT NULL, -- Array of {id, text} objects
    allow_multiple BOOLEAN DEFAULT false,
    closes_at TIMESTAMP,
    is_closed BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Poll votes table
CREATE TABLE IF NOT EXISTS poll_votes (
    poll_id UUID REFERENCES polls(id) ON DELETE CASCADE,
    voter_id UUID REFERENCES users(id) ON DELETE CASCADE,
    option_ids JSONB NOT NULL, -- Array of selected option IDs
    voted_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (poll_id, voter_id)
);
*/
