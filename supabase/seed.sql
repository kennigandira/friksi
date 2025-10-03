-- Seed Data for Friksi
-- Simple seed data for development and testing

-- ============================================================================
-- DEFAULT CATEGORIES
-- ============================================================================

-- Insert root categories without ltree path (will be handled by triggers)
INSERT INTO categories (name, slug, description, color, is_default, is_active) VALUES
    ('General Discussion', 'general', 'General topics and conversations', '#6b7280', true, true),
    ('Technology', 'tech', 'Technology news and discussions', '#3b82f6', true, true),
    ('Politics', 'politics', 'Political discussions and debates', '#ef4444', false, true),
    ('Science', 'science', 'Scientific discoveries and research', '#10b981', true, true),
    ('Entertainment', 'entertainment', 'Movies, TV, music, and more', '#f59e0b', true, true),
    ('Sports', 'sports', 'Sports news and discussions', '#8b5cf6', false, true),
    ('Municipal Affairs', 'municipal-affairs', 'Local government and city services', '#1e40af', true, true),
    ('Community Events', 'community-events', 'Local events and gatherings', '#059669', true, true),
    ('Infrastructure', 'infrastructure', 'Roads, utilities, and city infrastructure', '#dc2626', true, true),
    ('Public Safety', 'public-safety', 'Police, fire, and emergency services', '#7c2d12', true, true),
    ('Environment', 'environment', 'Environmental issues and sustainability', '#166534', true, true),
    ('Education', 'education', 'Schools and educational programs', '#7c3aed', true, true);

-- ============================================================================
-- SAMPLE USERS
-- ============================================================================

-- Insert sample users (email is required by NOT NULL constraint)
INSERT INTO users (id, username, email, level, xp, trust_score)
VALUES
    ('00000000-0000-0000-0000-000000000001'::uuid, 'admin', 'admin@friksi.local', 5, 10000, 100.00),
    ('00000000-0000-0000-0000-000000000002'::uuid, 'citymod', 'citymod@friksi.local', 5, 7500, 95.00),
    ('00000000-0000-0000-0000-000000000003'::uuid, 'activecitizen', 'activecitizen@friksi.local', 4, 3000, 85.00),
    ('00000000-0000-0000-0000-000000000004'::uuid, 'newcomer', 'newcomer@friksi.local', 2, 150, 55.00),
    ('00000000-0000-0000-0000-000000000005'::uuid, 'quietobserver', 'quietobserver@friksi.local', 1, 25, 50.00)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- SAMPLE THREADS
-- ============================================================================

-- Add sample threads (simpler version)
INSERT INTO threads (title, content, category_id, user_id, upvotes, downvotes, view_count, is_pinned)
SELECT
    'Welcome to Friksi - Community Guidelines',
    'Welcome to Friksi, our democratic discussion platform! This platform is designed to foster meaningful civic engagement and community discussions.',
    id,
    '00000000-0000-0000-0000-000000000001'::uuid,
    42,
    2,
    523,
    true
FROM categories WHERE slug = 'general';

INSERT INTO threads (title, content, category_id, user_id, upvotes, downvotes, view_count)
SELECT
    'City Budget Meeting - Public Input Needed',
    'The city council is holding a public budget meeting next Tuesday at 7 PM.',
    id,
    '00000000-0000-0000-0000-000000000002'::uuid,
    15,
    2,
    234
FROM categories WHERE slug = 'municipal-affairs';

INSERT INTO threads (title, content, category_id, user_id, upvotes, downvotes, view_count)
SELECT
    'Potholes on Main Street Getting Worse',
    'The potholes on Main Street between 5th and 8th Avenue are getting really bad.',
    id,
    '00000000-0000-0000-0000-000000000004'::uuid,
    23,
    1,
    156
FROM categories WHERE slug = 'infrastructure';

-- ============================================================================
-- DISPLAY SUMMARY
-- ============================================================================

DO $$
DECLARE
    cat_count INTEGER;
    thread_count INTEGER;
    user_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO cat_count FROM categories;
    SELECT COUNT(*) INTO thread_count FROM threads;
    SELECT COUNT(*) INTO user_count FROM users;

    RAISE NOTICE '';
    RAISE NOTICE '===== Seed Data Summary =====';
    RAISE NOTICE 'Categories created: %', cat_count;
    RAISE NOTICE 'Threads created: %', thread_count;
    RAISE NOTICE 'Users created: %', user_count;
    RAISE NOTICE '=============================';
END $$;