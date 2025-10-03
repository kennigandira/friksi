-- ============================================
-- Migration: Ensure LTREE Extension Exists
-- Description: Creates ltree extension before any other migrations
-- Date: 2025-01-03
-- ============================================

-- Create ltree extension in public schema
-- This MUST be the first migration to ensure ltree is available for all other migrations
CREATE EXTENSION IF NOT EXISTS "ltree" WITH SCHEMA public;

-- Grant usage to roles
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, anon, authenticated, service_role;
