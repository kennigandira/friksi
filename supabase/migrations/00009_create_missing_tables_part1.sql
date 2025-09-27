-- ============================================
-- MIGRATION: Create Missing Tables Part 1 (TEMPORARILY DISABLED)
-- Edit History, Enhanced Moderation, and Temporary Bans
-- Need to create base tables first (moderators, elections, etc.)
-- ============================================

/*

-- Thread edit history
CREATE TABLE IF NOT EXISTS thread_edits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    thread_id UUID REFERENCES threads(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    previous_title TEXT,
    previous_content TEXT,
    edited_at TIMESTAMP DEFAULT NOW()
);

-- Update moderators table with missing columns
ALTER TABLE moderators
ADD COLUMN IF NOT EXISTS removed_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS posts_removed INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS bans_issued INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS can_pin BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS can_remove_posts BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS can_ban_users BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS max_ban_days INTEGER DEFAULT 7;

-- Add missing election columns
ALTER TABLE moderator_elections
ADD COLUMN IF NOT EXISTS actual_voter_count INTEGER DEFAULT 0;

-- Add missing status value to elections
ALTER TABLE moderator_elections
DROP CONSTRAINT IF EXISTS moderator_elections_status_check,
ADD CONSTRAINT moderator_elections_status_check
    CHECK (status IN ('pending', 'active', 'completed', 'cancelled'));

-- Election candidates table
CREATE TABLE IF NOT EXISTS election_candidates (
    election_id UUID REFERENCES moderator_elections(id) ON DELETE CASCADE,
    candidate_id UUID REFERENCES users(id) ON DELETE CASCADE,
    nomination_text TEXT,
    votes_received INTEGER DEFAULT 0,
    nominated_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (election_id, candidate_id)
);

-- Enhanced moderation logs with more action types
ALTER TABLE moderation_logs
DROP CONSTRAINT IF EXISTS moderation_logs_action_check,
ADD CONSTRAINT moderation_logs_action_check CHECK (action IN (
    'remove_post', 'restore_post', 'lock_thread', 'unlock_thread',
    'pin_thread', 'unpin_thread', 'warn_user', 'ban_user',
    'unban_user', 'shadowban_user', 'edit_category_rules'
));

-- Add missing columns to moderation_logs
ALTER TABLE moderation_logs
ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES categories(id);

-- User warnings with points system
ALTER TABLE user_warnings
ADD COLUMN IF NOT EXISTS points INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS acknowledged BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS acknowledged_at TIMESTAMP;

-- Temporary bans table
CREATE TABLE IF NOT EXISTS temporary_bans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    moderator_id UUID REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id), -- NULL for site-wide ban
    reason TEXT NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    lifted_at TIMESTAMP,
    lifted_by UUID REFERENCES users(id),
    lift_reason TEXT
);
*/
