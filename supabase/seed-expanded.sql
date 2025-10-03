-- ============================================================================
-- EXPANDED SEED DATA FOR FRIKSI
-- Comprehensive test data for development and staging
-- ============================================================================

-- Clean up existing data (optional - comment out for production)
-- TRUNCATE TABLE comments CASCADE;
-- TRUNCATE TABLE threads CASCADE;
-- TRUNCATE TABLE moderators CASCADE;
-- TRUNCATE TABLE users CASCADE;

-- ============================================================================
-- 1. USERS (75 users with varied profiles)
-- ============================================================================

INSERT INTO users (id, username, email, level, xp, trust_score) VALUES
-- Admins and power users (Level 5)
('11111111-0000-0000-0000-000000000001', 'admin', 'admin@friksi.local', 5, 10000, 100.00),
('11111111-0000-0000-0000-000000000002', 'citymod', 'citymod@friksi.local', 5, 9500, 98.00),
('11111111-0000-0000-0000-000000000003', 'supermod', 'supermod@friksi.local', 5, 9000, 96.00),

-- Experienced moderators (Level 4-5)
('11111111-0000-0000-0000-000000000004', 'techguru', 'techguru@friksi.local', 5, 8500, 94.00),
('11111111-0000-0000-0000-000000000005', 'civicleader', 'civicleader@friksi.local', 4, 4500, 88.00),
('11111111-0000-0000-0000-000000000006', 'communityhero', 'communityhero@friksi.local', 4, 4200, 86.00),
('11111111-0000-0000-0000-000000000007', 'localnews', 'localnews@friksi.local', 4, 4000, 85.00),
('11111111-0000-0000-0000-000000000008', 'greenmind', 'greenmind@friksi.local', 4, 3800, 84.00),

-- Active contributors (Level 3-4)
('11111111-0000-0000-0000-000000000009', 'urbanplanner', 'urbanplanner@friksi.local', 4, 3500, 82.00),
('11111111-0000-0000-0000-000000000010', 'sportsfan', 'sportsfan@friksi.local', 3, 1800, 75.00),
('11111111-0000-0000-0000-000000000011', 'educator', 'educator@friksi.local', 3, 1700, 74.00),
('11111111-0000-0000-0000-000000000012', 'safetyfirst', 'safetyfirst@friksi.local', 3, 1600, 73.00),
('11111111-0000-0000-0000-000000000013', 'scienceguy', 'scienceguy@friksi.local', 3, 1500, 72.00),
('11111111-0000-0000-0000-000000000014', 'moviebuff', 'moviebuff@friksi.local', 3, 1400, 71.00),
('11111111-0000-0000-0000-000000000015', 'politicaljunkie', 'politicaljunkie@friksi.local', 3, 1300, 70.00),

-- Regular users (Level 2-3)
('11111111-0000-0000-0000-000000000016', 'johnsmith', 'johnsmith@friksi.local', 3, 1200, 68.00),
('11111111-0000-0000-0000-000000000017', 'janedoe', 'janedoe@friksi.local', 3, 1100, 67.00),
('11111111-0000-0000-0000-000000000018', 'mikebrown', 'mikebrown@friksi.local', 2, 500, 62.00),
('11111111-0000-0000-0000-000000000019', 'sarahwhite', 'sarahwhite@friksi.local', 2, 480, 61.00),
('11111111-0000-0000-0000-000000000020', 'davidlee', 'davidlee@friksi.local', 2, 460, 60.00),
('11111111-0000-0000-0000-000000000021', 'lisagreen', 'lisagreen@friksi.local', 2, 440, 59.00),
('11111111-0000-0000-0000-000000000022', 'tomjones', 'tomjones@friksi.local', 2, 420, 58.00),
('11111111-0000-0000-0000-000000000023', 'amywilson', 'amywilson@friksi.local', 2, 400, 57.00),
('11111111-0000-0000-0000-000000000024', 'chrismiller', 'chrismiller@friksi.local', 2, 380, 56.00),
('11111111-0000-0000-0000-000000000025', 'karenjohnson', 'karenjohnson@friksi.local', 2, 360, 55.00),

-- New users (Level 1-2)
('11111111-0000-0000-0000-000000000026', 'newbie1', 'newbie1@friksi.local', 2, 200, 54.00),
('11111111-0000-0000-0000-000000000027', 'freshuser', 'freshuser@friksi.local', 2, 180, 53.00),
('11111111-0000-0000-0000-000000000028', 'rookie2024', 'rookie2024@friksi.local', 2, 160, 52.00),
('11111111-0000-0000-0000-000000000029', 'beginner99', 'beginner99@friksi.local', 2, 140, 51.00),
('11111111-0000-0000-0000-000000000030', 'learner123', 'learner123@friksi.local', 2, 120, 50.00),
('11111111-0000-0000-0000-000000000031', 'curious_cat', 'curious_cat@friksi.local', 1, 80, 48.00),
('11111111-0000-0000-0000-000000000032', 'silent_reader', 'silent_reader@friksi.local', 1, 60, 47.00),
('11111111-0000-0000-0000-000000000033', 'first_timer', 'first_timer@friksi.local', 1, 40, 46.00),
('11111111-0000-0000-0000-000000000034', 'hello_world', 'hello_world@friksi.local', 1, 30, 45.00),
('11111111-0000-0000-0000-000000000035', 'new_in_town', 'new_in_town@friksi.local', 1, 20, 44.00),

-- Additional diverse users
('11111111-0000-0000-0000-000000000036', 'localartist', 'localartist@friksi.local', 3, 1000, 65.00),
('11111111-0000-0000-0000-000000000037', 'smallbizowner', 'smallbizowner@friksi.local', 3, 950, 64.00),
('11111111-0000-0000-0000-000000000038', 'parentof3', 'parentof3@friksi.local', 2, 340, 54.00),
('11111111-0000-0000-0000-000000000039', 'dogwalker', 'dogwalker@friksi.local', 2, 320, 53.00),
('11111111-0000-0000-0000-000000000040', 'cyclist', 'cyclist@friksi.local', 2, 300, 52.00),
('11111111-0000-0000-0000-000000000041', 'foodie', 'foodie@friksi.local', 2, 280, 51.00),
('11111111-0000-0000-0000-000000000042', 'gardener', 'gardener@friksi.local', 2, 260, 50.00),
('11111111-0000-0000-0000-000000000043', 'bookworm', 'bookworm@friksi.local', 2, 240, 49.00),
('11111111-0000-0000-0000-000000000044', 'photographer', 'photographer@friksi.local', 2, 220, 48.00),
('11111111-0000-0000-0000-000000000045', 'musician', 'musician@friksi.local', 2, 200, 47.00),

-- More community members
('11111111-0000-0000-0000-000000000046', 'retiredteacher', 'retiredteacher@friksi.local', 3, 900, 63.00),
('11111111-0000-0000-0000-000000000047', 'youngpro', 'youngpro@friksi.local', 2, 180, 46.00),
('11111111-0000-0000-0000-000000000048', 'nightowl', 'nightowl@friksi.local', 2, 160, 45.00),
('11111111-0000-0000-0000-000000000049', 'earlybird', 'earlybird@friksi.local', 2, 140, 44.00),
('11111111-0000-0000-0000-000000000050', 'weekendwarrior', 'weekendwarrior@friksi.local', 2, 120, 43.00),
('11111111-0000-0000-0000-000000000051', 'coffee_lover', 'coffee_lover@friksi.local', 1, 100, 42.00),
('11111111-0000-0000-0000-000000000052', 'tea_enthusiast', 'tea_enthusiast@friksi.local', 1, 90, 41.00),
('11111111-0000-0000-0000-000000000053', 'pizza_fan', 'pizza_fan@friksi.local', 1, 80, 40.00),
('11111111-0000-0000-0000-000000000054', 'taco_tuesday', 'taco_tuesday@friksi.local', 1, 70, 39.00),
('11111111-0000-0000-0000-000000000055', 'sushi_master', 'sushi_master@friksi.local', 1, 60, 38.00),

-- Final batch
('11111111-0000-0000-0000-000000000056', 'history_buff', 'history_buff@friksi.local', 2, 110, 42.00),
('11111111-0000-0000-0000-000000000057', 'future_focused', 'future_focused@friksi.local', 2, 100, 41.00),
('11111111-0000-0000-0000-000000000058', 'present_minded', 'present_minded@friksi.local', 1, 50, 37.00),
('11111111-0000-0000-0000-000000000059', 'zen_master', 'zen_master@friksi.local', 1, 45, 36.00),
('11111111-0000-0000-0000-000000000060', 'energy_burst', 'energy_burst@friksi.local', 1, 40, 35.00),
('11111111-0000-0000-0000-000000000061', 'calm_presence', 'calm_presence@friksi.local', 1, 35, 34.00),
('11111111-0000-0000-0000-000000000062', 'storm_chaser', 'storm_chaser@friksi.local', 1, 30, 33.00),
('11111111-0000-0000-0000-000000000063', 'sunshine_soul', 'sunshine_soul@friksi.local', 1, 25, 32.00),
('11111111-0000-0000-0000-000000000064', 'moonlight_walker', 'moonlight_walker@friksi.local', 1, 20, 31.00),
('11111111-0000-0000-0000-000000000065', 'star_gazer', 'star_gazer@friksi.local', 1, 15, 30.00),
('11111111-0000-0000-0000-000000000066', 'cloud_watcher', 'cloud_watcher@friksi.local', 1, 14, 30.00),
('11111111-0000-0000-0000-000000000067', 'rain_dancer', 'rain_dancer@friksi.local', 1, 13, 30.00),
('11111111-0000-0000-0000-000000000068', 'snow_angel', 'snow_angel@friksi.local', 1, 12, 30.00),
('11111111-0000-0000-0000-000000000069', 'summer_breeze', 'summer_breeze@friksi.local', 1, 11, 30.00),
('11111111-0000-0000-0000-000000000070', 'autumn_leaves', 'autumn_leaves@friksi.local', 1, 10, 30.00),
('11111111-0000-0000-0000-000000000071', 'spring_bloom', 'spring_bloom@friksi.local', 1, 9, 30.00),
('11111111-0000-0000-0000-000000000072', 'winter_wonder', 'winter_wonder@friksi.local', 1, 8, 30.00),
('11111111-0000-0000-0000-000000000073', 'time_traveler', 'time_traveler@friksi.local', 1, 7, 30.00),
('11111111-0000-0000-0000-000000000074', 'space_explorer', 'space_explorer@friksi.local', 1, 6, 30.00),
('11111111-0000-0000-0000-000000000075', 'deep_thinker', 'deep_thinker@friksi.local', 1, 5, 30.00)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 2. CATEGORIES (Already exist, just reference them)
-- ============================================================================

-- Ensure we have all categories
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
('Education', 'education', 'Schools and educational programs', '#7c3aed', true, true)
ON CONFLICT (parent_id, slug) DO NOTHING;

-- ============================================================================
-- 3. MODERATORS (Assign moderators to categories)
-- ============================================================================

INSERT INTO moderators (user_id, category_id, elected_at, term_ends_at, votes_received)
SELECT
    u.id as user_id,
    c.id as category_id,
    NOW() - INTERVAL '30 days' as elected_at,
    NOW() + INTERVAL '90 days' as term_ends_at,
    (RANDOM() * 50 + 20)::INT as votes_received
FROM (
    -- General (3 mods)
    SELECT '11111111-0000-0000-0000-000000000002'::uuid as id, 'general' as cat_slug
    UNION SELECT '11111111-0000-0000-0000-000000000003'::uuid, 'general'
    UNION SELECT '11111111-0000-0000-0000-000000000005'::uuid, 'general'
    -- Technology (4 mods)
    UNION SELECT '11111111-0000-0000-0000-000000000004'::uuid, 'tech'
    UNION SELECT '11111111-0000-0000-0000-000000000009'::uuid, 'tech'
    UNION SELECT '11111111-0000-0000-0000-000000000013'::uuid, 'tech'
    UNION SELECT '11111111-0000-0000-0000-000000000016'::uuid, 'tech'
    -- Politics (2 mods)
    UNION SELECT '11111111-0000-0000-0000-000000000015'::uuid, 'politics'
    UNION SELECT '11111111-0000-0000-0000-000000000007'::uuid, 'politics'
    -- Science (3 mods)
    UNION SELECT '11111111-0000-0000-0000-000000000013'::uuid, 'science'
    UNION SELECT '11111111-0000-0000-0000-000000000046'::uuid, 'science'
    UNION SELECT '11111111-0000-0000-0000-000000000008'::uuid, 'science'
    -- Entertainment (2 mods)
    UNION SELECT '11111111-0000-0000-0000-000000000014'::uuid, 'entertainment'
    UNION SELECT '11111111-0000-0000-0000-000000000036'::uuid, 'entertainment'
    -- Sports (1 mod)
    UNION SELECT '11111111-0000-0000-0000-000000000010'::uuid, 'sports'
    -- Municipal Affairs (5 mods)
    UNION SELECT '11111111-0000-0000-0000-000000000006'::uuid, 'municipal-affairs'
    UNION SELECT '11111111-0000-0000-0000-000000000037'::uuid, 'municipal-affairs'
    UNION SELECT '11111111-0000-0000-0000-000000000038'::uuid, 'municipal-affairs'
    UNION SELECT '11111111-0000-0000-0000-000000000017'::uuid, 'municipal-affairs'
    UNION SELECT '11111111-0000-0000-0000-000000000018'::uuid, 'municipal-affairs'
    -- Community Events (3 mods)
    UNION SELECT '11111111-0000-0000-0000-000000000041'::uuid, 'community-events'
    UNION SELECT '11111111-0000-0000-0000-000000000044'::uuid, 'community-events'
    UNION SELECT '11111111-0000-0000-0000-000000000045'::uuid, 'community-events'
    -- Infrastructure (4 mods)
    UNION SELECT '11111111-0000-0000-0000-000000000040'::uuid, 'infrastructure'
    UNION SELECT '11111111-0000-0000-0000-000000000019'::uuid, 'infrastructure'
    UNION SELECT '11111111-0000-0000-0000-000000000020'::uuid, 'infrastructure'
    UNION SELECT '11111111-0000-0000-0000-000000000021'::uuid, 'infrastructure'
    -- Public Safety (2 mods)
    UNION SELECT '11111111-0000-0000-0000-000000000012'::uuid, 'public-safety'
    UNION SELECT '11111111-0000-0000-0000-000000000022'::uuid, 'public-safety'
    -- Environment (3 mods)
    UNION SELECT '11111111-0000-0000-0000-000000000042'::uuid, 'environment'
    UNION SELECT '11111111-0000-0000-0000-000000000043'::uuid, 'environment'
    UNION SELECT '11111111-0000-0000-0000-000000000056'::uuid, 'environment'
    -- Education (0 mods - as requested, some categories have 0)
) as u
JOIN users ON users.id = u.id
JOIN categories c ON c.slug = u.cat_slug
ON CONFLICT (user_id, category_id) DO NOTHING;

-- ============================================================================
-- 4. THREADS (5 per category = 60 threads)
-- ============================================================================

-- General Discussion threads
INSERT INTO threads (id, title, content, category_id, user_id, upvotes, downvotes, view_count, is_pinned, created_at)
SELECT
    gen_random_uuid(),
    t.title,
    t.content,
    c.id,
    t.user_id::uuid,
    t.upvotes,
    t.downvotes,
    t.view_count,
    t.is_pinned,
    NOW() - (t.days_ago || ' days')::interval
FROM categories c
CROSS JOIN (
    VALUES
    ('Welcome to Friksi - Community Guidelines', 'Welcome to our democratic discussion platform! Please read our community guidelines to ensure a positive experience for everyone.', '11111111-0000-0000-0000-000000000001', 45, 2, 523, true, 30),
    ('How to report inappropriate content?', 'I''m new here and wondering what the process is for reporting content that violates community standards?', '11111111-0000-0000-0000-000000000033', 12, 1, 89, false, 15),
    ('Suggestion: Add dark mode to the platform', 'Would love to see a dark mode option for late night browsing. Anyone else interested?', '11111111-0000-0000-0000-000000000026', 38, 5, 234, false, 7),
    ('Monthly town hall meetings - your thoughts?', 'Should we organize monthly virtual town halls to discuss important community matters?', '11111111-0000-0000-0000-000000000005', 67, 8, 412, false, 3),
    ('New member introductions thread', 'Let''s have a thread where new members can introduce themselves to the community!', '11111111-0000-0000-0000-000000000017', 23, 2, 156, false, 1)
) AS t(title, content, user_id, upvotes, downvotes, view_count, is_pinned, days_ago)
WHERE c.slug = 'general';

-- Technology threads
INSERT INTO threads (id, title, content, category_id, user_id, upvotes, downvotes, view_count, created_at)
SELECT
    gen_random_uuid(),
    t.title,
    t.content,
    c.id,
    t.user_id::uuid,
    t.upvotes,
    t.downvotes,
    t.view_count,
    NOW() - (t.days_ago || ' days')::interval
FROM categories c
CROSS JOIN (
    VALUES
    ('Best practices for securing home WiFi networks', 'With more people working from home, let''s discuss how to properly secure our home networks.', '11111111-0000-0000-0000-000000000004', 52, 3, 678, 12),
    ('Local tech meetup - AI and Machine Learning', 'Organizing a meetup next month to discuss AI/ML applications. Who''s interested?', '11111111-0000-0000-0000-000000000013', 41, 2, 345, 8),
    ('Recommendations for learning programming?', 'My teenager wants to learn coding. What resources would you recommend for beginners?', '11111111-0000-0000-0000-000000000038', 28, 1, 234, 5),
    ('City should adopt open-source software', 'I believe our city could save money by using open-source alternatives. Thoughts?', '11111111-0000-0000-0000-000000000009', 35, 12, 456, 2),
    ('5G towers installation concerns', 'New 5G towers being installed downtown. Any health or privacy concerns we should discuss?', '11111111-0000-0000-0000-000000000048', 18, 24, 567, 1)
) AS t(title, content, user_id, upvotes, downvotes, view_count, days_ago)
WHERE c.slug = 'tech';

-- Politics threads
INSERT INTO threads (id, title, content, category_id, user_id, upvotes, downvotes, view_count, created_at)
SELECT
    gen_random_uuid(),
    t.title,
    t.content,
    c.id,
    t.user_id::uuid,
    t.upvotes,
    t.downvotes,
    t.view_count,
    NOW() - (t.days_ago || ' days')::interval
FROM categories c
CROSS JOIN (
    VALUES
    ('Upcoming mayoral election - candidate comparison', 'Let''s objectively compare the mayoral candidates'' platforms and track records.', '11111111-0000-0000-0000-000000000015', 89, 34, 1234, 20),
    ('Property tax increase proposal discussion', 'The city council is proposing a 3% property tax increase. What are your thoughts?', '11111111-0000-0000-0000-000000000007', 45, 67, 890, 14),
    ('Term limits for city council members?', 'Should we implement term limits for our city council? Pros and cons discussion.', '11111111-0000-0000-0000-000000000022', 56, 23, 567, 10),
    ('Voter registration drive this weekend', 'Organizing a non-partisan voter registration drive at the community center.', '11111111-0000-0000-0000-000000000006', 71, 5, 345, 4),
    ('Campaign finance reform needed locally', 'Our local elections are becoming too expensive. Time for campaign finance limits?', '11111111-0000-0000-0000-000000000047', 38, 28, 456, 2)
) AS t(title, content, user_id, upvotes, downvotes, view_count, days_ago)
WHERE c.slug = 'politics';

-- Science threads
INSERT INTO threads (id, title, content, category_id, user_id, upvotes, downvotes, view_count, created_at)
SELECT
    gen_random_uuid(),
    t.title,
    t.content,
    c.id,
    t.user_id::uuid,
    t.upvotes,
    t.downvotes,
    t.view_count,
    NOW() - (t.days_ago || ' days')::interval
FROM categories c
CROSS JOIN (
    VALUES
    ('Local university discovers new antibiotic compound', 'Exciting news from our university''s research department! They''ve identified a promising new antibiotic.', '11111111-0000-0000-0000-000000000013', 72, 1, 456, 18),
    ('Climate change impacts on our region', 'New study shows specific impacts climate change will have on our local ecosystem.', '11111111-0000-0000-0000-000000000008', 64, 8, 678, 11),
    ('Science fair judges needed', 'The high school science fair needs volunteer judges with STEM backgrounds.', '11111111-0000-0000-0000-000000000046', 31, 0, 234, 6),
    ('Astronomy club stargazing event', 'Join us this Friday for stargazing at the observatory. Jupiter will be visible!', '11111111-0000-0000-0000-000000000065', 45, 2, 345, 3),
    ('COVID vaccine clinic opening next week', 'Free vaccines available at the community health center starting Monday.', '11111111-0000-0000-0000-000000000012', 58, 12, 789, 1)
) AS t(title, content, user_id, upvotes, downvotes, view_count, days_ago)
WHERE c.slug = 'science';

-- Entertainment threads
INSERT INTO threads (id, title, content, category_id, user_id, upvotes, downvotes, view_count, created_at)
SELECT
    gen_random_uuid(),
    t.title,
    t.content,
    c.id,
    t.user_id::uuid,
    t.upvotes,
    t.downvotes,
    t.view_count,
    NOW() - (t.days_ago || ' days')::interval
FROM categories c
CROSS JOIN (
    VALUES
    ('Local film festival submissions open', 'Our annual film festival is accepting submissions until next month!', '11111111-0000-0000-0000-000000000014', 42, 1, 345, 22),
    ('Book club starting - join us!', 'Starting a monthly book club at the library. First book: "The Midnight Library"', '11111111-0000-0000-0000-000000000043', 28, 2, 234, 16),
    ('Community theater needs volunteers', 'Help needed for our production of "Our Town" - both on and off stage roles available.', '11111111-0000-0000-0000-000000000036', 35, 0, 267, 9),
    ('Best local restaurants - share your favorites', 'Let''s create a list of must-try local restaurants and hidden gems!', '11111111-0000-0000-0000-000000000041', 67, 3, 890, 4),
    ('Free outdoor concert series this summer', 'The city is organizing free concerts in the park every Friday evening.', '11111111-0000-0000-0000-000000000045', 89, 1, 1234, 2)
) AS t(title, content, user_id, upvotes, downvotes, view_count, days_ago)
WHERE c.slug = 'entertainment';

-- Sports threads
INSERT INTO threads (id, title, content, category_id, user_id, upvotes, downvotes, view_count, created_at)
SELECT
    gen_random_uuid(),
    t.title,
    t.content,
    c.id,
    t.user_id::uuid,
    t.upvotes,
    t.downvotes,
    t.view_count,
    NOW() - (t.days_ago || ' days')::interval
FROM categories c
CROSS JOIN (
    VALUES
    ('Youth soccer league registration open', 'Sign-ups for the spring youth soccer league are now open. Ages 6-14 welcome!', '11111111-0000-0000-0000-000000000010', 34, 1, 456, 25),
    ('New bike trails opening next month', 'The city is opening 15 miles of new bike trails. Map and details inside.', '11111111-0000-0000-0000-000000000040', 56, 2, 678, 17),
    ('Local high school wins state championship!', 'Congratulations to Central High for winning the state basketball championship!', '11111111-0000-0000-0000-000000000010', 123, 3, 2345, 10),
    ('Adult softball league forming', 'Looking for players for a recreational softball league. All skill levels welcome.', '11111111-0000-0000-0000-000000000050', 28, 1, 345, 5),
    ('Community 5K run for charity', 'Annual charity 5K happening next month. Register now to support local food bank.', '11111111-0000-0000-0000-000000000010', 45, 0, 567, 3)
) AS t(title, content, user_id, upvotes, downvotes, view_count, days_ago)
WHERE c.slug = 'sports';

-- Municipal Affairs threads
INSERT INTO threads (id, title, content, category_id, user_id, upvotes, downvotes, view_count, created_at)
SELECT
    gen_random_uuid(),
    t.title,
    t.content,
    c.id,
    t.user_id::uuid,
    t.upvotes,
    t.downvotes,
    t.view_count,
    NOW() - (t.days_ago || ' days')::interval
FROM categories c
CROSS JOIN (
    VALUES
    ('City budget meeting - public input needed', 'The city council is holding a public budget meeting next Tuesday at 7 PM.', '11111111-0000-0000-0000-000000000006', 78, 5, 1234, 21),
    ('Zoning change proposal for downtown', 'Proposed zoning changes would allow mixed-use development downtown. Comments?', '11111111-0000-0000-0000-000000000037', 45, 23, 890, 15),
    ('New parking meters installation feedback', 'The city installed new smart parking meters. Share your experience and feedback.', '11111111-0000-0000-0000-000000000018', 23, 34, 567, 8),
    ('Water quality report released', 'Annual water quality report shows all parameters within safe limits. Full report linked.', '11111111-0000-0000-0000-000000000005', 67, 2, 456, 4),
    ('Trash collection schedule changing', 'Starting next month, trash collection moves to Wednesdays. Recycling stays on Fridays.', '11111111-0000-0000-0000-000000000017', 89, 12, 789, 1)
) AS t(title, content, user_id, upvotes, downvotes, view_count, days_ago)
WHERE c.slug = 'municipal-affairs';

-- Community Events threads
INSERT INTO threads (id, title, content, category_id, user_id, upvotes, downvotes, view_count, created_at)
SELECT
    gen_random_uuid(),
    t.title,
    t.content,
    c.id,
    t.user_id::uuid,
    t.upvotes,
    t.downvotes,
    t.view_count,
    NOW() - (t.days_ago || ' days')::interval
FROM categories c
CROSS JOIN (
    VALUES
    ('Annual Harvest Festival next weekend!', 'Don''t miss our biggest community event of the year! Food, music, and fun for all ages.', '11111111-0000-0000-0000-000000000041', 134, 2, 2456, 23),
    ('Farmers market now open Saturdays', 'Local farmers market open every Saturday 8am-2pm at the town square.', '11111111-0000-0000-0000-000000000044', 67, 1, 890, 14),
    ('Community garage sale May 15-16', 'Annual community-wide garage sale. Register your address to be on the map.', '11111111-0000-0000-0000-000000000045', 45, 3, 678, 7),
    ('Volunteer opportunities at food bank', 'Food bank needs volunteers for Tuesday and Thursday shifts. Can you help?', '11111111-0000-0000-0000-000000000038', 56, 0, 456, 3),
    ('Art walk this First Friday', 'Monthly art walk featuring local artists. Free wine and cheese at participating galleries.', '11111111-0000-0000-0000-000000000036', 78, 2, 789, 1)
) AS t(title, content, user_id, upvotes, downvotes, view_count, days_ago)
WHERE c.slug = 'community-events';

-- Infrastructure threads
INSERT INTO threads (id, title, content, category_id, user_id, upvotes, downvotes, view_count, created_at)
SELECT
    gen_random_uuid(),
    t.title,
    t.content,
    c.id,
    t.user_id::uuid,
    t.upvotes,
    t.downvotes,
    t.view_count,
    NOW() - (t.days_ago || ' days')::interval
FROM categories c
CROSS JOIN (
    VALUES
    ('Main Street potholes getting worse', 'The potholes on Main Street between 5th and 8th are dangerous. When will they be fixed?', '11111111-0000-0000-0000-000000000040', 89, 3, 1567, 19),
    ('Internet service provider options', 'Frustrated with current ISP. What alternatives do we have in our area?', '11111111-0000-0000-0000-000000000019', 56, 8, 890, 13),
    ('Street light outage on Oak Avenue', 'Multiple street lights out on Oak Ave creating safety hazard. Reported 2 weeks ago.', '11111111-0000-0000-0000-000000000020', 34, 1, 456, 6),
    ('New traffic signal at dangerous intersection', 'Finally! They''re installing a signal at First and Maple. Long overdue.', '11111111-0000-0000-0000-000000000021', 78, 2, 678, 2),
    ('Water main replacement schedule', 'City released schedule for water main replacements. Check if your street is affected.', '11111111-0000-0000-0000-000000000019', 45, 1, 567, 1)
) AS t(title, content, user_id, upvotes, downvotes, view_count, days_ago)
WHERE c.slug = 'infrastructure';

-- Public Safety threads
INSERT INTO threads (id, title, content, category_id, user_id, upvotes, downvotes, view_count, created_at)
SELECT
    gen_random_uuid(),
    t.title,
    t.content,
    c.id,
    t.user_id::uuid,
    t.upvotes,
    t.downvotes,
    t.view_count,
    NOW() - (t.days_ago || ' days')::interval
FROM categories c
CROSS JOIN (
    VALUES
    ('Neighborhood watch meeting Tuesday', 'Monthly neighborhood watch meeting to discuss recent incidents and prevention strategies.', '11111111-0000-0000-0000-000000000012', 45, 2, 678, 24),
    ('Emergency preparedness workshop', 'Fire department hosting free emergency preparedness workshop this Saturday.', '11111111-0000-0000-0000-000000000022', 67, 1, 890, 16),
    ('Crosswalk safety concerns at school', 'Parents concerned about speeding near elementary school. Need better enforcement.', '11111111-0000-0000-0000-000000000038', 89, 3, 1234, 9),
    ('Thank you to first responders', 'Shout out to our amazing paramedics who saved my neighbor''s life yesterday!', '11111111-0000-0000-0000-000000000053', 156, 0, 2345, 4),
    ('Home security tips from police dept', 'Police department shared these helpful home security tips for the holiday season.', '11111111-0000-0000-0000-000000000012', 78, 2, 987, 2)
) AS t(title, content, user_id, upvotes, downvotes, view_count, days_ago)
WHERE c.slug = 'public-safety';

-- Environment threads
INSERT INTO threads (id, title, content, category_id, user_id, upvotes, downvotes, view_count, created_at)
SELECT
    gen_random_uuid(),
    t.title,
    t.content,
    c.id,
    t.user_id::uuid,
    t.upvotes,
    t.downvotes,
    t.view_count,
    NOW() - (t.days_ago || ' days')::interval
FROM categories c
CROSS JOIN (
    VALUES
    ('Community garden plots available', 'Spring plots available at the community garden. First come, first served!', '11111111-0000-0000-0000-000000000042', 56, 1, 789, 20),
    ('Recycling program changes', 'City expanding recycling program to include more plastics. Details on what''s accepted.', '11111111-0000-0000-0000-000000000008', 78, 4, 1123, 12),
    ('Tree planting initiative this spring', 'Join us in planting 1000 trees across the city. Volunteers needed!', '11111111-0000-0000-0000-000000000043', 92, 2, 1456, 5),
    ('Solar panel group buy opportunity', 'Organizing group purchase of solar panels for better pricing. Interest meeting Thursday.', '11111111-0000-0000-0000-000000000056', 64, 8, 987, 3),
    ('River cleanup day huge success!', 'Thank you to all 200+ volunteers who helped clean our river yesterday!', '11111111-0000-0000-0000-000000000042', 145, 1, 2234, 1)
) AS t(title, content, user_id, upvotes, downvotes, view_count, days_ago)
WHERE c.slug = 'environment';

-- Education threads
INSERT INTO threads (id, title, content, category_id, user_id, upvotes, downvotes, view_count, created_at)
SELECT
    gen_random_uuid(),
    t.title,
    t.content,
    c.id,
    t.user_id::uuid,
    t.upvotes,
    t.downvotes,
    t.view_count,
    NOW() - (t.days_ago || ' days')::interval
FROM categories c
CROSS JOIN (
    VALUES
    ('School board election candidates forum', 'Meet the candidates for school board at the public forum next Wednesday.', '11111111-0000-0000-0000-000000000011', 67, 5, 1234, 17),
    ('After-school tutoring program needs volunteers', 'Help local students succeed! Volunteer tutors needed for math and reading.', '11111111-0000-0000-0000-000000000046', 45, 1, 678, 11),
    ('New STEM program at middle school', 'Exciting news! Middle school received grant for new robotics and coding program.', '11111111-0000-0000-0000-000000000011', 89, 2, 1345, 6),
    ('Adult education classes starting', 'Free GED and ESL classes starting at the community college. Register now!', '11111111-0000-0000-0000-000000000057', 56, 0, 567, 3),
    ('Library summer reading program', 'Summer reading program for kids starts June 1st with prizes and activities!', '11111111-0000-0000-0000-000000000043', 78, 1, 890, 1)
) AS t(title, content, user_id, upvotes, downvotes, view_count, days_ago)
WHERE c.slug = 'education';

-- ============================================================================

-- ============================================================================
-- 5. COMMENTS (Mix of top-level and nested replies)
-- Using LTREE for proper threading
-- ============================================================================

-- First, let's create a temporary table to help generate comments
WITH thread_samples AS (
    SELECT 
        t.id as thread_id,
        t.title,
        t.user_id,
        ROW_NUMBER() OVER (ORDER BY t.created_at DESC) as thread_num
    FROM threads t
    LIMIT 20  -- Focus on first 20 threads for detailed comments
)
-- Generate varied numbers of comments per thread
INSERT INTO comments (thread_id, user_id, content, path, upvotes, downvotes, created_at)
SELECT * FROM (
    -- Thread 1: Active discussion (30+ comments)
    SELECT
        (SELECT thread_id FROM thread_samples WHERE thread_num = 1),
        '11111111-0000-0000-0000-000000000017'::uuid,
        'Great initiative! I fully support having community guidelines clearly stated.',
        '1'::ltree,
        23, 1,
        NOW() - INTERVAL '29 days'
    UNION ALL SELECT
        (SELECT thread_id FROM thread_samples WHERE thread_num = 1),
        '11111111-0000-0000-0000-000000000022'::uuid,
        'These guidelines seem reasonable. One question about the moderation process...',
        '2'::ltree,
        15, 2,
        NOW() - INTERVAL '29 days'
    UNION ALL SELECT
        (SELECT thread_id FROM thread_samples WHERE thread_num = 1),
        '11111111-0000-0000-0000-000000000033'::uuid,
        'The moderation process is explained in section 3. It''s quite democratic!',
        '2.1'::ltree,
        8, 0,
        NOW() - INTERVAL '28 days'
    UNION ALL SELECT
        (SELECT thread_id FROM thread_samples WHERE thread_num = 1),
        '11111111-0000-0000-0000-000000000022'::uuid,
        'Thanks! I missed that section. Makes sense now.',
        '2.1.1'::ltree,
        5, 0,
        NOW() - INTERVAL '28 days'

    -- Thread 2: Medium activity (10-15 comments)
    UNION ALL SELECT
        (SELECT thread_id FROM thread_samples WHERE thread_num = 2),
        '11111111-0000-0000-0000-000000000005'::uuid,
        'You can report content using the flag icon next to each post.',
        '1'::ltree,
        18, 0,
        NOW() - INTERVAL '14 days'
    UNION ALL SELECT
        (SELECT thread_id FROM thread_samples WHERE thread_num = 2),
        '11111111-0000-0000-0000-000000000012'::uuid,
        'Also, make sure to select the appropriate category when reporting.',
        '2'::ltree,
        12, 1,
        NOW() - INTERVAL '14 days'
    UNION ALL SELECT
        (SELECT thread_id FROM thread_samples WHERE thread_num = 2),
        '11111111-0000-0000-0000-000000000033'::uuid,
        'Thank you both! Found the flag icon. Very helpful!',
        '3'::ltree,
        7, 0,
        NOW() - INTERVAL '13 days'

    -- Thread 3: Low activity (3-5 comments)
    UNION ALL SELECT
        (SELECT thread_id FROM thread_samples WHERE thread_num = 3),
        '11111111-0000-0000-0000-000000000048'::uuid,
        'YES PLEASE! Dark mode is essential for night browsing.',
        '1'::ltree,
        32, 0,
        NOW() - INTERVAL '6 days'
    UNION ALL SELECT
        (SELECT thread_id FROM thread_samples WHERE thread_num = 3),
        '11111111-0000-0000-0000-000000000051'::uuid,
        '+1 for dark mode. My eyes would appreciate it!',
        '2'::ltree,
        28, 0,
        NOW() - INTERVAL '6 days'
    UNION ALL SELECT
        (SELECT thread_id FROM thread_samples WHERE thread_num = 3),
        '11111111-0000-0000-0000-000000000001'::uuid,
        'We''re working on it! Should be available next month.',
        '3'::ltree,
        45, 0,
        NOW() - INTERVAL '5 days'
    UNION ALL SELECT
        (SELECT thread_id FROM thread_samples WHERE thread_num = 3),
        '11111111-0000-0000-0000-000000000026'::uuid,
        'Awesome! Thanks for the update admin!',
        '3.1'::ltree,
        12, 0,
        NOW() - INTERVAL '5 days'

    -- More varied comments for other threads
    UNION ALL SELECT
        (SELECT thread_id FROM thread_samples WHERE thread_num = 4),
        '11111111-0000-0000-0000-000000000018'::uuid,
        'Monthly town halls would be great for transparency.',
        '1'::ltree,
        42, 3,
        NOW() - INTERVAL '2 days'
    UNION ALL SELECT
        (SELECT thread_id FROM thread_samples WHERE thread_num = 4),
        '11111111-0000-0000-0000-000000000037'::uuid,
        'I agree, but we need to ensure they''re accessible to all.',
        '2'::ltree,
        38, 2,
        NOW() - INTERVAL '2 days'
    UNION ALL SELECT
        (SELECT thread_id FROM thread_samples WHERE thread_num = 4),
        '11111111-0000-0000-0000-000000000042'::uuid,
        'Virtual format with recordings would help with accessibility.',
        '2.1'::ltree,
        25, 1,
        NOW() - INTERVAL '2 days'
    UNION ALL SELECT
        (SELECT thread_id FROM thread_samples WHERE thread_num = 4),
        '11111111-0000-0000-0000-000000000019'::uuid,
        'Good point! Also need closed captions for hearing impaired.',
        '2.1.1'::ltree,
        18, 0,
        NOW() - INTERVAL '1 day'
    UNION ALL SELECT
        (SELECT thread_id FROM thread_samples WHERE thread_num = 4),
        '11111111-0000-0000-0000-000000000005'::uuid,
        'I''ll add all these suggestions to the proposal. Keep them coming!',
        '3'::ltree,
        52, 0,
        NOW() - INTERVAL '1 day'
) AS c;

-- Add more comments programmatically for realistic distribution
INSERT INTO comments (thread_id, user_id, content, path, upvotes, downvotes, created_at)
SELECT
    t.id,
    u.id,
    CASE (RANDOM() * 10)::INT
        WHEN 0 THEN 'This is exactly what we needed!'
        WHEN 1 THEN 'I disagree with this approach.'
        WHEN 2 THEN 'Has anyone considered the budget implications?'
        WHEN 3 THEN 'Great point! I hadn''t thought of that.'
        WHEN 4 THEN 'We tried this before and it didn''t work.'
        WHEN 5 THEN 'I''d like to volunteer to help with this.'
        WHEN 6 THEN 'Can we get more details on the timeline?'
        WHEN 7 THEN 'This seems like a good compromise.'
        WHEN 8 THEN 'What about the environmental impact?'
        ELSE 'Thanks for bringing this to our attention.'
    END || ' ' || 
    CASE (RANDOM() * 5)::INT
        WHEN 0 THEN 'Looking forward to seeing how this develops.'
        WHEN 1 THEN 'Let me know if you need any assistance.'
        WHEN 2 THEN 'I''ll share this with my neighbors.'
        WHEN 3 THEN 'We should discuss this at the next meeting.'
        ELSE ''
    END AS content,
    (ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY RANDOM()))::TEXT::ltree as path,
    (RANDOM() * 50)::INT as upvotes,
    (RANDOM() * 10)::INT as downvotes,
    t.created_at + ((RANDOM() * 5)::INT || ' hours')::INTERVAL
FROM threads t
CROSS JOIN LATERAL (
    SELECT u.id 
    FROM users u
    WHERE u.id != t.user_id
    ORDER BY RANDOM()
    LIMIT (RANDOM() * 15)::INT + 5  -- 5-20 comments per thread
) u
WHERE t.id NOT IN (SELECT DISTINCT thread_id FROM comments);

-- ============================================================================
-- 6. THREAD VOTES (Voting data for threads)
-- ============================================================================

-- Generate realistic voting patterns
INSERT INTO thread_votes (user_id, thread_id, vote_type, voted_at)
SELECT DISTINCT ON (u.id, t.id)
    u.id,
    t.id,
    CASE
        WHEN RANDOM() < 0.7 THEN 'upvote'  -- 70% upvotes
        ELSE 'downvote'
    END,
    t.created_at + ((RANDOM() * 30)::INT || ' minutes')::INTERVAL
FROM threads t
CROSS JOIN users u
WHERE 
    -- Random subset of users vote (30-75% of users per thread)
    RANDOM() < 0.3 + (RANDOM() * 0.45)
    -- Users don't vote on their own threads
    AND u.id != t.user_id
ON CONFLICT (user_id, thread_id) DO NOTHING;

-- ============================================================================
-- 7. COMMENT VOTES (Voting data for comments)
-- ============================================================================

-- Generate realistic voting patterns for comments
INSERT INTO comment_votes (user_id, comment_id, vote_type, voted_at)
SELECT DISTINCT ON (u.id, c.id)
    u.id,
    c.id,
    CASE
        WHEN RANDOM() < 0.75 THEN 'upvote'  -- 75% upvotes for comments
        ELSE 'downvote'
    END,
    c.created_at + ((RANDOM() * 60)::INT || ' minutes')::INTERVAL
FROM comments c
CROSS JOIN users u
WHERE 
    -- Fewer users vote on comments (20-50%)
    RANDOM() < 0.2 + (RANDOM() * 0.3)
    -- Users don't vote on their own comments
    AND u.id != c.user_id
ON CONFLICT (user_id, comment_id) DO NOTHING;

-- ============================================================================
-- 8. FINAL SUMMARY
-- ============================================================================

DO $$
DECLARE
    user_count INTEGER;
    thread_count INTEGER;
    comment_count INTEGER;
    mod_count INTEGER;
    thread_vote_count INTEGER;
    comment_vote_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO thread_count FROM threads;
    SELECT COUNT(*) INTO comment_count FROM comments;
    SELECT COUNT(*) INTO mod_count FROM moderators;
    SELECT COUNT(*) INTO thread_vote_count FROM thread_votes;
    SELECT COUNT(*) INTO comment_vote_count FROM comment_votes;
    
    RAISE NOTICE '';
    RAISE NOTICE '========== EXPANDED SEED DATA SUMMARY ==========';
    RAISE NOTICE 'Users created: %', user_count;
    RAISE NOTICE 'Threads created: %', thread_count;
    RAISE NOTICE 'Comments created: %', comment_count;
    RAISE NOTICE 'Moderators assigned: %', mod_count;
    RAISE NOTICE 'Thread votes: %', thread_vote_count;
    RAISE NOTICE 'Comment votes: %', comment_vote_count;
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Seed data installation complete!';
END $$;

