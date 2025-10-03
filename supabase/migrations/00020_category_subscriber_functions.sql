-- ============================================
-- Migration: 00020_category_subscriber_functions.sql
-- Add RPC functions for managing category subscriber counts
-- ============================================

-- Function to increment/decrement category subscriber count
CREATE OR REPLACE FUNCTION increment_category_subscribers(
  category_id UUID,
  increment INTEGER
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE categories
  SET subscriber_count = GREATEST(0, COALESCE(subscriber_count, 0) + increment)
  WHERE id = category_id;
END;
$$;

-- Function to get accurate subscriber count for a category
CREATE OR REPLACE FUNCTION get_category_subscriber_count(category_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  count INTEGER;
BEGIN
  SELECT COUNT(*)::INTEGER
  INTO count
  FROM category_subscriptions
  WHERE category_subscriptions.category_id = get_category_subscriber_count.category_id;

  RETURN COALESCE(count, 0);
END;
$$;

-- Function to sync all category subscriber counts (for maintenance)
CREATE OR REPLACE FUNCTION sync_all_category_subscriber_counts()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE categories c
  SET subscriber_count = (
    SELECT COUNT(*)
    FROM category_subscriptions cs
    WHERE cs.category_id = c.id
  );
END;
$$;

-- Grant execute permissions for authenticated users
GRANT EXECUTE ON FUNCTION increment_category_subscribers(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_category_subscriber_count(UUID) TO authenticated;

-- Comment the functions
COMMENT ON FUNCTION increment_category_subscribers(UUID, INTEGER) IS
  'Safely increments or decrements the subscriber count for a category';
COMMENT ON FUNCTION get_category_subscriber_count(UUID) IS
  'Returns the accurate subscriber count for a category';
COMMENT ON FUNCTION sync_all_category_subscriber_counts() IS
  'Syncs all category subscriber counts with actual subscription data (maintenance)';

-- Add trigger to automatically update subscriber count on subscription changes
CREATE OR REPLACE FUNCTION update_category_subscriber_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE categories
    SET subscriber_count = COALESCE(subscriber_count, 0) + 1
    WHERE id = NEW.category_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE categories
    SET subscriber_count = GREATEST(0, COALESCE(subscriber_count, 0) - 1)
    WHERE id = OLD.category_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

-- Create trigger for automatic subscriber count updates
DROP TRIGGER IF EXISTS update_category_subscriber_count_trigger ON category_subscriptions;
CREATE TRIGGER update_category_subscriber_count_trigger
AFTER INSERT OR DELETE ON category_subscriptions
FOR EACH ROW
EXECUTE FUNCTION update_category_subscriber_count();

-- Log successful migration
DO $$
BEGIN
  RAISE NOTICE 'Migration 00020: Category subscriber functions installed successfully';
END $$;