-- ============================================
-- MIGRATION: Maintenance and Utility Functions
-- Cleanup and scoring functions from the plan
-- ============================================

-- Function to clean up expired sessions (from plan)
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS void AS $$
BEGIN
    DELETE FROM user_sessions WHERE expires_at < NOW();
    DELETE FROM temporary_bans WHERE expires_at < NOW() AND is_active = true;
    DELETE FROM user_warnings WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to update hot threads (from plan)
CREATE OR REPLACE FUNCTION update_hot_threads()
RETURNS void AS $$
BEGIN
    UPDATE threads
    SET hot_score = calculate_hot_score(upvotes, downvotes, created_at),
        is_hot = (calculate_hot_score(upvotes, downvotes, created_at) > 5)
    WHERE created_at > NOW() - INTERVAL '7 days'
    AND is_removed = false;
END;
$$ LANGUAGE plpgsql;

-- Function to archive old notifications (from plan)
CREATE OR REPLACE FUNCTION archive_old_notifications()
RETURNS void AS $$
BEGIN
    DELETE FROM notifications
    WHERE created_at < NOW() - INTERVAL '90 days'
    AND is_read = true;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate trust scores (from plan)
CREATE OR REPLACE FUNCTION recalculate_trust_scores()
RETURNS void AS $$
BEGIN
    -- This implements the trust score calculation logic from the plan
    -- Simplified example:
    UPDATE users u
    SET trust_score = LEAST(100, GREATEST(0,
        50 -- base score
        + LEAST(20, EXTRACT(DAY FROM NOW() - u.created_at) * 0.1) -- age bonus
        + (SELECT COUNT(*) * 2 FROM bot_reports br
           WHERE br.reported_user_id = u.id
           AND br.status = 'confirmed') -- successful reports
        - (SELECT COUNT(*) * 10 FROM user_warnings w
           WHERE w.user_id = u.id
           AND w.expires_at > NOW()) -- active warnings
    ))
    WHERE account_status = 'active';
END;
$$ LANGUAGE plpgsql;