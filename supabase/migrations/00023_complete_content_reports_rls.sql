-- ============================================
-- Migration: 00023_complete_content_reports_rls.sql
-- Add complete RLS policies for content_reports table
-- ============================================

-- Ensure RLS is enabled on content_reports
ALTER TABLE content_reports ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to recreate them properly
DROP POLICY IF EXISTS "Users can view own content reports" ON content_reports;
DROP POLICY IF EXISTS "Moderators can view content reports" ON content_reports;
DROP POLICY IF EXISTS "Level 3+ users can create content reports" ON content_reports;
DROP POLICY IF EXISTS "Moderators can update content reports" ON content_reports;

-- ============================================
-- SELECT Policies
-- ============================================

-- Users can view their own reports
CREATE POLICY "Users can view own reports"
ON content_reports
FOR SELECT
USING (reporter_id = auth.uid());

-- Moderators can view all reports
CREATE POLICY "Moderators can view all reports"
ON content_reports
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM moderators
    WHERE user_id = auth.uid()
    AND is_active = true
  )
);

-- ============================================
-- INSERT Policies
-- ============================================

-- Level 3+ users can create reports
CREATE POLICY "Level 3+ users can create reports"
ON content_reports
FOR INSERT
WITH CHECK (
  reporter_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND level >= 3
    AND account_status = 'active'
  )
);

-- ============================================
-- UPDATE Policies
-- ============================================

-- Moderators can update report status
CREATE POLICY "Moderators can update report status"
ON content_reports
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM moderators
    WHERE user_id = auth.uid()
    AND is_active = true
  )
)
WITH CHECK (
  -- Moderators can update reports
  EXISTS (
    SELECT 1 FROM moderators
    WHERE user_id = auth.uid()
    AND is_active = true
  )
);

-- Users cannot update their own reports after submission
-- (No policy for regular users to UPDATE)

-- ============================================
-- DELETE Policies
-- ============================================

-- Only system admins can delete reports (no policy = no access)
-- This ensures reports are retained for audit purposes

-- ============================================
-- Additional Security Measures
-- ============================================

-- Add rate limiting for report creation
CREATE OR REPLACE FUNCTION check_report_rate_limit()
RETURNS TRIGGER AS $$
DECLARE
  recent_reports INT;
BEGIN
  -- Count reports by this user in the last hour
  SELECT COUNT(*) INTO recent_reports
  FROM content_reports
  WHERE reporter_id = NEW.reporter_id
    AND created_at > NOW() - INTERVAL '1 hour';

  -- Limit to 10 reports per hour
  IF recent_reports >= 10 THEN
    RAISE EXCEPTION 'Report rate limit exceeded. Maximum 10 reports per hour.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for rate limiting
DROP TRIGGER IF EXISTS enforce_report_rate_limit ON content_reports;
CREATE TRIGGER enforce_report_rate_limit
BEFORE INSERT ON content_reports
FOR EACH ROW
EXECUTE FUNCTION check_report_rate_limit();

-- Add function to check for duplicate reports
CREATE OR REPLACE FUNCTION prevent_duplicate_reports()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if the same user already reported the same content
  IF EXISTS (
    SELECT 1 FROM content_reports
    WHERE reporter_id = NEW.reporter_id
      AND content_type = NEW.content_type
      AND content_id = NEW.content_id
      AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'You have already reported this content.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for duplicate prevention
DROP TRIGGER IF EXISTS prevent_duplicate_reports_trigger ON content_reports;
CREATE TRIGGER prevent_duplicate_reports_trigger
BEFORE INSERT ON content_reports
FOR EACH ROW
EXECUTE FUNCTION prevent_duplicate_reports();

-- ============================================
-- Indexes for Performance
-- ============================================

-- Index for reporter lookups
CREATE INDEX IF NOT EXISTS idx_content_reports_reporter
ON content_reports(reporter_id);

-- Index for content lookups
CREATE INDEX IF NOT EXISTS idx_content_reports_content
ON content_reports(content_type, content_id);

-- Index for status filtering
CREATE INDEX IF NOT EXISTS idx_content_reports_status
ON content_reports(status);

-- Index for moderator dashboard (status + created_at)
CREATE INDEX IF NOT EXISTS idx_content_reports_moderation
ON content_reports(status, created_at DESC);