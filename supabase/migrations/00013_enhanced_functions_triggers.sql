-- ============================================
-- MIGRATION: Enhanced Functions and Triggers
-- Advanced trigger functions and automation
-- ============================================

-- Enhanced hot score calculation (from plan)
CREATE OR REPLACE FUNCTION calculate_hot_score(
    upvotes INTEGER,
    downvotes INTEGER,
    created_at TIMESTAMP
) RETURNS DECIMAL AS $$
DECLARE
    score INTEGER;
    order_val DECIMAL;
    sign_val INTEGER;
    seconds DECIMAL;
    epoch CONSTANT INTEGER := 1134028003; -- Reddit epoch
BEGIN
    score := upvotes - downvotes;

    IF score = 0 THEN
        RETURN 0;
    END IF;

    order_val := LOG(10, GREATEST(ABS(score), 1));

    IF score > 0 THEN
        sign_val := 1;
    ELSIF score < 0 THEN
        sign_val := -1;
    ELSE
        sign_val := 0;
    END IF;

    seconds := EXTRACT(EPOCH FROM created_at) - epoch;
    RETURN ROUND(sign_val * order_val + seconds / 45000, 4);
END;
$$ LANGUAGE plpgsql;

-- Update thread last_activity_at when comments are added
CREATE OR REPLACE FUNCTION update_thread_activity()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE threads
    SET last_activity_at = NOW(),
        comment_count = comment_count + 1
    WHERE id = NEW.thread_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for thread activity updates
DROP TRIGGER IF EXISTS update_thread_on_comment ON comments;
CREATE TRIGGER update_thread_on_comment AFTER INSERT ON comments
    FOR EACH ROW EXECUTE FUNCTION update_thread_activity();

-- Update category post counts with proper hierarchy handling
CREATE OR REPLACE FUNCTION update_category_post_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE categories
        SET post_count = post_count + 1
        WHERE id = NEW.category_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE categories
        SET post_count = post_count - 1
        WHERE id = OLD.category_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for category post count updates
DROP TRIGGER IF EXISTS update_category_counts ON threads;
CREATE TRIGGER update_category_counts AFTER INSERT OR DELETE ON threads
    FOR EACH ROW EXECUTE FUNCTION update_category_post_count();

-- Enhanced bot detection update function
CREATE OR REPLACE FUNCTION update_bot_detection()
RETURNS TRIGGER AS $$
DECLARE
    content_length INTEGER;
BEGIN
    content_length := LENGTH(NEW.content);

    -- Insert or update bot detection record
    INSERT INTO bot_detection (user_id, total_post_count, short_post_count)
    VALUES (NEW.user_id, 1, CASE WHEN content_length < 40 THEN 1 ELSE 0 END)
    ON CONFLICT (user_id) DO UPDATE
    SET total_post_count = bot_detection.total_post_count + 1,
        short_post_count = bot_detection.short_post_count +
            CASE WHEN content_length < 40 THEN 1 ELSE 0 END;

    -- Update user post count
    UPDATE users
    SET post_count = post_count + 1
    WHERE id = NEW.user_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for bot detection updates
DROP TRIGGER IF EXISTS track_bot_detection ON threads;
CREATE TRIGGER track_bot_detection AFTER INSERT ON threads
    FOR EACH ROW EXECUTE FUNCTION update_bot_detection();

-- Function to evaluate bot status (from plan)
CREATE OR REPLACE FUNCTION evaluate_bot_status(user_id_param UUID)
RETURNS TABLE(is_bot BOOLEAN, strikes INTEGER, bot_score DECIMAL) AS $$
DECLARE
    total_users INTEGER;
    user_stats RECORD;
    criteria_met INTEGER := 0;
BEGIN
    -- Get total active users for population percentage
    SELECT COUNT(*) INTO total_users
    FROM users
    WHERE account_status = 'active';

    -- Get user bot detection stats
    SELECT * INTO user_stats
    FROM bot_detection
    WHERE user_id = user_id_param;

    -- Check criteria 1: Short posts (70%+)
    IF user_stats.short_post_percentage >= 70 THEN
        criteria_met := criteria_met + 1;
    END IF;

    -- Check criteria 2: Population reports (3.5%+)
    IF (user_stats.bot_reports_count::DECIMAL / total_users) >= 0.035 THEN
        criteria_met := criteria_met + 1;
    END IF;

    -- Check criteria 3: Moderator reports (3+)
    IF user_stats.moderator_reports_count >= 3 THEN
        criteria_met := criteria_met + 1;
    END IF;

    -- Update bot detection record
    UPDATE bot_detection
    SET strikes = criteria_met,
        is_bot = (criteria_met >= 2),
        last_evaluated = NOW()
    WHERE user_id = user_id_param;

    -- Return results
    RETURN QUERY
    SELECT
        (criteria_met >= 2) AS is_bot,
        criteria_met AS strikes,
        user_stats.bot_score;
END;
$$ LANGUAGE plpgsql;