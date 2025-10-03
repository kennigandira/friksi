-- ============================================
-- MIGRATION: Update Categories with LTREE Path Tracking
-- Adds hierarchical path calculation and access controls
-- ============================================

-- Add missing columns to categories table
ALTER TABLE categories
ADD COLUMN IF NOT EXISTS path LTREE,
ADD COLUMN IF NOT EXISTS depth INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_locked BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS min_level_to_post INTEGER DEFAULT 2,
ADD COLUMN IF NOT EXISTS min_level_to_comment INTEGER DEFAULT 2;

-- Function to auto-calculate category path (similar to comments)
CREATE OR REPLACE FUNCTION calculate_category_path()
RETURNS TRIGGER AS $$
DECLARE
    parent_path LTREE;
    parent_depth INTEGER;
BEGIN
    IF NEW.parent_id IS NULL THEN
        -- Replace hyphens with underscores for LTREE compatibility
        NEW.path = REPLACE(NEW.slug, '-', '_')::LTREE;
        NEW.depth = 0;
    ELSE
        SELECT path, depth INTO parent_path, parent_depth
        FROM categories
        WHERE id = NEW.parent_id;

        -- Replace hyphens with underscores for LTREE compatibility
        NEW.path = parent_path || REPLACE(NEW.slug, '-', '_')::TEXT;
        NEW.depth = parent_depth + 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-calculating category paths
CREATE TRIGGER set_category_path BEFORE INSERT OR UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION calculate_category_path();

-- Update existing categories to calculate their paths
-- Start with root categories (no parent)
UPDATE categories
SET path = REPLACE(slug, '-', '_')::LTREE, depth = 0
WHERE parent_id IS NULL;

-- Update child categories recursively
WITH RECURSIVE category_hierarchy AS (
    -- Base case: root categories
    SELECT id, parent_id, slug, REPLACE(slug, '-', '_')::LTREE as path, 0 as depth
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    -- Recursive case: child categories
    SELECT c.id, c.parent_id, c.slug,
           (ch.path || REPLACE(c.slug, '-', '_')::TEXT)::LTREE as path,
           ch.depth + 1 as depth
    FROM categories c
    INNER JOIN category_hierarchy ch ON c.parent_id = ch.id
)
UPDATE categories
SET path = ch.path, depth = ch.depth
FROM category_hierarchy ch
WHERE categories.id = ch.id;

-- Add GIST index for efficient LTREE queries
CREATE INDEX IF NOT EXISTS idx_categories_path_gist ON categories USING GIST (path);

-- Add constraint to ensure unique rule numbers per category
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_rule_number') THEN
        ALTER TABLE category_rules ADD CONSTRAINT unique_rule_number UNIQUE(category_id, rule_number);
    END IF;
END $$;
