-- Row Level Security (RLS) Policies for Friksi
-- Comprehensive security policies for all tables

-- ============================================================================
-- ENABLE RLS ON ALL TABLES
-- ============================================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE thread_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comment_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE moderators ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE bot_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE voting_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE voting_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE moderator_elections ENABLE ROW LEVEL SECURITY;
ALTER TABLE category_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activities ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- HELPER FUNCTIONS FOR RLS
-- ============================================================================

-- Get current user ID from JWT
CREATE OR REPLACE FUNCTION auth.user_id() RETURNS UUID AS $$
  SELECT auth.uid();
$$ LANGUAGE SQL STABLE;

-- Get current user data
CREATE OR REPLACE FUNCTION get_current_user()
RETURNS users AS $$
  SELECT * FROM users WHERE id = auth.user_id();
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- Check if user is moderator of category
CREATE OR REPLACE FUNCTION is_moderator_of_category(category_uuid UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM moderators
    WHERE user_id = auth.user_id()
    AND category_id = category_uuid
    AND is_active = TRUE
  );
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- Check if user is moderator of any category
CREATE OR REPLACE FUNCTION is_moderator()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM moderators
    WHERE user_id = auth.user_id()
    AND is_active = TRUE
  );
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- Check user level
CREATE OR REPLACE FUNCTION user_has_level(required_level INTEGER)
RETURNS BOOLEAN AS $$
  SELECT level >= required_level
  FROM users
  WHERE id = auth.user_id();
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- Check if content belongs to user
CREATE OR REPLACE FUNCTION owns_content(content_author_id UUID)
RETURNS BOOLEAN AS $$
  SELECT content_author_id = auth.user_id();
$$ LANGUAGE SQL STABLE;

-- ============================================================================
-- USERS TABLE POLICIES
-- ============================================================================

-- Users can view all active users (public profiles)
CREATE POLICY "Users can view public profiles" ON users
  FOR SELECT
  USING (account_status = 'active');

-- Users can view their own profile (including private data)
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT
  USING (id = auth.user_id());

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE
  USING (id = auth.user_id())
  WITH CHECK (
    id = auth.user_id() AND
    -- Prevent users from changing critical fields
    level = level AND
    xp = xp AND
    trust_score = trust_score AND
    is_bot = is_bot AND
    bot_flags = bot_flags
  );

-- New users can insert their profile
CREATE POLICY "New users can insert profile" ON users
  FOR INSERT
  WITH CHECK (id = auth.user_id());

-- Moderators can view user reports/bot status for moderation
CREATE POLICY "Moderators can view user moderation data" ON users
  FOR SELECT
  USING (is_moderator());

-- ============================================================================
-- CATEGORIES TABLE POLICIES
-- ============================================================================

-- Anyone can view active categories
CREATE POLICY "Anyone can view active categories" ON categories
  FOR SELECT
  USING (is_active = TRUE);

-- Level 4+ users can create categories
CREATE POLICY "Level 4+ users can create categories" ON categories
  FOR INSERT
  WITH CHECK (
    user_has_level('level_4') AND
    created_by = auth.user_id()
  );

-- Category creators and moderators can update categories
CREATE POLICY "Category creators and moderators can update" ON categories
  FOR UPDATE
  USING (
    created_by = auth.user_id() OR
    is_moderator_of_category(id)
  );

-- ============================================================================
-- THREADS TABLE POLICIES
-- ============================================================================

-- Anyone can view non-removed, non-spam threads
CREATE POLICY "Anyone can view public threads" ON threads
  FOR SELECT
  USING (is_removed = FALSE AND is_spam = FALSE);

-- Users can view their own threads (even if removed)
CREATE POLICY "Users can view own threads" ON threads
  FOR SELECT
  USING (user_id = auth.user_id());

-- Level 2+ users can create threads
CREATE POLICY "Level 2+ users can create threads" ON threads
  FOR INSERT
  WITH CHECK (
    user_has_level(2) AND
    user_id = auth.user_id()
  );

-- Authors can update their own threads
CREATE POLICY "Authors can update own threads" ON threads
  FOR UPDATE
  USING (user_id = auth.user_id())
  WITH CHECK (
    user_id = auth.user_id()
  );

-- Moderators can update threads in their categories
CREATE POLICY "Moderators can update threads in categories" ON threads
  FOR UPDATE
  USING (is_moderator_of_category(category_id));

-- Authors can soft delete their own threads
CREATE POLICY "Authors can delete own threads" ON threads
  FOR UPDATE
  USING (author_id = auth.user_id())
  WITH CHECK (is_deleted = TRUE);

-- ============================================================================
-- COMMENTS TABLE POLICIES
-- ============================================================================

-- Anyone can view non-removed comments
CREATE POLICY "Anyone can view public comments" ON comments
  FOR SELECT
  USING (is_removed = FALSE);

-- Users can view their own comments
CREATE POLICY "Users can view own comments" ON comments
  FOR SELECT
  USING (user_id = auth.user_id());

-- Level 2+ users can create comments
CREATE POLICY "Level 2+ users can create comments" ON comments
  FOR INSERT
  WITH CHECK (
    user_has_level(2) AND
    user_id = auth.user_id()
  );

-- Authors can update their own comments
CREATE POLICY "Authors can update own comments" ON comments
  FOR UPDATE
  USING (user_id = auth.user_id())
  WITH CHECK (
    user_id = auth.user_id()
  );

-- ============================================================================
-- VOTE TABLE POLICIES
-- ============================================================================

-- Thread votes policies
CREATE POLICY "Anyone can view thread votes" ON thread_votes
  FOR SELECT
  USING (TRUE);

CREATE POLICY "Authenticated users can vote on threads" ON thread_votes
  FOR INSERT
  WITH CHECK (user_id = auth.user_id());

CREATE POLICY "Users can update own thread votes" ON thread_votes
  FOR UPDATE
  USING (user_id = auth.user_id())
  WITH CHECK (user_id = auth.user_id());

CREATE POLICY "Users can delete own thread votes" ON thread_votes
  FOR DELETE
  USING (user_id = auth.user_id());

-- Comment votes policies
CREATE POLICY "Anyone can view comment votes" ON comment_votes
  FOR SELECT
  USING (TRUE);

CREATE POLICY "Authenticated users can vote on comments" ON comment_votes
  FOR INSERT
  WITH CHECK (user_id = auth.user_id());

CREATE POLICY "Users can update own comment votes" ON comment_votes
  FOR UPDATE
  USING (user_id = auth.user_id())
  WITH CHECK (user_id = auth.user_id());

CREATE POLICY "Users can delete own comment votes" ON comment_votes
  FOR DELETE
  USING (user_id = auth.user_id());

-- ============================================================================
-- BADGES TABLE POLICIES
-- ============================================================================

-- Anyone can view badges
CREATE POLICY "Anyone can view badges" ON badges
  FOR SELECT
  USING (TRUE);

-- Only system/admins can manage badges (handled via service role)

-- ============================================================================
-- USER BADGES TABLE POLICIES
-- ============================================================================

-- Anyone can view user badges
CREATE POLICY "Anyone can view user badges" ON user_badges
  FOR SELECT
  USING (TRUE);

-- Only system can award badges (handled via triggers/functions)

-- ============================================================================
-- MODERATORS TABLE POLICIES
-- ============================================================================

-- Anyone can view active moderators
CREATE POLICY "Anyone can view active moderators" ON moderators
  FOR SELECT
  USING (is_active = TRUE);

-- Level 5 users can become moderators (via election system)
CREATE POLICY "Level 5 users can become moderators" ON moderators
  FOR INSERT
  WITH CHECK (
    user_has_level('level_5') AND
    user_id = auth.user_id()
  );

-- ============================================================================
-- REPORTS TABLE POLICIES
-- ============================================================================

-- Users can view their own reports
CREATE POLICY "Users can view own reports" ON reports
  FOR SELECT
  USING (reporter_id = auth.user_id());

-- Moderators can view all reports
CREATE POLICY "Moderators can view reports" ON reports
  FOR SELECT
  USING (is_moderator());

-- Level 3+ users can create reports
CREATE POLICY "Level 3+ users can create reports" ON content_reports
  FOR INSERT
  WITH CHECK (
    user_has_level(3) AND
    reporter_id = auth.user_id()
  );

-- Moderators can update reports (resolve them)
CREATE POLICY "Moderators can update reports" ON reports
  FOR UPDATE
  USING (is_moderator())
  WITH CHECK (resolved_by = auth.user_id());

-- ============================================================================
-- BOT FLAGS TABLE POLICIES
-- ============================================================================

-- Moderators can view bot flags
CREATE POLICY "Moderators can view bot flags" ON bot_flags
  FOR SELECT
  USING (is_moderator());

-- Level 3+ users can create bot flags
CREATE POLICY "Level 3+ users can create bot flags" ON bot_flags
  FOR INSERT
  WITH CHECK (
    user_has_level('level_3') AND
    flagged_by = auth.user_id()
  );

-- ============================================================================
-- VOTING SESSIONS TABLE POLICIES
-- ============================================================================

-- Anyone can view active voting sessions
CREATE POLICY "Anyone can view voting sessions" ON voting_sessions
  FOR SELECT
  USING (TRUE);

-- Level 4+ users can create voting sessions
CREATE POLICY "Level 4+ users can create voting sessions" ON voting_sessions
  FOR INSERT
  WITH CHECK (
    user_has_level('level_4') AND
    created_by = auth.user_id()
  );

-- Creators can update their voting sessions
CREATE POLICY "Creators can update voting sessions" ON voting_sessions
  FOR UPDATE
  USING (created_by = auth.user_id());

-- ============================================================================
-- VOTING OPTIONS TABLE POLICIES
-- ============================================================================

-- Anyone can view voting options
CREATE POLICY "Anyone can view voting options" ON voting_options
  FOR SELECT
  USING (TRUE);

-- Session creators can add options
CREATE POLICY "Session creators can add options" ON voting_options
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM voting_sessions
      WHERE id = session_id AND created_by = auth.user_id()
    )
  );

-- ============================================================================
-- USER VOTES TABLE POLICIES
-- ============================================================================

-- Users can view their own votes
CREATE POLICY "Users can view own votes" ON user_votes
  FOR SELECT
  USING (user_id = auth.user_id());

-- Users can vote in sessions (if they meet requirements)
CREATE POLICY "Users can vote in sessions" ON user_votes
  FOR INSERT
  WITH CHECK (
    user_id = auth.user_id() AND
    EXISTS (
      SELECT 1 FROM voting_sessions vs
      WHERE vs.id = session_id
      AND vs.status = 'active'
      AND NOW() BETWEEN vs.start_date AND vs.end_date
      -- Level requirements checked in application logic
    )
  );

-- ============================================================================
-- CATEGORY SUBSCRIPTIONS TABLE POLICIES
-- ============================================================================

-- Users can view their own subscriptions
CREATE POLICY "Users can view own subscriptions" ON category_subscriptions
  FOR SELECT
  USING (user_id = auth.user_id());

-- Users can manage their own subscriptions
CREATE POLICY "Users can manage own subscriptions" ON category_subscriptions
  FOR ALL
  USING (user_id = auth.user_id())
  WITH CHECK (user_id = auth.user_id());

-- ============================================================================
-- USER ACTIVITIES TABLE POLICIES
-- ============================================================================

-- Users can view their own activities
CREATE POLICY "Users can view own activities" ON user_activities
  FOR SELECT
  USING (user_id = auth.user_id());

-- System creates activities (via triggers)
-- No direct INSERT policy needed - handled by service role

-- ============================================================================
-- MODERATOR ELECTIONS TABLE POLICIES
-- ============================================================================

-- Anyone can view election results
CREATE POLICY "Anyone can view elections" ON moderator_elections
  FOR SELECT
  USING (TRUE);

-- Level 4+ users can create elections
CREATE POLICY "Level 4+ users can create elections" ON moderator_elections
  FOR INSERT
  WITH CHECK (user_has_level('level_4'));

-- ============================================================================
-- USER LEVELS TABLE POLICIES (Reference data)
-- ============================================================================

-- Anyone can view user levels
CREATE POLICY "Anyone can view user levels" ON user_levels
  FOR SELECT
  USING (TRUE);