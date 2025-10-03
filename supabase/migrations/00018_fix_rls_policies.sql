-- ============================================
-- Migration: 00018_fix_rls_policies.sql
-- Fix RLS policy table name mismatches
-- ============================================

-- This migration corrects RLS policies that reference incorrect table names
-- and adds RLS policies for newly created tables from migration 00017

-- ============================================
-- DROP INCORRECT POLICIES (if they exist)
-- ============================================

-- Note: Removed DROP POLICY statements for non-existent tables (user_levels, user_activities, voting_options, user_votes, reports, bot_flags)
-- These tables don't exist in the schema and cause migration errors
-- The corrected policies for actual tables (user_activity, voting_entries, session_votes, content_reports) are handled below

-- ============================================
-- CREATE CORRECT POLICIES FOR EXISTING TABLES
-- ============================================

-- user_activity (was incorrectly referenced as user_activities)
DROP POLICY IF EXISTS "Users can view own activity" ON user_activity;
CREATE POLICY "Users can view own activity" ON user_activity
  FOR SELECT
  USING (user_id = auth.uid());

-- voting_entries (was incorrectly referenced as voting_options)
DROP POLICY IF EXISTS "Anyone can view voting entries" ON voting_entries;
CREATE POLICY "Anyone can view voting entries" ON voting_entries
  FOR SELECT
  USING (TRUE);

DROP POLICY IF EXISTS "Session creators can add entries" ON voting_entries;
CREATE POLICY "Session creators can add entries" ON voting_entries
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM voting_sessions
      WHERE id = session_id AND winner_id = auth.uid()
    )
  );

-- session_votes (was incorrectly referenced as user_votes)
DROP POLICY IF EXISTS "Users can view own session votes" ON session_votes;
CREATE POLICY "Users can view own session votes" ON session_votes
  FOR SELECT
  USING (voter_id = auth.uid());

DROP POLICY IF EXISTS "Users can vote in sessions" ON session_votes;
CREATE POLICY "Users can vote in sessions" ON session_votes
  FOR INSERT
  WITH CHECK (
    voter_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM voting_sessions vs
      WHERE vs.id = session_id
      AND vs.status = 'active'
    )
  );

-- content_reports (was incorrectly referenced as reports)
DROP POLICY IF EXISTS "Users can view own content reports" ON content_reports;
CREATE POLICY "Users can view own content reports" ON content_reports
  FOR SELECT
  USING (reporter_id = auth.uid());

DROP POLICY IF EXISTS "Moderators can view content reports" ON content_reports;
CREATE POLICY "Moderators can view content reports" ON content_reports
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM moderators
      WHERE user_id = auth.uid()
      AND is_active = true
    )
  );

DROP POLICY IF EXISTS "Level 3+ users can create content reports" ON content_reports;
CREATE POLICY "Level 3+ users can create content reports" ON content_reports
  FOR INSERT
  WITH CHECK (
    reporter_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND level >= 3
      AND account_status = 'active'
    )
  );

DROP POLICY IF EXISTS "Moderators can update content reports" ON content_reports;
CREATE POLICY "Moderators can update content reports" ON content_reports
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM moderators
      WHERE user_id = auth.uid()
      AND is_active = true
    )
  )
  WITH CHECK (moderator_id = auth.uid());

-- ============================================
-- ADD RLS POLICIES FOR NEW TABLES (from migration 00017)
-- ============================================

-- Enable RLS on all new tables
ALTER TABLE IF EXISTS moderators ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS moderation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_warnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS moderator_elections ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS election_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS moderator_bot_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS spam_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS spam_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS xp_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS voting_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS voting_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS session_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS thread_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS category_digests ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS notification_preferences ENABLE ROW LEVEL SECURITY;

-- Moderators policies
CREATE POLICY "Anyone can view active moderators" ON moderators
  FOR SELECT
  USING (is_active = true);

-- Moderation logs policies
CREATE POLICY "Moderators can view moderation logs" ON moderation_logs
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM moderators
      WHERE user_id = auth.uid()
      AND is_active = true
    )
  );

CREATE POLICY "Moderators can create moderation logs" ON moderation_logs
  FOR INSERT
  WITH CHECK (
    moderator_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM moderators
      WHERE user_id = auth.uid()
      AND is_active = true
    )
  );

-- User warnings policies
CREATE POLICY "Users can view own warnings" ON user_warnings
  FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Moderators can view all warnings" ON user_warnings
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM moderators
      WHERE user_id = auth.uid()
      AND is_active = true
    )
  );

CREATE POLICY "Moderators can issue warnings" ON user_warnings
  FOR INSERT
  WITH CHECK (
    moderator_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM moderators
      WHERE user_id = auth.uid()
      AND is_active = true
    )
  );

-- Moderator elections policies
CREATE POLICY "Anyone can view moderator elections" ON moderator_elections
  FOR SELECT
  USING (TRUE);

CREATE POLICY "Level 4+ users can create elections" ON moderator_elections
  FOR INSERT
  WITH CHECK (
    initiated_by = auth.uid() AND
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND level >= 4
      AND account_status = 'active'
    )
  );

-- Election votes policies
CREATE POLICY "Users can view own election votes" ON election_votes
  FOR SELECT
  USING (voter_id = auth.uid());

CREATE POLICY "Eligible users can vote in elections" ON election_votes
  FOR INSERT
  WITH CHECK (
    voter_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM moderator_elections
      WHERE id = election_id
      AND status = 'active'
    )
  );

-- Moderator bot reports policies
CREATE POLICY "Moderators can view moderator bot reports" ON moderator_bot_reports
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM moderators
      WHERE user_id = auth.uid()
      AND is_active = true
    )
  );

CREATE POLICY "Moderators can create bot reports" ON moderator_bot_reports
  FOR INSERT
  WITH CHECK (
    moderator_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM moderators
      WHERE user_id = auth.uid()
      AND is_active = true
    )
  );

-- Spam patterns policies (system managed)
CREATE POLICY "Anyone can view active spam patterns" ON spam_patterns
  FOR SELECT
  USING (is_active = true);

-- Spam logs policies (system managed, moderators can view)
CREATE POLICY "Moderators can view spam logs" ON spam_logs
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM moderators
      WHERE user_id = auth.uid()
      AND is_active = true
    )
  );

-- Badges policies
CREATE POLICY "Anyone can view active badges" ON badges
  FOR SELECT
  USING (is_active = true OR NOT is_secret);

-- User badges policies
CREATE POLICY "Anyone can view user badges" ON user_badges
  FOR SELECT
  USING (TRUE);

-- XP transactions policies
CREATE POLICY "Users can view own xp transactions" ON xp_transactions
  FOR SELECT
  USING (user_id = auth.uid());

-- Voting sessions policies
CREATE POLICY "Anyone can view voting sessions" ON voting_sessions
  FOR SELECT
  USING (TRUE);

CREATE POLICY "Level 4+ users can create voting sessions" ON voting_sessions
  FOR INSERT
  WITH CHECK (
    winner_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND level >= 4
      AND account_status = 'active'
    )
  );

-- Thread summaries policies
CREATE POLICY "Anyone can view thread summaries" ON thread_summaries
  FOR SELECT
  USING (TRUE);

-- Category digests policies
CREATE POLICY "Anyone can view category digests" ON category_digests
  FOR SELECT
  USING (TRUE);

-- Notifications policies
CREATE POLICY "Users can view own notifications" ON notifications
  FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications" ON notifications
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Notification preferences policies
CREATE POLICY "Users can manage own notification preferences" ON notification_preferences
  FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());