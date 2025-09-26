-- ============================================
-- MIGRATION: Row Level Security Policies
-- Comprehensive RLS policies from the plan
-- ============================================

-- Enable RLS on all tables that need it
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE thread_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comment_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bot_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE moderators ENABLE ROW LEVEL SECURITY;

-- Users can read all non-shadowbanned users
CREATE POLICY "Users can view active users" ON users
    FOR SELECT
    USING (account_status != 'shadowbanned' OR id = auth.uid());

-- Users can only update their own profile
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- Anyone can read non-removed threads
CREATE POLICY "Public threads are viewable" ON threads
    FOR SELECT
    USING (is_removed = false OR user_id = auth.uid());

-- Only authenticated users at level 2+ can create threads
CREATE POLICY "Level 2+ users can create threads" ON threads
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid()
            AND level >= 2
            AND account_status = 'active'
        )
    );

-- Users can edit their own threads within 1 hour
CREATE POLICY "Users can edit own recent threads" ON threads
    FOR UPDATE
    USING (
        user_id = auth.uid()
        AND created_at > NOW() - INTERVAL '1 hour'
        AND edit_count < 3
    );

-- Moderators can moderate threads in their category
CREATE POLICY "Moderators can moderate threads" ON threads
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM moderators
            WHERE user_id = auth.uid()
            AND category_id = threads.category_id
            AND is_active = true
        )
    );

-- Similar policies for comments
CREATE POLICY "Public comments are viewable" ON comments
    FOR SELECT
    USING (is_removed = false OR user_id = auth.uid());

CREATE POLICY "Level 2+ users can create comments" ON comments
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid()
            AND level >= 2
            AND account_status = 'active'
        )
    );

CREATE POLICY "Users can edit own recent comments" ON comments
    FOR UPDATE
    USING (
        user_id = auth.uid()
        AND created_at > NOW() - INTERVAL '1 hour'
        AND edit_count < 3
    );

-- Voting policies
CREATE POLICY "Users can vote on threads" ON thread_votes
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid()
            AND account_status = 'active'
        )
    );

CREATE POLICY "Users can vote on comments" ON comment_votes
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid()
            AND account_status = 'active'
        )
    );

-- Bot report policies
CREATE POLICY "Users can report suspected bots" ON bot_reports
    FOR INSERT
    WITH CHECK (
        reporter_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid()
            AND account_status = 'active'
            AND level >= 3
        )
    );

CREATE POLICY "Users can view bot reports" ON bot_reports
    FOR SELECT
    USING (
        reporter_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM moderators
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

-- Moderator policies
CREATE POLICY "Moderators are publicly visible" ON moderators
    FOR SELECT
    USING (is_active = true);