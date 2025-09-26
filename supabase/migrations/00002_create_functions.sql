-- Database Functions for Friksi
-- Hot score calculation, XP management, and utility functions

-- ============================================================================
-- HOT SCORE CALCULATION (Reddit-style algorithm)
-- ============================================================================

-- Calculate hot score for threads (time-decay algorithm)
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

  -- Determine sign
  IF score > 0 THEN
    sign_value := 1;
  ELSIF score < 0 THEN
    sign_value := -1;
  ELSE
    sign_value := 0;
  END IF;

  -- Calculate order of magnitude
  order_value := LOG(GREATEST(ABS(score), 1));

  -- Time component (seconds since epoch)
  seconds_since_epoch := EXTRACT(EPOCH FROM created_at);

  -- Reddit hot algorithm: sign * log(max(abs(score), 1)) + (seconds / 45000)
  RETURN sign_value * order_value + (seconds_since_epoch / 45000.0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- WILSON SCORE INTERVAL (for quality ranking)
-- ============================================================================

-- Calculate Wilson score confidence interval for quality ranking
CREATE OR REPLACE FUNCTION calculate_wilson_score(
  upvotes INTEGER,
  downvotes INTEGER,
  confidence NUMERIC DEFAULT 0.95
)
RETURNS NUMERIC AS $$
DECLARE
  n INTEGER;
  p NUMERIC;
  z NUMERIC;
BEGIN
  n := upvotes + downvotes;

  IF n = 0 THEN
    RETURN 0;
  END IF;

  p := CAST(upvotes AS NUMERIC) / n;

  -- Z-score for 95% confidence (1.96)
  z := 1.96;

  -- Wilson score formula
  RETURN (p + z*z/(2*n) - z * SQRT((p*(1-p) + z*z/(4*n))/n))/(1 + z*z/n);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- XP AND LEVELING SYSTEM
-- ============================================================================

-- XP values for different actions
CREATE OR REPLACE FUNCTION get_xp_for_action(action_type TEXT)
RETURNS INTEGER AS $$
BEGIN
  RETURN CASE action_type
    WHEN 'thread_created' THEN 10
    WHEN 'comment_created' THEN 5
    WHEN 'upvote_received' THEN 2
    WHEN 'downvote_received' THEN -1
    WHEN 'voted' THEN 1
    WHEN 'daily_login' THEN 1
    WHEN 'moderate_action' THEN 15
    WHEN 'report_validated' THEN 5
    WHEN 'election_participation' THEN 20
    ELSE 0
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Calculate user level based on XP
CREATE OR REPLACE FUNCTION calculate_user_level(xp_amount INTEGER)
RETURNS INTEGER AS $$
BEGIN
  IF xp_amount >= 5000 THEN
    RETURN 5;
  ELSIF xp_amount >= 2000 THEN
    RETURN 4;
  ELSIF xp_amount >= 500 THEN
    RETURN 3;
  ELSIF xp_amount >= 100 THEN
    RETURN 2;
  ELSE
    RETURN 1;
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Award XP to user and update level
CREATE OR REPLACE FUNCTION award_xp(
  target_user_id UUID,
  action_type TEXT,
  reference_content_type TEXT DEFAULT NULL,
  reference_content_id UUID DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  xp_to_award INTEGER;
  new_xp INTEGER;
  new_level INTEGER;
  current_level INTEGER;
BEGIN
  xp_to_award := get_xp_for_action(action_type);

  IF xp_to_award = 0 THEN
    RETURN;
  END IF;

  -- Get current level
  SELECT level INTO current_level FROM users WHERE id = target_user_id;

  -- Update user XP
  UPDATE users
  SET xp = xp + xp_to_award,
      last_active = NOW()
  WHERE id = target_user_id
  RETURNING xp INTO new_xp;

  -- Calculate new level
  new_level := calculate_user_level(new_xp);

  -- Update level if it changed
  IF new_level != current_level THEN
    UPDATE users SET level = new_level WHERE id = target_user_id;
  END IF;

  -- Log the activity in XP transactions
  INSERT INTO xp_transactions (user_id, amount, reason, source_type, source_id)
  VALUES (target_user_id, xp_to_award, action_type, action_type, reference_content_id);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- BOT DETECTION FUNCTIONS
-- ============================================================================

-- Check if user meets bot criteria
CREATE OR REPLACE FUNCTION check_bot_criteria(target_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  criteria_met INTEGER := 0;
  short_post_ratio NUMERIC;
  user_report_ratio NUMERIC;
  moderator_reports INTEGER;
  total_users INTEGER;
  active_users INTEGER;
BEGIN
  -- Criteria 1: 70% of posts under 40 characters
  SELECT
    CASE
      WHEN total_post_count > 0 AND (CAST(short_post_count AS NUMERIC) / total_post_count) >= 0.70
      THEN 1
      ELSE 0
    END
  INTO criteria_met
  FROM users
  WHERE id = target_user_id;

  -- Criteria 2: 3.5% of active users report as bot
  SELECT COUNT(*) INTO active_users
  FROM users
  WHERE is_active = TRUE AND last_active_at > NOW() - INTERVAL '30 days';

  SELECT COUNT(*) INTO moderator_reports
  FROM bot_flags bf
  WHERE bf.user_id = target_user_id
  AND bf.criteria = 2;

  IF active_users > 0 AND (CAST(moderator_reports AS NUMERIC) / active_users) >= 0.035 THEN
    criteria_met := criteria_met + 1;
  END IF;

  -- Criteria 3: 3 moderators report as bot
  SELECT COUNT(*) INTO moderator_reports
  FROM bot_flags bf
  JOIN moderators m ON m.user_id = bf.flagged_by
  WHERE bf.user_id = target_user_id
  AND bf.criteria = 3
  AND m.is_active = TRUE;

  IF moderator_reports >= 3 THEN
    criteria_met := criteria_met + 1;
  END IF;

  RETURN criteria_met;
END;
$$ LANGUAGE plpgsql;

-- Flag user as bot if criteria met
CREATE OR REPLACE FUNCTION update_bot_status(target_user_id UUID)
RETURNS VOID AS $$
DECLARE
  criteria_count INTEGER;
BEGIN
  criteria_count := check_bot_criteria(target_user_id);

  -- Update bot status and flag count
  UPDATE users
  SET
    is_bot = (criteria_count >= 2),
    bot_flags = criteria_count
  WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- LTREE PATH MANAGEMENT
-- ============================================================================

-- Generate comment path for nested structure
CREATE OR REPLACE FUNCTION generate_comment_path(
  parent_comment_id UUID DEFAULT NULL
)
RETURNS LTREE AS $$
DECLARE
  parent_path LTREE;
  new_path TEXT;
BEGIN
  IF parent_comment_id IS NULL THEN
    -- Root comment
    RETURN CAST(EXTRACT(EPOCH FROM NOW())::TEXT AS LTREE);
  END IF;

  -- Get parent path
  SELECT path INTO parent_path
  FROM comments
  WHERE id = parent_comment_id;

  IF parent_path IS NULL THEN
    RAISE EXCEPTION 'Parent comment not found';
  END IF;

  -- Append timestamp to parent path
  new_path := parent_path::TEXT || '.' || EXTRACT(EPOCH FROM NOW())::TEXT;

  RETURN CAST(new_path AS LTREE);
END;
$$ LANGUAGE plpgsql;

-- Helper function to get category hierarchy path
CREATE OR REPLACE FUNCTION get_category_path(category_id UUID)
RETURNS TEXT AS $$
WITH RECURSIVE category_path AS (
  SELECT id, name, parent_id, name::TEXT as path
  FROM categories
  WHERE id = category_id

  UNION ALL

  SELECT c.id, c.name, c.parent_id,
         cp.path || ' > ' || c.name
  FROM categories c
  INNER JOIN category_path cp ON c.id = cp.parent_id
)
SELECT path FROM category_path WHERE parent_id IS NULL;
$$ LANGUAGE SQL;

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Get thread statistics
CREATE OR REPLACE FUNCTION get_thread_stats(thread_uuid UUID)
RETURNS JSONB AS $$
DECLARE
  stats JSONB;
BEGIN
  SELECT jsonb_build_object(
    'upvotes', t.upvotes,
    'downvotes', t.downvotes,
    'comment_count', t.comment_count,
    'view_count', t.view_count,
    'hot_score', t.hot_score,
    'wilson_score', t.wilson_score,
    'engagement_ratio', CASE
      WHEN t.view_count > 0 THEN ROUND((t.upvotes + t.downvotes + t.comment_count)::NUMERIC / t.view_count, 3)
      ELSE 0
    END
  )
  INTO stats
  FROM threads t
  WHERE t.id = thread_uuid;

  RETURN COALESCE(stats, '{}'::JSONB);
END;
$$ LANGUAGE plpgsql STABLE;

-- Get user stats and level info
CREATE OR REPLACE FUNCTION get_user_stats(user_uuid UUID)
RETURNS JSONB AS $$
DECLARE
  stats JSONB;
BEGIN
  SELECT jsonb_build_object(
    'level', u.level,
    'xp', u.xp,
    'trust_score', u.trust_score,
    'thread_count', u.post_count,
    'comment_count', u.comment_count,
    'helpful_votes', u.helpful_votes,
    'badge_count', (
      SELECT COUNT(*) FROM user_badges WHERE user_id = u.id
    ),
    'is_moderator', (
      SELECT EXISTS(SELECT 1 FROM moderators WHERE user_id = u.id AND is_active = TRUE)
    ),
    'next_level_xp', CASE
      WHEN u.level = 1 THEN 100
      WHEN u.level = 2 THEN 500
      WHEN u.level = 3 THEN 2000
      WHEN u.level = 4 THEN 5000
      ELSE NULL
    END,
    'account_status', u.account_status
  )
  INTO stats
  FROM users u
  WHERE u.id = user_uuid;

  RETURN COALESCE(stats, '{}'::JSONB);
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- SEARCH FUNCTIONS
-- ============================================================================

-- Full-text search for threads
CREATE OR REPLACE FUNCTION search_threads(
  search_query TEXT,
  category_filter UUID DEFAULT NULL,
  limit_count INTEGER DEFAULT 20,
  offset_count INTEGER DEFAULT 0
)
RETURNS TABLE(
  id UUID,
  title TEXT,
  content TEXT,
  category_name TEXT,
  author_username TEXT,
  hot_score DECIMAL,
  created_at TIMESTAMP,
  rank REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id,
    t.title,
    t.content,
    c.name as category_name,
    u.username as author_username,
    t.hot_score,
    t.created_at,
    ts_rank(to_tsvector('english', t.title || ' ' || COALESCE(t.content, '')), plainto_tsquery('english', search_query)) as rank
  FROM threads t
  JOIN categories c ON c.id = t.category_id
  JOIN users u ON u.id = t.user_id
  WHERE
    t.is_removed = FALSE
    AND t.is_spam = FALSE
    AND (category_filter IS NULL OR t.category_id = category_filter)
    AND (
      to_tsvector('english', t.title || ' ' || COALESCE(t.content, '')) @@ plainto_tsquery('english', search_query)
    )
  ORDER BY rank DESC, t.hot_score DESC
  LIMIT limit_count OFFSET offset_count;
END;
$$ LANGUAGE plpgsql STABLE;