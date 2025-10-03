-- ============================================
-- Migration: Cleanup Duplicate Functions and Fix Security Issues
-- Description: Removes all duplicate function versions and ensures all functions have secure search_path
-- Date: 2025-01-03
-- ============================================

-- ============================================
-- STEP 1: Drop ALL versions of functions with security issues
-- ============================================

-- Drop all versions of calculate_hot_score
DO $$
BEGIN
  -- Drop any version with 3 parameters (different timestamp types)
  IF EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'calculate_hot_score'
    AND pronargs = 3
    AND pronamespace = 'public'::regnamespace
  ) THEN
    DROP FUNCTION IF EXISTS public.calculate_hot_score(INTEGER, INTEGER, TIMESTAMP);
    DROP FUNCTION IF EXISTS public.calculate_hot_score(INTEGER, INTEGER, TIMESTAMP WITH TIME ZONE);
    DROP FUNCTION IF EXISTS public.calculate_hot_score(INTEGER, INTEGER, TIMESTAMP WITHOUT TIME ZONE);
  END IF;
END $$;

-- Drop all versions of calculate_wilson_score
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'calculate_wilson_score'
    AND pronamespace = 'public'::regnamespace
  ) THEN
    DROP FUNCTION IF EXISTS public.calculate_wilson_score(INTEGER, INTEGER);
    DROP FUNCTION IF EXISTS public.calculate_wilson_score(INTEGER, INTEGER, NUMERIC);
  END IF;
END $$;

-- Drop all versions of calculate_user_level
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'calculate_user_level'
    AND pronamespace = 'public'::regnamespace
  ) THEN
    DROP FUNCTION IF EXISTS public.calculate_user_level(INTEGER);
  END IF;
END $$;

-- Drop all versions of award_xp
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'award_xp'
    AND pronamespace = 'public'::regnamespace
  ) THEN
    DROP FUNCTION IF EXISTS public.award_xp(UUID, TEXT, TEXT, UUID);
    DROP FUNCTION IF EXISTS public.award_xp(UUID, TEXT, INTEGER);
  END IF;
END $$;

-- Drop all versions of check_bot_criteria
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'check_bot_criteria'
    AND pronamespace = 'public'::regnamespace
  ) THEN
    DROP FUNCTION IF EXISTS public.check_bot_criteria(UUID);
  END IF;
END $$;

-- Drop all versions of update_bot_status (CASCADE to drop dependent triggers)
DO $$
BEGIN
  -- Drop the trigger first if it exists
  DROP TRIGGER IF EXISTS trigger_update_bot_status ON bot_reports;

  IF EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'update_bot_status'
    AND pronamespace = 'public'::regnamespace
  ) THEN
    DROP FUNCTION IF EXISTS public.update_bot_status() CASCADE;
    DROP FUNCTION IF EXISTS public.update_bot_status(UUID) CASCADE;
  END IF;
END $$;

-- Drop all versions of generate_comment_path
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'generate_comment_path'
    AND pronamespace = 'public'::regnamespace
  ) THEN
    DROP FUNCTION IF EXISTS public.generate_comment_path(UUID);
  END IF;
END $$;

-- Drop all versions of get_category_path
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'get_category_path'
    AND pronamespace = 'public'::regnamespace
  ) THEN
    DROP FUNCTION IF EXISTS public.get_category_path(UUID);
  END IF;
END $$;

-- Drop all versions of get_thread_stats
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'get_thread_stats'
    AND pronamespace = 'public'::regnamespace
  ) THEN
    DROP FUNCTION IF EXISTS public.get_thread_stats(UUID);
  END IF;
END $$;

-- Drop all versions of get_user_stats
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'get_user_stats'
    AND pronamespace = 'public'::regnamespace
  ) THEN
    DROP FUNCTION IF EXISTS public.get_user_stats(UUID);
  END IF;
END $$;

-- Drop all versions of search_threads
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'search_threads'
    AND pronamespace = 'public'::regnamespace
  ) THEN
    DROP FUNCTION IF EXISTS public.search_threads(TEXT, UUID, INTEGER);
    DROP FUNCTION IF EXISTS public.search_threads(TEXT, UUID, INTEGER, INTEGER);
  END IF;
END $$;

-- Drop all versions of evaluate_bot_status
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'evaluate_bot_status'
    AND pronamespace = 'public'::regnamespace
  ) THEN
    DROP FUNCTION IF EXISTS public.evaluate_bot_status(UUID);
  END IF;
END $$;

-- ============================================
-- STEP 2: Recreate functions with secure search_path
-- ============================================

-- Calculate hot score (Reddit algorithm)
CREATE FUNCTION calculate_hot_score(
  upvotes INTEGER,
  downvotes INTEGER,
  created_at TIMESTAMP WITH TIME ZONE
)
RETURNS NUMERIC AS $$
DECLARE
  score INTEGER;
  order_value NUMERIC;
  sign_value INTEGER;
  seconds_since_epoch NUMERIC;
BEGIN
  score := upvotes - downvotes;

  IF score > 0 THEN
    sign_value := 1;
  ELSIF score < 0 THEN
    sign_value := -1;
  ELSE
    sign_value := 0;
  END IF;

  order_value := GREATEST(ABS(score), 1);
  seconds_since_epoch := EXTRACT(EPOCH FROM created_at) - 1134028003;

  RETURN ROUND(sign_value * LOG(10, order_value) + seconds_since_epoch / 45000, 7);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT SET search_path = '';

-- Calculate Wilson score for quality ranking
CREATE FUNCTION calculate_wilson_score(
  upvotes INTEGER,
  downvotes INTEGER
)
RETURNS NUMERIC AS $$
DECLARE
  n NUMERIC;
  phat NUMERIC;
  z NUMERIC := 1.96; -- 95% confidence
  result NUMERIC;
BEGIN
  n := upvotes + downvotes;

  IF n = 0 THEN
    RETURN 0;
  END IF;

  phat := upvotes::NUMERIC / n;

  result := (phat + z*z/(2*n) - z * SQRT((phat*(1-phat) + z*z/(4*n))/n)) / (1 + z*z/n);

  RETURN ROUND(result, 4);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT SET search_path = '';

-- Calculate user level based on XP
CREATE FUNCTION calculate_user_level(xp INTEGER)
RETURNS INTEGER AS $$
BEGIN
  RETURN CASE
    WHEN xp < 100 THEN 1
    WHEN xp < 500 THEN 2
    WHEN xp < 1500 THEN 3
    WHEN xp < 5000 THEN 4
    ELSE 5
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT SET search_path = '';

-- Award XP to user
CREATE FUNCTION award_xp(
  p_user_id UUID,
  p_action TEXT,
  p_amount INTEGER DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  xp_amount INTEGER;
  new_total_xp INTEGER;
  new_level INTEGER;
BEGIN
  -- Get XP amount (use provided amount or calculate from action)
  xp_amount := COALESCE(p_amount,
    CASE p_action
      WHEN 'thread_created' THEN 10
      WHEN 'comment_created' THEN 5
      WHEN 'thread_upvoted' THEN 2
      WHEN 'comment_upvoted' THEN 1
      WHEN 'daily_visit' THEN 3
      WHEN 'report_confirmed' THEN 15
      WHEN 'moderation_action' THEN 20
      ELSE 0
    END
  );

  -- Update user XP and level
  UPDATE users
  SET
    xp = xp + xp_amount,
    level = calculate_user_level(xp + xp_amount),
    updated_at = NOW()
  WHERE id = p_user_id
  RETURNING xp, level INTO new_total_xp, new_level;

  -- Record transaction
  INSERT INTO xp_transactions (
    user_id,
    action,
    amount,
    balance,
    created_at
  ) VALUES (
    p_user_id,
    p_action,
    xp_amount,
    new_total_xp,
    NOW()
  );
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Check bot criteria
CREATE FUNCTION check_bot_criteria(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  criteria_met INTEGER := 0;
  post_frequency NUMERIC;
  short_post_ratio NUMERIC;
  report_count INTEGER;
BEGIN
  -- Check post frequency (more than 10 posts in an hour)
  SELECT COUNT(*) INTO post_frequency
  FROM threads
  WHERE user_id = p_user_id
  AND created_at > NOW() - INTERVAL '1 hour';

  IF post_frequency > 10 THEN
    criteria_met := criteria_met + 1;
  END IF;

  -- Check short post ratio (more than 70% posts under 40 chars)
  SELECT
    CASE
      WHEN COUNT(*) > 0 THEN
        SUM(CASE WHEN LENGTH(content) < 40 THEN 1 ELSE 0 END)::NUMERIC / COUNT(*)
      ELSE 0
    END INTO short_post_ratio
  FROM threads
  WHERE user_id = p_user_id;

  IF short_post_ratio > 0.7 THEN
    criteria_met := criteria_met + 1;
  END IF;

  -- Check bot reports
  SELECT COUNT(*) INTO report_count
  FROM bot_reports
  WHERE user_id = p_user_id
  AND confidence > 0.5;

  IF report_count > 2 THEN
    criteria_met := criteria_met + 1;
  END IF;

  -- Return true if 2 or more criteria met
  RETURN criteria_met >= 2;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Update bot status trigger function
CREATE FUNCTION update_bot_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.confidence > 0.8 AND NEW.status = 'pending' THEN
    UPDATE users
    SET
      is_bot = TRUE,
      bot_probability = NEW.confidence,
      updated_at = NOW()
    WHERE id = NEW.user_id;

    NEW.status = 'confirmed';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Generate comment path (for ltree)
CREATE FUNCTION generate_comment_path(p_parent_id UUID)
RETURNS public.ltree AS $$
DECLARE
  parent_path public.ltree;
  new_id TEXT;
BEGIN
  new_id := gen_random_uuid()::TEXT;

  IF p_parent_id IS NULL THEN
    RETURN new_id::public.ltree;
  ELSE
    SELECT path INTO parent_path FROM comments WHERE id = p_parent_id;
    RETURN parent_path || new_id::public.ltree;
  END IF;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Get category path
CREATE FUNCTION get_category_path(p_category_id UUID)
RETURNS public.ltree AS $$
DECLARE
  cat_path public.ltree;
BEGIN
  SELECT path INTO cat_path FROM categories WHERE id = p_category_id;
  RETURN cat_path;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Get thread statistics
CREATE FUNCTION get_thread_stats(p_thread_id UUID)
RETURNS TABLE(
  comment_count INTEGER,
  unique_commenters INTEGER,
  total_votes INTEGER,
  wilson_score NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(c.id)::INTEGER AS comment_count,
    COUNT(DISTINCT c.user_id)::INTEGER AS unique_commenters,
    (t.upvotes + t.downvotes)::INTEGER AS total_votes,
    t.wilson_score
  FROM threads t
  LEFT JOIN comments c ON c.thread_id = t.id
  WHERE t.id = p_thread_id
  GROUP BY t.id, t.upvotes, t.downvotes, t.wilson_score;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Get user statistics
CREATE FUNCTION get_user_stats(p_user_id UUID)
RETURNS TABLE(
  thread_count INTEGER,
  comment_count INTEGER,
  total_upvotes INTEGER,
  total_downvotes INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*)::INTEGER FROM threads WHERE user_id = p_user_id) AS thread_count,
    (SELECT COUNT(*)::INTEGER FROM comments WHERE user_id = p_user_id) AS comment_count,
    (SELECT COALESCE(SUM(upvotes), 0)::INTEGER FROM threads WHERE user_id = p_user_id) AS total_upvotes,
    (SELECT COALESCE(SUM(downvotes), 0)::INTEGER FROM threads WHERE user_id = p_user_id) AS total_downvotes;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Search threads with full-text search
CREATE FUNCTION search_threads(
  search_query TEXT,
  p_category_id UUID DEFAULT NULL,
  limit_count INTEGER DEFAULT 20
)
RETURNS TABLE(
  id UUID,
  title TEXT,
  content TEXT,
  user_id UUID,
  category_id UUID,
  created_at TIMESTAMP WITH TIME ZONE,
  relevance REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id,
    t.title,
    t.content,
    t.user_id,
    t.category_id,
    t.created_at,
    ts_rank(t.search_vector, plainto_tsquery(search_query)) AS relevance
  FROM threads t
  WHERE
    t.search_vector @@ plainto_tsquery(search_query)
    AND (p_category_id IS NULL OR t.category_id = p_category_id)
    AND t.is_removed = FALSE
  ORDER BY relevance DESC, t.created_at DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Evaluate bot status for user
CREATE FUNCTION evaluate_bot_status(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  avg_confidence NUMERIC;
  is_bot_detected BOOLEAN;
BEGIN
  -- Check if user meets bot criteria
  is_bot_detected := check_bot_criteria(p_user_id);

  -- Get average confidence from bot reports
  SELECT AVG(confidence) INTO avg_confidence
  FROM bot_reports
  WHERE user_id = p_user_id
  AND created_at > NOW() - INTERVAL '7 days';

  -- Update user if bot detected with high confidence
  IF is_bot_detected OR (avg_confidence IS NOT NULL AND avg_confidence > 0.7) THEN
    UPDATE users
    SET is_bot = TRUE,
        bot_probability = COALESCE(avg_confidence, 0.75),
        updated_at = NOW()
    WHERE id = p_user_id;
  END IF;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- ============================================
-- STEP 3: Recreate any dropped triggers if needed
-- ============================================

-- Recreate trigger for bot status updates if it was dropped
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'trigger_update_bot_status'
  ) THEN
    CREATE TRIGGER trigger_update_bot_status
    BEFORE INSERT OR UPDATE ON bot_reports
    FOR EACH ROW EXECUTE FUNCTION update_bot_status();
  END IF;
END $$;

-- ============================================
-- Verification queries (commented out, for manual verification)
-- ============================================

-- Verify all functions have search_path set:
-- SELECT proname, proconfig
-- FROM pg_proc
-- WHERE pronamespace = 'public'::regnamespace
-- AND proname IN (
--   'calculate_hot_score', 'calculate_wilson_score', 'calculate_user_level',
--   'award_xp', 'check_bot_criteria', 'update_bot_status',
--   'generate_comment_path', 'get_category_path', 'get_thread_stats',
--   'get_user_stats', 'search_threads', 'evaluate_bot_status'
-- )
-- ORDER BY proname;

-- ============================================
-- End of migration
-- ============================================