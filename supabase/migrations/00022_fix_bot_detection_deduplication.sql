-- ============================================
-- Migration: 00022_fix_bot_detection_deduplication.sql
-- Fix bot detection duplicate reports
-- ============================================

-- Add a unique constraint to prevent duplicate reports
ALTER TABLE bot_reports
ADD CONSTRAINT unique_user_reason_per_hour
UNIQUE (user_id, reason, date_trunc('hour', created_at));

-- Update the bot detection function to handle conflicts
CREATE OR REPLACE FUNCTION update_bot_detection()
RETURNS trigger AS $$
DECLARE
  comment_count INT;
  thread_count INT;
  post_count INT;
  avg_length FLOAT;
  time_window INTERVAL := '1 hour';
BEGIN
  -- Count recent comments
  SELECT COUNT(*) INTO comment_count
  FROM comments
  WHERE user_id = NEW.user_id
    AND created_at > NOW() - time_window;

  -- Count recent threads
  SELECT COUNT(*) INTO thread_count
  FROM threads
  WHERE user_id = NEW.user_id
    AND created_at > NOW() - time_window;

  post_count := comment_count + thread_count;

  -- Check posting frequency (deduplication added)
  IF post_count > 10 THEN
    INSERT INTO bot_reports (user_id, reason, confidence)
    VALUES (NEW.user_id, 'High posting frequency', 0.8)
    ON CONFLICT (user_id, reason, date_trunc('hour', created_at))
    DO UPDATE SET
      confidence = GREATEST(bot_reports.confidence, EXCLUDED.confidence),
      updated_at = NOW();
  END IF;

  -- Check for rapid-fire posting (deduplication added)
  IF comment_count > 5 AND NEW.created_at - LAG(NEW.created_at) OVER (PARTITION BY NEW.user_id ORDER BY NEW.created_at) < INTERVAL '30 seconds' THEN
    INSERT INTO bot_reports (user_id, reason, confidence)
    VALUES (NEW.user_id, 'Rapid posting detected', 0.9)
    ON CONFLICT (user_id, reason, date_trunc('hour', created_at))
    DO UPDATE SET
      confidence = GREATEST(bot_reports.confidence, EXCLUDED.confidence),
      updated_at = NOW();
  END IF;

  -- Check content patterns (deduplication added)
  IF LENGTH(NEW.content) < 10 AND post_count > 5 THEN
    INSERT INTO bot_reports (user_id, reason, confidence)
    VALUES (NEW.user_id, 'Short repetitive content', 0.6)
    ON CONFLICT (user_id, reason, date_trunc('hour', created_at))
    DO UPDATE SET
      confidence = GREATEST(bot_reports.confidence, EXCLUDED.confidence),
      updated_at = NOW();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '';

-- Update similar function for thread detection
CREATE OR REPLACE FUNCTION detect_thread_spam()
RETURNS trigger AS $$
DECLARE
  recent_threads INT;
BEGIN
  -- Count threads in last hour
  SELECT COUNT(*) INTO recent_threads
  FROM threads
  WHERE user_id = NEW.user_id
    AND created_at > NOW() - INTERVAL '1 hour';

  IF recent_threads > 5 THEN
    INSERT INTO bot_reports (user_id, reason, confidence)
    VALUES (NEW.user_id, 'Excessive thread creation', 0.7)
    ON CONFLICT (user_id, reason, date_trunc('hour', created_at))
    DO UPDATE SET
      confidence = GREATEST(bot_reports.confidence, EXCLUDED.confidence),
      updated_at = NOW();
  END IF;

  -- Check for duplicate titles (deduplication added)
  IF EXISTS (
    SELECT 1 FROM threads
    WHERE user_id = NEW.user_id
      AND title = NEW.title
      AND id != NEW.id
      AND created_at > NOW() - INTERVAL '24 hours'
  ) THEN
    INSERT INTO bot_reports (user_id, reason, confidence)
    VALUES (NEW.user_id, 'Duplicate thread titles', 0.85)
    ON CONFLICT (user_id, reason, date_trunc('hour', created_at))
    DO UPDATE SET
      confidence = GREATEST(bot_reports.confidence, EXCLUDED.confidence),
      updated_at = NOW();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = '';

-- Add an index for better performance on conflict checking
CREATE INDEX IF NOT EXISTS idx_bot_reports_conflict
ON bot_reports(user_id, reason, date_trunc('hour', created_at));

-- Add updated_at column if it doesn't exist
ALTER TABLE bot_reports
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Update the updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_bot_reports_updated_at ON bot_reports;
CREATE TRIGGER update_bot_reports_updated_at
BEFORE UPDATE ON bot_reports
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();