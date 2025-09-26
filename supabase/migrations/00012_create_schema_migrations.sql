-- ============================================
-- MIGRATION: Create Schema Migrations Table
-- Version tracking for database migrations
-- ============================================

-- Schema version tracking
CREATE TABLE IF NOT EXISTS schema_migrations (
    version INTEGER PRIMARY KEY,
    description TEXT,
    applied_at TIMESTAMP DEFAULT NOW()
);

-- Insert migration records for all the migrations we've created
INSERT INTO schema_migrations (version, description) VALUES
(1, 'Initial schema with self-referencing categories'),
(4, 'Update categories with LTREE path tracking and access controls'),
(5, 'Update users with ban management columns'),
(6, 'Update threads with edit tracking and activity timestamps'),
(7, 'Update comments with constraints and edit tracking'),
(8, 'Update bot detection with strikes system'),
(9, 'Create missing tables part 1 - Edit history and moderation'),
(10, 'Create missing tables part 2 - Polls and level unlocks'),
(11, 'Create missing tables part 3 - Analytics and AI usage'),
(12, 'Create schema migrations table')
ON CONFLICT (version) DO NOTHING;