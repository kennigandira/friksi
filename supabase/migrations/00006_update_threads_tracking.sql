-- ============================================
-- MIGRATION: Update Threads with Edit Tracking and Activity
-- Adds edit counting, activity timestamps, and moderation tracking
-- ============================================

-- Add missing columns to threads table
ALTER TABLE threads
ADD COLUMN IF NOT EXISTS edit_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_activity_at TIMESTAMP DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS removed_by UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS removed_at TIMESTAMP;

-- Add content length constraints
ALTER TABLE threads
ADD CONSTRAINT check_title_length CHECK (LENGTH(title) BETWEEN 5 AND 200),
ADD CONSTRAINT check_content_length CHECK (LENGTH(content) >= 40);

-- Add constraints for vote counts
ALTER TABLE threads
ADD CONSTRAINT check_upvotes_positive CHECK (upvotes >= 0),
ADD CONSTRAINT check_downvotes_positive CHECK (downvotes >= 0),
ADD CONSTRAINT check_comment_count_positive CHECK (comment_count >= 0),
ADD CONSTRAINT check_view_count_positive CHECK (view_count >= 0),
ADD CONSTRAINT check_spam_score_range CHECK (spam_score >= 0 AND spam_score <= 100);

-- Update existing threads to have last_activity_at set to created_at if null
UPDATE threads
SET last_activity_at = created_at
WHERE last_activity_at IS NULL;