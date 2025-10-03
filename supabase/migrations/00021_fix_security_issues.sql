-- ============================================
-- Migration: Fix Security Issues
-- Description: Addresses Supabase security warnings
-- Date: 2025-01-03
-- ============================================

-- ============================================
-- 1. FIX CRITICAL: Enable RLS on content_reports table
-- ============================================

ALTER TABLE content_reports ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 2. FIX IMPORTANT: Set search_path for all functions
-- ============================================

-- Note: Setting search_path = '' prevents SQL injection attacks by ensuring
-- functions don't rely on mutable search paths that could be exploited

-- Calculate hot score function
CREATE OR REPLACE FUNCTION calculate_hot_score(
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
$$ LANGUAGE plpgsql IMMUTABLE SET search_path = '';

-- Calculate Wilson score function
CREATE OR REPLACE FUNCTION calculate_wilson_score(
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
$$ LANGUAGE plpgsql IMMUTABLE SET search_path = '';

-- Get XP for action function
CREATE OR REPLACE FUNCTION get_xp_for_action(action_type TEXT)
RETURNS INTEGER AS $$
BEGIN
  RETURN CASE action_type
    WHEN 'thread_created' THEN 10
    WHEN 'comment_created' THEN 5
    WHEN 'thread_upvoted' THEN 2
    WHEN 'comment_upvoted' THEN 1
    WHEN 'daily_visit' THEN 3
    WHEN 'report_confirmed' THEN 15
    WHEN 'moderation_action' THEN 20
    ELSE 0
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE SET search_path = '';

-- Calculate user level function
-- Drop and recreate to fix parameter name issue
DROP FUNCTION IF EXISTS calculate_user_level(INTEGER);
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
$$ LANGUAGE plpgsql IMMUTABLE SET search_path = '';

-- Update user activity function
CREATE OR REPLACE FUNCTION update_user_activity()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_activity (
    user_id,
    action_type,
    metadata,
    created_at
  ) VALUES (
    NEW.user_id,
    TG_ARGV[0],
    jsonb_build_object(
      'table', TG_TABLE_NAME,
      'id', NEW.id
    ),
    NOW()
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Track post length function
CREATE OR REPLACE FUNCTION track_post_length()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_TABLE_NAME = 'threads' THEN
    NEW.content_length := LENGTH(NEW.content);
  ELSIF TG_TABLE_NAME = 'comments' THEN
    NEW.content_length := LENGTH(NEW.content);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Update subscriber count function
CREATE OR REPLACE FUNCTION update_subscriber_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE categories
    SET subscriber_count = subscriber_count + 1
    WHERE id = NEW.category_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE categories
    SET subscriber_count = subscriber_count - 1
    WHERE id = OLD.category_id;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Calculate category path function
CREATE OR REPLACE FUNCTION calculate_category_path()
RETURNS TRIGGER AS $$
DECLARE
  parent_path public.ltree;
BEGIN
  IF NEW.parent_id IS NULL THEN
    NEW.path = NEW.slug::public.ltree;
  ELSE
    SELECT path INTO parent_path FROM categories WHERE id = NEW.parent_id;
    NEW.path = parent_path || NEW.slug::public.ltree;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Calculate comment path function
CREATE OR REPLACE FUNCTION calculate_comment_path()
RETURNS TRIGGER AS $$
DECLARE
  parent_path public.ltree;
BEGIN
  IF NEW.parent_id IS NULL THEN
    NEW.path = NEW.id::text::public.ltree;
  ELSE
    SELECT path INTO parent_path FROM comments WHERE id = NEW.parent_id;
    NEW.path = parent_path || NEW.id::text::public.ltree;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Update thread activity function
CREATE OR REPLACE FUNCTION update_thread_activity()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE threads
  SET
    last_activity = NOW(),
    updated_at = NOW()
  WHERE id = NEW.thread_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Update category post count function
CREATE OR REPLACE FUNCTION update_category_post_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE categories
    SET post_count = post_count + 1,
        last_activity = NOW(),
        updated_at = NOW()
    WHERE id = NEW.category_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE categories
    SET post_count = post_count - 1,
        updated_at = NOW()
    WHERE id = OLD.category_id;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Update bot detection function
CREATE OR REPLACE FUNCTION update_bot_detection()
RETURNS TRIGGER AS $$
DECLARE
  post_count INTEGER;
  time_span INTERVAL;
BEGIN
  -- Count posts in last hour
  SELECT COUNT(*) INTO post_count
  FROM threads
  WHERE user_id = NEW.user_id
  AND created_at > NOW() - INTERVAL '1 hour';

  -- Flag if suspicious
  IF post_count > 10 THEN
    INSERT INTO bot_reports (user_id, reason, confidence)
    VALUES (NEW.user_id, 'High posting frequency', 0.8);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Award XP function
CREATE OR REPLACE FUNCTION award_xp(
  p_user_id UUID,
  p_action TEXT,
  p_amount INTEGER DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  xp_amount INTEGER;
  new_total_xp INTEGER;
  new_level INTEGER;
  old_level INTEGER;
BEGIN
  -- Get XP amount
  xp_amount := COALESCE(p_amount, get_xp_for_action(p_action));

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

-- Check bot criteria function
-- Drop and recreate to fix return type issue
DROP FUNCTION IF EXISTS check_bot_criteria(UUID);
CREATE FUNCTION check_bot_criteria(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  criteria_met INTEGER := 0;
  total_criteria INTEGER := 5;
BEGIN
  -- Check various bot indicators
  -- Implementation would check multiple factors
  -- This is a simplified version

  IF criteria_met >= 3 THEN
    RETURN TRUE;
  END IF;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Update bot status function
CREATE OR REPLACE FUNCTION update_bot_status()
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

-- Generate comment path function
-- Drop and recreate to fix parameter name issue
DROP FUNCTION IF EXISTS generate_comment_path(UUID);
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

-- Get category path function
-- Drop and recreate to fix return type issue
DROP FUNCTION IF EXISTS get_category_path(UUID);
CREATE FUNCTION get_category_path(p_category_id UUID)
RETURNS public.ltree AS $$
DECLARE
  cat_path public.ltree;
BEGIN
  SELECT path INTO cat_path FROM categories WHERE id = p_category_id;
  RETURN cat_path;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Get thread stats function
-- Drop and recreate to fix return type issue
DROP FUNCTION IF EXISTS get_thread_stats(UUID);
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

-- Get user stats function
-- Drop and recreate to fix return type issue
DROP FUNCTION IF EXISTS get_user_stats(UUID);
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

-- Search threads function
-- Drop and recreate to fix parameter name collision
DROP FUNCTION IF EXISTS search_threads(TEXT, UUID, INTEGER);
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

-- Update thread hot score function
CREATE OR REPLACE FUNCTION update_thread_hot_score()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE threads
  SET
    hot_score = calculate_hot_score(NEW.upvotes, NEW.downvotes, NEW.created_at),
    updated_at = NOW()
  WHERE id = NEW.id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Update category thread count function
CREATE OR REPLACE FUNCTION update_category_thread_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE categories
    SET thread_count = thread_count + 1
    WHERE id = NEW.category_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE categories
    SET thread_count = thread_count - 1
    WHERE id = OLD.category_id;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Set comment path function
CREATE OR REPLACE FUNCTION set_comment_path()
RETURNS TRIGGER AS $$
DECLARE
  parent_path public.ltree;
BEGIN
  IF NEW.parent_id IS NULL THEN
    NEW.path = NEW.id::text::public.ltree;
  ELSE
    SELECT path INTO parent_path FROM comments WHERE id = NEW.parent_id;
    IF parent_path IS NULL THEN
      RAISE EXCEPTION 'Parent comment not found';
    END IF;
    NEW.path = parent_path || NEW.id::text::public.ltree;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Update thread comment count function
CREATE OR REPLACE FUNCTION update_thread_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE threads
    SET comment_count = comment_count + 1,
        last_activity = NOW()
    WHERE id = NEW.thread_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE threads
    SET comment_count = comment_count - 1
    WHERE id = OLD.thread_id;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Update comment Wilson score function
CREATE OR REPLACE FUNCTION update_comment_wilson_score()
RETURNS TRIGGER AS $$
BEGIN
  NEW.wilson_score := calculate_wilson_score(NEW.upvotes, NEW.downvotes);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Update thread vote counts function
CREATE OR REPLACE FUNCTION update_thread_vote_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.vote_type = 1 THEN
      UPDATE threads SET upvotes = upvotes + 1 WHERE id = NEW.thread_id;
    ELSE
      UPDATE threads SET downvotes = downvotes + 1 WHERE id = NEW.thread_id;
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.vote_type = 1 AND NEW.vote_type = -1 THEN
      UPDATE threads SET upvotes = upvotes - 1, downvotes = downvotes + 1 WHERE id = NEW.thread_id;
    ELSIF OLD.vote_type = -1 AND NEW.vote_type = 1 THEN
      UPDATE threads SET downvotes = downvotes - 1, upvotes = upvotes + 1 WHERE id = NEW.thread_id;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.vote_type = 1 THEN
      UPDATE threads SET upvotes = upvotes - 1 WHERE id = OLD.thread_id;
    ELSE
      UPDATE threads SET downvotes = downvotes - 1 WHERE id = OLD.thread_id;
    END IF;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Update comment vote counts function
CREATE OR REPLACE FUNCTION update_comment_vote_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.vote_type = 1 THEN
      UPDATE comments SET upvotes = upvotes + 1 WHERE id = NEW.comment_id;
    ELSE
      UPDATE comments SET downvotes = downvotes + 1 WHERE id = NEW.comment_id;
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.vote_type = 1 AND NEW.vote_type = -1 THEN
      UPDATE comments SET upvotes = upvotes - 1, downvotes = downvotes + 1 WHERE id = NEW.comment_id;
    ELSIF OLD.vote_type = -1 AND NEW.vote_type = 1 THEN
      UPDATE comments SET downvotes = downvotes - 1, upvotes = upvotes + 1 WHERE id = NEW.comment_id;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.vote_type = 1 THEN
      UPDATE comments SET upvotes = upvotes - 1 WHERE id = OLD.comment_id;
    ELSE
      UPDATE comments SET downvotes = downvotes - 1 WHERE id = OLD.comment_id;
    END IF;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Evaluate bot status function
-- Drop and recreate to fix return type issue
DROP FUNCTION IF EXISTS evaluate_bot_status(UUID);
CREATE FUNCTION evaluate_bot_status(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  avg_confidence NUMERIC;
BEGIN
  SELECT AVG(confidence) INTO avg_confidence
  FROM bot_reports
  WHERE user_id = p_user_id
  AND created_at > NOW() - INTERVAL '7 days';

  IF avg_confidence > 0.7 THEN
    UPDATE users
    SET is_bot = TRUE,
        bot_probability = avg_confidence
    WHERE id = p_user_id;
  END IF;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Cleanup expired sessions function
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS void AS $$
BEGIN
  DELETE FROM user_sessions WHERE expires_at < NOW();
  DELETE FROM temporary_bans WHERE expires_at < NOW() AND is_active = true;
  DELETE FROM user_warnings WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Update hot threads function
CREATE OR REPLACE FUNCTION update_hot_threads()
RETURNS void AS $$
BEGIN
  UPDATE threads
  SET hot_score = calculate_hot_score(upvotes, downvotes, created_at),
      is_hot = (calculate_hot_score(upvotes, downvotes, created_at) > 5)
  WHERE created_at > NOW() - INTERVAL '7 days'
  AND is_removed = false;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Archive old notifications function
CREATE OR REPLACE FUNCTION archive_old_notifications()
RETURNS void AS $$
BEGIN
  DELETE FROM notifications
  WHERE created_at < NOW() - INTERVAL '30 days'
  AND is_read = true;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Recalculate trust scores function
CREATE OR REPLACE FUNCTION recalculate_trust_scores()
RETURNS void AS $$
BEGIN
  UPDATE users
  SET trust_score = GREATEST(0, LEAST(100,
    50 +
    (SELECT COUNT(*) FROM threads WHERE user_id = users.id AND NOT is_removed) * 2 +
    (SELECT COUNT(*) FROM comments WHERE user_id = users.id AND NOT is_removed) +
    (SELECT SUM(upvotes - downvotes) FROM threads WHERE user_id = users.id) / 10
  ))
  WHERE NOT is_bot;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Create user profile function
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO users (
    id,
    email,
    username,
    display_name,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    NOW(),
    NOW()
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- ============================================
-- 3. FIX RECOMMENDED: Extensions in public schema
-- ============================================

-- Note: Extensions (ltree, pg_trgm) remain in public schema for compatibility
-- Extension schema migration removed due to permission constraints in Supabase
-- All ltree type references use public.ltree to be explicit

-- ============================================
-- Verification queries (commented out, for manual verification)
-- ============================================

-- Check if RLS is enabled:
-- SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'content_reports';

-- Check function search paths:
-- SELECT proname, prosecdef, proconfig FROM pg_proc
-- WHERE proname IN ('calculate_hot_score', 'calculate_wilson_score')
-- AND pronamespace = 'public'::regnamespace;

-- Check extension schemas:
-- SELECT extname, extnamespace::regnamespace FROM pg_extension
-- WHERE extname IN ('ltree', 'pg_trgm');

-- ============================================
-- End of migration
-- ============================================