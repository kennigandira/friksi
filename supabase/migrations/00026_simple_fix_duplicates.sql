-- Simple approach to fix duplicate categories
-- We'll keep the first ID (alphabetically) for each duplicate slug

-- First, update all foreign keys to point to the first category ID for each slug

-- Update threads
UPDATE threads
SET category_id = first_categories.first_id
FROM (
  SELECT slug,
         (array_agg(id::text ORDER BY id::text))[1]::uuid as first_id,
         array_agg(id ORDER BY id::text) as all_ids
  FROM categories
  GROUP BY slug
  HAVING COUNT(*) > 1
) as first_categories
WHERE threads.category_id = ANY(first_categories.all_ids)
  AND threads.category_id != first_categories.first_id;

-- Update category_subscriptions (remove duplicates first)
DELETE FROM category_subscriptions cs1
WHERE EXISTS (
  SELECT 1
  FROM category_subscriptions cs2
  JOIN (
    SELECT slug,
           (array_agg(id::text ORDER BY id::text))[1]::uuid as first_id,
           array_agg(id ORDER BY id::text) as all_ids
    FROM categories
    GROUP BY slug
    HAVING COUNT(*) > 1
  ) fc ON cs2.category_id = fc.first_id
  WHERE cs1.user_id = cs2.user_id
    AND cs1.category_id = ANY(fc.all_ids)
    AND cs1.category_id != fc.first_id
);

-- Update remaining category_subscriptions
UPDATE category_subscriptions
SET category_id = first_categories.first_id
FROM (
  SELECT slug,
         (array_agg(id::text ORDER BY id::text))[1]::uuid as first_id,
         array_agg(id ORDER BY id::text) as all_ids
  FROM categories
  GROUP BY slug
  HAVING COUNT(*) > 1
) as first_categories
WHERE category_subscriptions.category_id = ANY(first_categories.all_ids)
  AND category_subscriptions.category_id != first_categories.first_id;

-- Update moderators
UPDATE moderators
SET category_id = first_categories.first_id
FROM (
  SELECT slug,
         (array_agg(id::text ORDER BY id::text))[1]::uuid as first_id,
         array_agg(id ORDER BY id::text) as all_ids
  FROM categories
  GROUP BY slug
  HAVING COUNT(*) > 1
) as first_categories
WHERE moderators.category_id = ANY(first_categories.all_ids)
  AND moderators.category_id != first_categories.first_id;

-- Update moderator_elections
UPDATE moderator_elections
SET category_id = first_categories.first_id
FROM (
  SELECT slug,
         (array_agg(id::text ORDER BY id::text))[1]::uuid as first_id,
         array_agg(id ORDER BY id::text) as all_ids
  FROM categories
  GROUP BY slug
  HAVING COUNT(*) > 1
) as first_categories
WHERE moderator_elections.category_id = ANY(first_categories.all_ids)
  AND moderator_elections.category_id != first_categories.first_id;

-- Update category_digests
UPDATE category_digests
SET category_id = first_categories.first_id
FROM (
  SELECT slug,
         (array_agg(id::text ORDER BY id::text))[1]::uuid as first_id,
         array_agg(id ORDER BY id::text) as all_ids
  FROM categories
  GROUP BY slug
  HAVING COUNT(*) > 1
) as first_categories
WHERE category_digests.category_id = ANY(first_categories.all_ids)
  AND category_digests.category_id != first_categories.first_id;

-- Update category_rules
UPDATE category_rules
SET category_id = first_categories.first_id
FROM (
  SELECT slug,
         (array_agg(id::text ORDER BY id::text))[1]::uuid as first_id,
         array_agg(id ORDER BY id::text) as all_ids
  FROM categories
  GROUP BY slug
  HAVING COUNT(*) > 1
) as first_categories
WHERE category_rules.category_id = ANY(first_categories.all_ids)
  AND category_rules.category_id != first_categories.first_id;

-- Update thread_summaries
UPDATE thread_summaries
SET category_id = first_categories.first_id
FROM (
  SELECT slug,
         (array_agg(id::text ORDER BY id::text))[1]::uuid as first_id,
         array_agg(id ORDER BY id::text) as all_ids
  FROM categories
  GROUP BY slug
  HAVING COUNT(*) > 1
) as first_categories
WHERE thread_summaries.category_id = ANY(first_categories.all_ids)
  AND thread_summaries.category_id != first_categories.first_id;

-- Update user_warnings
UPDATE user_warnings
SET category_id = first_categories.first_id
FROM (
  SELECT slug,
         (array_agg(id::text ORDER BY id::text))[1]::uuid as first_id,
         array_agg(id ORDER BY id::text) as all_ids
  FROM categories
  GROUP BY slug
  HAVING COUNT(*) > 1
) as first_categories
WHERE user_warnings.category_id = ANY(first_categories.all_ids)
  AND user_warnings.category_id != first_categories.first_id;

-- Now delete the duplicate categories (keeping the first one)
DELETE FROM categories
WHERE id IN (
  SELECT unnest(all_ids[2:])::uuid
  FROM (
    SELECT slug, array_agg(id ORDER BY id::text) as all_ids
    FROM categories
    GROUP BY slug
    HAVING COUNT(*) > 1
  ) as dup_categories
);

-- Add unique constraint to prevent future duplicates
ALTER TABLE categories
ADD CONSTRAINT categories_slug_unique UNIQUE (slug);

-- Recalculate counts
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

-- Update metadata
INSERT INTO schema_migrations (version, description, applied_at)
VALUES (26, 'Simple fix for duplicate categories', NOW())
ON CONFLICT (version) DO UPDATE SET
  description = EXCLUDED.description,
  applied_at = EXCLUDED.applied_at;