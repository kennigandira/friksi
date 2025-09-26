-- ============================================
-- MIGRATION: Update Users with Ban Management
-- Adds ban expiration and reason tracking
-- ============================================

-- Add ban management columns to users table
ALTER TABLE users
ADD COLUMN IF NOT EXISTS ban_expires_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS ban_reason TEXT;

-- Remove existing is_bot and bot_flags columns if they exist
-- (these will be handled by the bot_detection table as per plan)
ALTER TABLE users
DROP COLUMN IF EXISTS is_bot,
DROP COLUMN IF EXISTS bot_flags;

-- Add constraints to ensure valid data
ALTER TABLE users
ADD CONSTRAINT check_level_range CHECK (level >= 1 AND level <= 5),
ADD CONSTRAINT check_xp_positive CHECK (xp >= 0),
ADD CONSTRAINT check_trust_score_range CHECK (trust_score >= 0 AND trust_score <= 100);