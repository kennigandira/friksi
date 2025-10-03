-- ============================================
-- Migration: Add wilson_score columns
-- Purpose: Add computed wilson_score columns to comments and threads tables
-- Issue: Fix "column comments.wilson_score does not exist" error
-- ============================================

-- Add wilson_score as a generated column to comments table
ALTER TABLE comments
ADD COLUMN IF NOT EXISTS wilson_score NUMERIC
GENERATED ALWAYS AS (calculate_wilson_score(upvotes, downvotes)) STORED;

-- Add wilson_score as a generated column to threads table
ALTER TABLE threads
ADD COLUMN IF NOT EXISTS wilson_score NUMERIC
GENERATED ALWAYS AS (calculate_wilson_score(upvotes, downvotes)) STORED;

-- Create indexes for better query performance when sorting by wilson_score
CREATE INDEX IF NOT EXISTS idx_comments_wilson_score ON comments(wilson_score DESC);
CREATE INDEX IF NOT EXISTS idx_threads_wilson_score ON threads(wilson_score DESC);

-- Also create composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_comments_thread_wilson ON comments(thread_id, wilson_score DESC);
CREATE INDEX IF NOT EXISTS idx_threads_category_wilson ON threads(category_id, wilson_score DESC);

-- ============================================
-- Verification
-- ============================================
-- After this migration, you can verify with:
-- SELECT column_name, data_type, is_generated
-- FROM information_schema.columns
-- WHERE table_name IN ('comments', 'threads')
-- AND column_name = 'wilson_score';