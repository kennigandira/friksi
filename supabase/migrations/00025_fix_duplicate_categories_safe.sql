-- Safely fix duplicate categories by merging them

-- Step 1: Create temporary table to track category mappings
CREATE TEMP TABLE category_mappings AS
SELECT
  slug,
  MIN(id) as keep_id,
  array_agg(id ORDER BY id) as all_ids
FROM categories
GROUP BY slug
HAVING COUNT(*) > 1;

-- Step 2: Update threads to point to the category we're keeping
UPDATE threads t
SET category_id = cm.keep_id
FROM category_mappings cm
WHERE t.category_id = ANY(cm.all_ids)
  AND t.category_id != cm.keep_id;

-- Step 3: Update category_subscriptions to point to the category we're keeping
-- First remove duplicates in subscriptions
DELETE FROM category_subscriptions cs1
USING category_subscriptions cs2, category_mappings cm
WHERE cs1.category_id = ANY(cm.all_ids)
  AND cs2.category_id = cm.keep_id
  AND cs1.user_id = cs2.user_id
  AND cs1.category_id != cm.keep_id;

-- Then update remaining subscriptions
UPDATE category_subscriptions cs
SET category_id = cm.keep_id
FROM category_mappings cm
WHERE cs.category_id = ANY(cm.all_ids)
  AND cs.category_id != cm.keep_id;

-- Step 4: Update other related tables
UPDATE moderators m
SET category_id = cm.keep_id
FROM category_mappings cm
WHERE m.category_id = ANY(cm.all_ids)
  AND m.category_id != cm.keep_id;

UPDATE moderator_elections me
SET category_id = cm.keep_id
FROM category_mappings cm
WHERE me.category_id = ANY(cm.all_ids)
  AND me.category_id != cm.keep_id;

UPDATE category_digests cd
SET category_id = cm.keep_id
FROM category_mappings cm
WHERE cd.category_id = ANY(cm.all_ids)
  AND cd.category_id != cm.keep_id;

UPDATE category_rules cr
SET category_id = cm.keep_id
FROM category_mappings cm
WHERE cr.category_id = ANY(cm.all_ids)
  AND cr.category_id != cm.keep_id;

UPDATE thread_summaries ts
SET category_id = cm.keep_id
FROM category_mappings cm
WHERE ts.category_id = ANY(cm.all_ids)
  AND ts.category_id != cm.keep_id;

UPDATE user_warnings uw
SET category_id = cm.keep_id
FROM category_mappings cm
WHERE uw.category_id = ANY(cm.all_ids)
  AND uw.category_id != cm.keep_id;

-- Step 5: Now safely delete duplicate categories
DELETE FROM categories c
USING category_mappings cm
WHERE c.id = ANY(cm.all_ids)
  AND c.id != cm.keep_id;

-- Step 6: Add unique constraint to prevent future duplicates (if not exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'categories_slug_unique'
  ) THEN
    ALTER TABLE categories
    ADD CONSTRAINT categories_slug_unique UNIQUE (slug);
  END IF;
END $$;

-- Step 7: Create or replace the RPC function for incrementing subscribers
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

-- Step 8: Recalculate accurate counts
UPDATE categories c
SET post_count = (
  SELECT COUNT(*)
  FROM threads t
  WHERE t.category_id = c.id
    AND t.is_removed = false
    AND t.is_spam = false
);

UPDATE categories c
SET subscriber_count = (
  SELECT COUNT(*)
  FROM category_subscriptions cs
  WHERE cs.category_id = c.id
);

-- Step 9: Add helpful indexes
CREATE INDEX IF NOT EXISTS idx_categories_slug ON categories(slug);
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_categories_is_active ON categories(is_active);
CREATE INDEX IF NOT EXISTS idx_threads_category_id ON threads(category_id);

-- Update metadata
INSERT INTO schema_migrations (version, description, applied_at)
VALUES (25, 'Safely fix duplicate categories and add constraints', NOW())
ON CONFLICT (version) DO UPDATE SET
  description = EXCLUDED.description,
  applied_at = EXCLUDED.applied_at;