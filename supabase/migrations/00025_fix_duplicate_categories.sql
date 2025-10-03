-- Fix duplicate categories by keeping only one instance of each
-- and adding unique constraint to prevent future duplicates

-- First, identify and remove duplicates (keeping the one with lowest id)
DELETE FROM categories a
USING categories b
WHERE a.slug = b.slug
  AND a.id > b.id;

-- Add unique constraint on slug to prevent future duplicates
ALTER TABLE categories
ADD CONSTRAINT categories_slug_unique UNIQUE (slug);

-- Also ensure parent_id + slug combination is unique (for subcategories)
-- First drop the existing constraint if it exists
ALTER TABLE categories
DROP CONSTRAINT IF EXISTS categories_parent_id_slug_key;

-- Then recreate it properly
ALTER TABLE categories
ADD CONSTRAINT categories_parent_slug_unique UNIQUE (parent_id, slug);

-- Update the RPC function for incrementing subscribers if it doesn't exist
CREATE OR REPLACE FUNCTION increment_category_subscribers(
  category_id UUID,
  increment INTEGER
)
RETURNS VOID AS $$
BEGIN
  UPDATE categories
  SET subscriber_count = GREATEST(0, COALESCE(subscriber_count, 0) + increment)
  WHERE id = category_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION increment_category_subscribers TO authenticated;
GRANT EXECUTE ON FUNCTION increment_category_subscribers TO anon;

-- Recalculate accurate post counts for each category
UPDATE categories c
SET post_count = (
  SELECT COUNT(*)
  FROM threads t
  WHERE t.category_id = c.id
    AND t.is_removed = false
    AND t.is_spam = false
);

-- Recalculate accurate subscriber counts
UPDATE categories c
SET subscriber_count = (
  SELECT COUNT(*)
  FROM category_subscriptions cs
  WHERE cs.category_id = c.id
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_categories_slug ON categories(slug);
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_categories_is_active ON categories(is_active);

-- Update metadata
INSERT INTO schema_migrations (version, description, applied_at)
VALUES (25, 'Fix duplicate categories and add constraints', NOW())
ON CONFLICT (version) DO NOTHING;