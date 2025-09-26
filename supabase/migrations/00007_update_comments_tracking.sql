-- ============================================
-- MIGRATION: Update Comments with Constraints and Edit Tracking
-- Adds edit counting, moderation tracking, and depth constraints
-- ============================================

-- Add missing columns to comments table
ALTER TABLE comments
ADD COLUMN IF NOT EXISTS edit_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS removed_by UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS removed_at TIMESTAMP;

-- Add content length constraints
ALTER TABLE comments
ADD CONSTRAINT check_content_length CHECK (LENGTH(content) BETWEEN 1 AND 5000);

-- Add depth constraint (max 10 levels of nesting)
ALTER TABLE comments
ADD CONSTRAINT check_depth_limit CHECK (depth >= 0 AND depth <= 10);

-- Add constraints for vote counts
ALTER TABLE comments
ADD CONSTRAINT check_upvotes_positive CHECK (upvotes >= 0),
ADD CONSTRAINT check_downvotes_positive CHECK (downvotes >= 0);

-- Update the existing calculate_comment_path function to enforce depth limit
CREATE OR REPLACE FUNCTION calculate_comment_path()
RETURNS TRIGGER AS $$
DECLARE
    parent_path LTREE;
    parent_depth INTEGER;
BEGIN
    IF NEW.parent_id IS NULL THEN
        NEW.path = NEW.id::TEXT::LTREE;
        NEW.depth = 0;
    ELSE
        SELECT path, depth INTO parent_path, parent_depth
        FROM comments
        WHERE id = NEW.parent_id;

        IF parent_depth >= 10 THEN
            RAISE EXCEPTION 'Maximum comment nesting depth (10) exceeded';
        END IF;

        NEW.path = parent_path || NEW.id::TEXT;
        NEW.depth = parent_depth + 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;