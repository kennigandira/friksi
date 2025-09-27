-- ============================================
-- MIGRATION: Update Bot Detection with Strikes System
-- Adds 3-strike system and captcha tracking
-- ============================================

-- Add missing columns to bot_detection table
ALTER TABLE bot_detection
ADD COLUMN IF NOT EXISTS strikes INTEGER DEFAULT 0 CHECK (strikes >= 0 AND strikes <= 3),
ADD COLUMN IF NOT EXISTS failed_captcha_count INTEGER DEFAULT 0;

-- Add constraint for bot score range
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_bot_score_range') THEN
        ALTER TABLE bot_detection ADD CONSTRAINT check_bot_score_range CHECK (bot_score >= 0 AND bot_score <= 100);
    END IF;
END $$;

-- Update bot_reports table to include reviewed_by column
ALTER TABLE bot_reports
ADD COLUMN IF NOT EXISTS reviewed_by UUID REFERENCES users(id);

-- Add missing unique constraint to bot_reports (skip if already exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_reporter_per_user') THEN
        ALTER TABLE bot_reports ADD CONSTRAINT unique_reporter_per_user UNIQUE(reported_user_id, reporter_id);
    END IF;
END $$;

-- Skip moderator_bot_reports and spam_patterns updates until tables are created
/*
-- Update moderator_bot_reports to reference category_id instead of text
ALTER TABLE moderator_bot_reports
DROP COLUMN IF EXISTS category_context,
ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES categories(id);

-- Add constraint to moderator_bot_reports
ALTER TABLE moderator_bot_reports
ADD CONSTRAINT unique_moderator_report UNIQUE(reported_user_id, moderator_id);

-- Add missing spam pattern columns
ALTER TABLE spam_patterns
ADD COLUMN IF NOT EXISTS false_positive_count INTEGER DEFAULT 0;

-- Update constraints for spam patterns
ALTER TABLE spam_patterns
ADD CONSTRAINT check_weight_positive CHECK (weight > 0);
*/
