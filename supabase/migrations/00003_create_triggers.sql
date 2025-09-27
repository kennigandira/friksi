-- Database Triggers for Friksi
-- Automatic updates for hot scores, XP, counters, and LTREE paths

-- ============================================================================
-- THREAD TRIGGERS
-- ============================================================================

-- Update hot score when thread votes change
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
$$ LANGUAGE plpgsql;

-- Trigger for thread hot score updates
DROP TRIGGER IF EXISTS trigger_update_thread_hot_score ON threads;
CREATE TRIGGER trigger_update_thread_hot_score
  AFTER UPDATE OF upvotes, downvotes ON threads
  FOR EACH ROW
  EXECUTE FUNCTION update_thread_hot_score();

-- Update category thread count
CREATE OR REPLACE FUNCTION update_category_thread_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE categories
    SET post_count = post_count + 1
    WHERE id = NEW.category_id;

    -- Award XP for thread creation (temporarily disabled until xp_transactions table exists)
    -- PERFORM award_xp(NEW.user_id, 'thread_created', 'thread', NEW.id);

    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE categories
    SET post_count = post_count - 1
    WHERE id = OLD.category_id;

    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Triggers for category thread count
DROP TRIGGER IF EXISTS trigger_thread_insert ON threads;
CREATE TRIGGER trigger_thread_insert
  AFTER INSERT ON threads
  FOR EACH ROW
  EXECUTE FUNCTION update_category_thread_count();

DROP TRIGGER IF EXISTS trigger_thread_delete ON threads;
CREATE TRIGGER trigger_thread_delete
  AFTER DELETE ON threads
  FOR EACH ROW
  EXECUTE FUNCTION update_category_thread_count();

-- Update thread last activity timestamp
CREATE OR REPLACE FUNCTION update_thread_activity()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE threads
  SET updated_at = NOW()
  WHERE id = NEW.thread_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMMENT TRIGGERS
-- ============================================================================

-- Set comment path and depth on insert
CREATE OR REPLACE FUNCTION set_comment_path()
RETURNS TRIGGER AS $$
DECLARE
  parent_depth INTEGER := 0;
BEGIN
  -- Set path based on parent
  NEW.path := generate_comment_path(NEW.parent_id);

  -- Set depth
  IF NEW.parent_id IS NOT NULL THEN
    SELECT depth + 1 INTO NEW.depth
    FROM comments
    WHERE id = NEW.parent_id;
  ELSE
    NEW.depth := 0;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for comment path setting
DROP TRIGGER IF EXISTS trigger_set_comment_path ON comments;
CREATE TRIGGER trigger_set_comment_path
  BEFORE INSERT ON comments
  FOR EACH ROW
  EXECUTE FUNCTION set_comment_path();

-- Update thread comment count
CREATE OR REPLACE FUNCTION update_thread_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE threads
    SET
      comment_count = comment_count + 1,
      updated_at = NOW()
    WHERE id = NEW.thread_id;

    -- Award XP for comment creation (temporarily disabled until xp_transactions table exists)
    -- PERFORM award_xp(NEW.user_id, 'comment_created', 'comment', NEW.id);

    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE threads
    SET comment_count = comment_count - 1
    WHERE id = OLD.thread_id;

    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Triggers for thread comment count
DROP TRIGGER IF EXISTS trigger_comment_insert ON comments;
CREATE TRIGGER trigger_comment_insert
  AFTER INSERT ON comments
  FOR EACH ROW
  EXECUTE FUNCTION update_thread_comment_count();

DROP TRIGGER IF EXISTS trigger_comment_delete ON comments;
CREATE TRIGGER trigger_comment_delete
  AFTER DELETE ON comments
  FOR EACH ROW
  EXECUTE FUNCTION update_thread_comment_count();

-- Update comment Wilson score
CREATE OR REPLACE FUNCTION update_comment_wilson_score()
RETURNS TRIGGER AS $$
BEGIN
  -- Wilson score calculation disabled until column is added to schema
  -- NEW.wilson_score := calculate_wilson_score(NEW.upvotes, NEW.downvotes);
  NEW.updated_at := NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for comment Wilson score
DROP TRIGGER IF EXISTS trigger_update_comment_wilson_score ON comments;
CREATE TRIGGER trigger_update_comment_wilson_score
  BEFORE UPDATE OF upvotes, downvotes ON comments
  FOR EACH ROW
  EXECUTE FUNCTION update_comment_wilson_score();

-- ============================================================================
-- VOTE TRIGGERS
-- ============================================================================

-- Update thread vote counts when thread votes are created/updated/deleted
CREATE OR REPLACE FUNCTION update_thread_vote_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Update thread vote counts
    IF NEW.vote_type = 'upvote' THEN
      UPDATE threads SET upvotes = upvotes + 1 WHERE id = NEW.thread_id;
    ELSE
      UPDATE threads SET downvotes = downvotes + 1 WHERE id = NEW.thread_id;
    END IF;
    RETURN NEW;
    
  ELSIF TG_OP = 'UPDATE' THEN
    -- Handle vote changes (upvote to downvote or vice versa)
    IF OLD.vote_type != NEW.vote_type THEN
      IF OLD.vote_type = 'upvote' AND NEW.vote_type = 'downvote' THEN
        UPDATE threads SET upvotes = upvotes - 1, downvotes = downvotes + 1 WHERE id = NEW.thread_id;
      ELSIF OLD.vote_type = 'downvote' AND NEW.vote_type = 'upvote' THEN
        UPDATE threads SET upvotes = upvotes + 1, downvotes = downvotes - 1 WHERE id = NEW.thread_id;
      END IF;
    END IF;
    RETURN NEW;
    
  ELSIF TG_OP = 'DELETE' THEN
    -- Remove vote counts
    IF OLD.vote_type = 'upvote' THEN
      UPDATE threads SET upvotes = upvotes - 1 WHERE id = OLD.thread_id;
    ELSE
      UPDATE threads SET downvotes = downvotes - 1 WHERE id = OLD.thread_id;
    END IF;
    RETURN OLD;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Update comment vote counts when comment votes are created/updated/deleted
CREATE OR REPLACE FUNCTION update_comment_vote_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Update comment vote counts
    IF NEW.vote_type = 'upvote' THEN
      UPDATE comments SET upvotes = upvotes + 1 WHERE id = NEW.comment_id;
    ELSE
      UPDATE comments SET downvotes = downvotes + 1 WHERE id = NEW.comment_id;
    END IF;
    RETURN NEW;
    
  ELSIF TG_OP = 'UPDATE' THEN
    -- Handle vote changes (upvote to downvote or vice versa)
    IF OLD.vote_type != NEW.vote_type THEN
      IF OLD.vote_type = 'upvote' AND NEW.vote_type = 'downvote' THEN
        UPDATE comments SET upvotes = upvotes - 1, downvotes = downvotes + 1 WHERE id = NEW.comment_id;
      ELSIF OLD.vote_type = 'downvote' AND NEW.vote_type = 'upvote' THEN
        UPDATE comments SET upvotes = upvotes + 1, downvotes = downvotes - 1 WHERE id = NEW.comment_id;
      END IF;
    END IF;
    RETURN NEW;
    
  ELSIF TG_OP = 'DELETE' THEN
    -- Remove vote counts
    IF OLD.vote_type = 'upvote' THEN
      UPDATE comments SET upvotes = upvotes - 1 WHERE id = OLD.comment_id;
    ELSE
      UPDATE comments SET downvotes = downvotes - 1 WHERE id = OLD.comment_id;
    END IF;
    RETURN OLD;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Triggers for thread vote count updates
DROP TRIGGER IF EXISTS trigger_thread_vote_insert ON thread_votes;
CREATE TRIGGER trigger_thread_vote_insert
  AFTER INSERT ON thread_votes
  FOR EACH ROW
  EXECUTE FUNCTION update_thread_vote_counts();

DROP TRIGGER IF EXISTS trigger_thread_vote_update ON thread_votes;
CREATE TRIGGER trigger_thread_vote_update
  AFTER UPDATE ON thread_votes
  FOR EACH ROW
  EXECUTE FUNCTION update_thread_vote_counts();

DROP TRIGGER IF EXISTS trigger_thread_vote_delete ON thread_votes;
CREATE TRIGGER trigger_thread_vote_delete
  AFTER DELETE ON thread_votes
  FOR EACH ROW
  EXECUTE FUNCTION update_thread_vote_counts();

-- Triggers for comment vote count updates  
DROP TRIGGER IF EXISTS trigger_comment_vote_insert ON comment_votes;
CREATE TRIGGER trigger_comment_vote_insert
  AFTER INSERT ON comment_votes
  FOR EACH ROW
  EXECUTE FUNCTION update_comment_vote_counts();

DROP TRIGGER IF EXISTS trigger_comment_vote_update ON comment_votes;
CREATE TRIGGER trigger_comment_vote_update
  AFTER UPDATE ON comment_votes
  FOR EACH ROW
  EXECUTE FUNCTION update_comment_vote_counts();

DROP TRIGGER IF EXISTS trigger_comment_vote_delete ON comment_votes;
CREATE TRIGGER trigger_comment_vote_delete
  AFTER DELETE ON comment_votes
  FOR EACH ROW
  EXECUTE FUNCTION update_comment_vote_counts();

-- ============================================================================
-- USER TRIGGERS
-- ============================================================================

-- Update user activity timestamp
CREATE OR REPLACE FUNCTION update_user_activity()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users
  SET last_active = NOW()
  WHERE id = NEW.user_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers to update user activity on various actions
DROP TRIGGER IF EXISTS trigger_update_activity_thread ON threads;
CREATE TRIGGER trigger_update_activity_thread
  AFTER INSERT ON threads
  FOR EACH ROW
  EXECUTE FUNCTION update_user_activity();

DROP TRIGGER IF EXISTS trigger_update_activity_comment ON comments;
CREATE TRIGGER trigger_update_activity_comment
  AFTER INSERT ON comments
  FOR EACH ROW
  EXECUTE FUNCTION update_user_activity();

-- Vote activity triggers are handled by separate thread_votes and comment_votes triggers

-- Track post length for bot detection
CREATE OR REPLACE FUNCTION track_post_length()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND TG_TABLE_NAME = 'threads' THEN
    -- Update bot detection table
    INSERT INTO bot_detection (user_id, total_post_count, short_post_count)
    VALUES (NEW.user_id, 1, CASE WHEN LENGTH(COALESCE(NEW.content, '')) < 40 THEN 1 ELSE 0 END)
    ON CONFLICT (user_id) DO UPDATE SET
      total_post_count = bot_detection.total_post_count + 1,
      short_post_count = bot_detection.short_post_count +
        CASE WHEN LENGTH(COALESCE(NEW.content, '')) < 40 THEN 1 ELSE 0 END;

    -- Update user post count
    UPDATE users
    SET post_count = post_count + 1
    WHERE id = NEW.user_id;

    -- Check bot criteria after post
    PERFORM update_bot_status(NEW.user_id);

  ELSIF TG_OP = 'INSERT' AND TG_TABLE_NAME = 'comments' THEN
    -- Update bot detection table
    INSERT INTO bot_detection (user_id, total_post_count, short_post_count)
    VALUES (NEW.user_id, 1, CASE WHEN LENGTH(NEW.content) < 40 THEN 1 ELSE 0 END)
    ON CONFLICT (user_id) DO UPDATE SET
      total_post_count = bot_detection.total_post_count + 1,
      short_post_count = bot_detection.short_post_count +
        CASE WHEN LENGTH(NEW.content) < 40 THEN 1 ELSE 0 END;

    -- Update user comment count
    UPDATE users
    SET comment_count = comment_count + 1
    WHERE id = NEW.user_id;

    -- Check bot criteria after post
    PERFORM update_bot_status(NEW.user_id);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for post length tracking
DROP TRIGGER IF EXISTS trigger_track_thread_length ON threads;
CREATE TRIGGER trigger_track_thread_length
  AFTER INSERT ON threads
  FOR EACH ROW
  EXECUTE FUNCTION track_post_length();

DROP TRIGGER IF EXISTS trigger_track_comment_length ON comments;
CREATE TRIGGER trigger_track_comment_length
  AFTER INSERT ON comments
  FOR EACH ROW
  EXECUTE FUNCTION track_post_length();

-- ============================================================================
-- CATEGORY TRIGGERS
-- ============================================================================

-- Set category path on insert/update (disabled - requires path/level columns and generate_category_path function)
/*
CREATE OR REPLACE FUNCTION set_category_path()
RETURNS TRIGGER AS $$
BEGIN
  -- Set path and level
  NEW.path := generate_category_path(NEW.parent_id);

  -- Calculate level
  IF NEW.parent_id IS NULL THEN
    NEW.level := 0;
  ELSE
    SELECT level + 1 INTO NEW.level
    FROM categories
    WHERE id = NEW.parent_id;
  END IF;

  NEW.updated_at := NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for category path setting
DROP TRIGGER IF EXISTS trigger_set_category_path ON categories;
CREATE TRIGGER trigger_set_category_path
  BEFORE INSERT OR UPDATE OF parent_id ON categories
  FOR EACH ROW
  EXECUTE FUNCTION set_category_path();
*/

-- ============================================================================
-- BOT DETECTION TRIGGERS (disabled - requires bot_flags table)
-- ============================================================================

/*
-- Update bot status when flags are added
CREATE OR REPLACE FUNCTION check_bot_flags()
RETURNS TRIGGER AS $$
BEGIN
  -- Update bot status after flag is added
  PERFORM update_bot_status(NEW.user_id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for bot flag checking
DROP TRIGGER IF EXISTS trigger_check_bot_flags ON bot_flags;
CREATE TRIGGER trigger_check_bot_flags
  AFTER INSERT ON bot_flags
  FOR EACH ROW
  EXECUTE FUNCTION check_bot_flags();
*/

-- ============================================================================
-- BADGE TRIGGERS (disabled - requires badges and user_badges tables)
-- ============================================================================

/*
-- Update badge awarded count
CREATE OR REPLACE FUNCTION update_badge_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE badges
    SET awarded_count = awarded_count + 1
    WHERE id = NEW.badge_id;

    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE badges
    SET awarded_count = awarded_count - 1
    WHERE id = OLD.badge_id;

    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Triggers for badge count
DROP TRIGGER IF EXISTS trigger_badge_awarded ON user_badges;
CREATE TRIGGER trigger_badge_awarded
  AFTER INSERT ON user_badges
  FOR EACH ROW
  EXECUTE FUNCTION update_badge_count();

DROP TRIGGER IF EXISTS trigger_badge_removed ON user_badges;
CREATE TRIGGER trigger_badge_removed
  AFTER DELETE ON user_badges
  FOR EACH ROW
  EXECUTE FUNCTION update_badge_count();
*/

-- ============================================================================
-- SUBSCRIPTION TRIGGERS
-- ============================================================================

-- Update category subscriber count
CREATE OR REPLACE FUNCTION update_subscriber_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE categories
    SET subscriber_count = subscriber_count + 1
    WHERE id = NEW.category_id;

    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE categories
    SET subscriber_count = subscriber_count - 1
    WHERE id = OLD.category_id;

    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Triggers for subscriber count
DROP TRIGGER IF EXISTS trigger_subscription_insert ON category_subscriptions;
CREATE TRIGGER trigger_subscription_insert
  AFTER INSERT ON category_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_subscriber_count();

DROP TRIGGER IF EXISTS trigger_subscription_delete ON category_subscriptions;
CREATE TRIGGER trigger_subscription_delete
  AFTER DELETE ON category_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_subscriber_count();