-- Seed Data for Friksi
-- Sample data for development and testing

-- ============================================================================
-- DEFAULT CATEGORIES
-- ============================================================================

-- Default categories (matching the table-schema-plan structure)
INSERT INTO categories (name, slug, description, is_default) VALUES
    ('General Discussion', 'general', 'General topics and conversations', true),
    ('Technology', 'tech', 'Technology news and discussions', true),
    ('Politics', 'politics', 'Political discussions and debates', false),
    ('Science', 'science', 'Scientific discoveries and research', true),
    ('Entertainment', 'entertainment', 'Movies, TV, music, and more', true),
    ('Sports', 'sports', 'Sports news and discussions', false)
ON CONFLICT (slug) DO NOTHING;

-- Example subcategories (using parent_id)
INSERT INTO categories (name, slug, description, parent_id)
SELECT 'Programming', 'programming', 'Software development discussions', id
FROM categories WHERE slug = 'tech'
ON CONFLICT (parent_id, slug) DO NOTHING;

INSERT INTO categories (name, slug, description, parent_id)
SELECT 'Web Development', 'webdev', 'Frontend, backend, and full-stack development', id
FROM categories WHERE slug = 'programming'
ON CONFLICT (parent_id, slug) DO NOTHING;

INSERT INTO categories (name, slug, description, parent_id)
SELECT 'Mobile Development', 'mobile', 'iOS, Android, and cross-platform development', id
FROM categories WHERE slug = 'programming'
ON CONFLICT (parent_id, slug) DO NOTHING;

-- ============================================================================
-- SAMPLE BADGES
-- ============================================================================

INSERT INTO badges (name, description, icon, color, type, xp_requirement, level_requirement) VALUES
(
  'First Steps',
  'Welcome to Friksi! Awarded for joining the community',
  '👋',
  '#3b82f6',
  'participation',
  0,
  'level_1'
),
(
  'Conversation Starter',
  'Created your first thread',
  '💬',
  '#10b981',
  'participation',
  10,
  'level_2'
),
(
  'Thoughtful Contributor',
  'Posted 10 quality comments',
  '✍️',
  '#f59e0b',
  'quality_content',
  50,
  'level_2'
),
(
  'Community Watchdog',
  'Made your first content report',
  '🔍',
  '#ef4444',
  'moderation',
  25,
  'level_3'
),
(
  'Democratic Voter',
  'Participated in 3 voting sessions',
  '🗳️',
  '#8b5cf6',
  'civic_engagement',
  100,
  'level_3'
),
(
  'Consistent Voter',
  'Voted in 10 consecutive monthly sessions',
  '📊',
  '#06b6d4',
  'civic_engagement',
  500,
  'level_3'
),
(
  'Community Builder',
  'Created a popular category with 50+ subscribers',
  '🏗️',
  '#f97316',
  'community_building',
  200,
  'level_4'
),
(
  'Trusted Moderator',
  'Maintained 80%+ approval rating as moderator for 6 months',
  '⚖️',
  '#dc2626',
  'moderation',
  1000,
  'level_5'
),
(
  'Engagement Master',
  'Created content that received 100+ upvotes',
  '🔥',
  '#7c3aed',
  'quality_content',
  300,
  'level_3'
),
(
  'Anti-Bot Champion',
  'Successfully identified and reported 5 confirmed bots',
  '🤖',
  '#059669',
  'moderation',
  150,
  'level_3'
)
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- SAMPLE CATEGORIES
-- ============================================================================

-- Root categories
INSERT INTO categories (name, slug, description, color, icon, path, level, is_active, min_level_to_post) VALUES
(
  'Municipal Affairs',
  'municipal-affairs',
  'Discussions about local government, city council, and municipal services',
  '#1e40af',
  '🏛️',
  'municipal_affairs',
  0,
  true,
  'level_2'
),
(
  'Community Events',
  'community-events',
  'Organize and discuss local community events, festivals, and gatherings',
  '#059669',
  '🎉',
  'community_events',
  0,
  true,
  'level_2'
),
(
  'Infrastructure',
  'infrastructure',
  'Roads, public transportation, utilities, and city infrastructure',
  '#dc2626',
  '🚧',
  'infrastructure',
  0,
  true,
  'level_2'
),
(
  'Public Safety',
  'public-safety',
  'Police, fire department, emergency services, and community safety',
  '#7c2d12',
  '🚨',
  'public_safety',
  0,
  true,
  'level_2'
),
(
  'Environment',
  'environment',
  'Environmental issues, sustainability, parks, and green initiatives',
  '#166534',
  '🌱',
  'environment',
  0,
  true,
  'level_2'
),
(
  'Education',
  'education',
  'Schools, libraries, educational programs, and learning opportunities',
  '#7c3aed',
  '📚',
  'education',
  0,
  true,
  'level_2'
),
(
  'General Discussion',
  'general-discussion',
  'General community discussions that don''t fit other categories',
  '#6b7280',
  '💭',
  'general_discussion',
  0,
  true,
  'level_2'
)
ON CONFLICT (slug) DO NOTHING;

-- Subcategories (examples)
INSERT INTO categories (name, slug, description, color, icon, parent_id, path, level, is_active, min_level_to_post)
SELECT
  'Budget & Finance',
  'budget-finance',
  'Municipal budgets, taxes, and financial planning',
  '#1e40af',
  '💰',
  c.id,
  'municipal_affairs.budget_finance',
  1,
  true,
  'level_2'
FROM categories c WHERE c.slug = 'municipal-affairs'
UNION ALL
SELECT
  'Zoning & Development',
  'zoning-development',
  'Urban planning, zoning changes, and development projects',
  '#1e40af',
  '🏗️',
  c.id,
  'municipal_affairs.zoning_development',
  1,
  true,
  'level_2'
FROM categories c WHERE c.slug = 'municipal-affairs'
UNION ALL
SELECT
  'Parks & Recreation',
  'parks-recreation',
  'Local parks, recreational facilities, and outdoor activities',
  '#166534',
  '🏞️',
  c.id,
  'environment.parks_recreation',
  1,
  true,
  'level_2'
FROM categories c WHERE c.slug = 'environment'
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- SAMPLE USERS (for development only)
-- ============================================================================

INSERT INTO users (id, email, username, bio, level, xp, trust_score) VALUES
(
  '00000000-0000-0000-0000-000000000001',
  'admin@friksi.dev',
  'admin',
  'Platform administrator and community moderator',
  5,
  10000,
  100.00
),
(
  '00000000-0000-0000-0000-000000000002',
  'moderator@friksi.dev',
  'citymod',
  'Long-time community member and trusted moderator',
  5,
  7500,
  95.00
),
(
  '00000000-0000-0000-0000-000000000003',
  'active@friksi.dev',
  'activecitizen',
  'Community organizer passionate about local issues',
  4,
  3000,
  85.00
),
(
  '00000000-0000-0000-0000-000000000004',
  'newcomer@friksi.dev',
  'newcomer',
  'New to the area, eager to get involved',
  2,
  150,
  55.00
),
(
  '00000000-0000-0000-0000-000000000005',
  'observer@friksi.dev',
  'quietobserver',
  'Prefers to read and vote rather than post',
  1,
  25,
  50.00
)
ON CONFLICT (email) DO NOTHING;

-- ============================================================================
-- SAMPLE THREADS
-- ============================================================================

INSERT INTO threads (title, content, category_id, user_id, upvotes, downvotes, view_count)
SELECT
  'City Budget Meeting - Public Input Needed',
  'The city council is holding a public budget meeting next Tuesday at 7 PM. They''re discussing the proposed budget for next year, including funding for parks, road maintenance, and public services. This is our chance to have our voices heard on how our tax dollars should be spent.

Key topics:
- Park maintenance budget (currently underfunded)
- Road repair priorities
- Public safety funding
- New community center proposal

Anyone planning to attend? What issues should we prioritize?',
  c.id,
  '00000000-0000-0000-0000-000000000002',
  15,
  2,
  234
FROM categories c WHERE c.slug = 'municipal-affairs'
UNION ALL
SELECT
  'Potholes on Main Street Getting Worse',
  'The potholes on Main Street between 5th and 8th Avenue are getting really bad. I nearly damaged my tire yesterday, and I''ve seen several other cars struggling with the same spots.

Has anyone reported this to the city yet? Do we know if there''s a timeline for repairs? With winter coming, these are only going to get worse.',
  c.id,
  '00000000-0000-0000-0000-000000000004',
  23,
  1,
  156
FROM categories c WHERE c.slug = 'infrastructure'
UNION ALL
SELECT
  'Summer Festival Planning Committee',
  'Hi everyone! We''re starting to plan this year''s summer festival and we need volunteers. Last year was a huge success with over 2,000 attendees, and we want to make this year even better.

We need help with:
- Event logistics and setup
- Vendor coordination
- Entertainment booking
- Marketing and promotion
- Cleanup crew

The first planning meeting is this Saturday at 10 AM at the community center. Coffee and donuts provided!

Who''s interested in helping make our community festival amazing?',
  c.id,
  '00000000-0000-0000-0000-000000000003',
  31,
  0,
  298
FROM categories c WHERE c.slug = 'community-events'
UNION ALL
SELECT
  'New Dog Park Proposal',
  'I''ve been working with a few neighbors to propose a new dog park in the empty lot behind the library. We''ve done some research on costs and maintenance requirements.

Initial proposal:
- Fenced area with separate sections for large and small dogs
- Water fountains for dogs and owners
- Waste stations and seating
- Estimated cost: $45,000 for initial setup
- Annual maintenance: ~$8,000

The lot is currently unused and would be perfect for this. We have 47 signatures on our petition so far. What do you all think? Would you use a dog park in this location?',
  c.id,
  '00000000-0000-0000-0000-000000000003',
  28,
  3,
  187
FROM categories c WHERE c.slug = 'environment'
UNION ALL
SELECT
  'School Crossing Guard Needed',
  'Roosevelt Elementary is looking for a volunteer crossing guard for the intersection at Pine Street and 3rd Avenue. The previous volunteer had to step down due to health issues.

Time commitment: 7:30-8:30 AM and 2:30-3:30 PM on school days
Training provided by the police department
Small stipend available ($200/month)

This is a really important safety role for our kids. If you''re interested or know someone who might be, please let me know!',
  c.id,
  '00000000-0000-0000-0000-000000000002',
  19,
  0,
  142
FROM categories c WHERE c.slug = 'public-safety'
ON CONFLICT DO NOTHING;

-- Update thread hot scores based on sample data
UPDATE threads SET
  hot_score = calculate_hot_score(upvotes, downvotes, created_at),
  wilson_score = calculate_wilson_score(upvotes, downvotes);

-- ============================================================================
-- SAMPLE COMMENTS
-- ============================================================================

-- Get thread IDs for comments
DO $$
DECLARE
  budget_thread_id UUID;
  pothole_thread_id UUID;
  festival_thread_id UUID;
  dogpark_thread_id UUID;
BEGIN
  -- Get thread IDs
  SELECT id INTO budget_thread_id FROM threads WHERE title LIKE 'City Budget Meeting%' LIMIT 1;
  SELECT id INTO pothole_thread_id FROM threads WHERE title LIKE 'Potholes on Main Street%' LIMIT 1;
  SELECT id INTO festival_thread_id FROM threads WHERE title LIKE 'Summer Festival Planning%' LIMIT 1;
  SELECT id INTO dogpark_thread_id FROM threads WHERE title LIKE 'New Dog Park Proposal%' LIMIT 1;

  -- Comments on budget thread
  IF budget_thread_id IS NOT NULL THEN
    INSERT INTO comments (content, thread_id, user_id, upvotes, downvotes) VALUES
    (
      'I definitely plan to attend! The park maintenance budget is my top priority. Our neighborhood park hasn''t been properly maintained in over two years.',
      budget_thread_id,
      '00000000-0000-0000-0000-000000000003',
      8,
      0
    ),
    (
      'Road repairs should be the top priority. The city''s infrastructure is falling apart and it affects everyone who drives.',
      budget_thread_id,
      '00000000-0000-0000-0000-000000000004',
      5,
      2
    ),
    (
      'What about public transportation? We really need better bus service, especially for seniors and people without cars.',
      budget_thread_id,
      '00000000-0000-0000-0000-000000000005',
      12,
      1
    );
  END IF;

  -- Comments on pothole thread
  IF pothole_thread_id IS NOT NULL THEN
    INSERT INTO comments (content, thread_id, user_id, upvotes, downvotes) VALUES
    (
      'I reported this to the city''s website last month but haven''t heard anything back. You can report it at city.gov/reports - the more reports they get, the higher priority it becomes.',
      pothole_thread_id,
      '00000000-0000-0000-0000-000000000002',
      15,
      0
    ),
    (
      'Same issue on Oak Street! I think they''re waiting for the next budget cycle to do major road work. In the meantime, try to report it and document with photos.',
      pothole_thread_id,
      '00000000-0000-0000-0000-000000000003',
      7,
      0
    );
  END IF;

  -- Comments on festival thread
  IF festival_thread_id IS NOT NULL THEN
    INSERT INTO comments (content, thread_id, user_id, upvotes, downvotes) VALUES
    (
      'I''d love to help with vendor coordination! I have experience from organizing farmers markets. Count me in for the meeting on Saturday.',
      festival_thread_id,
      '00000000-0000-0000-0000-000000000004',
      6,
      0
    ),
    (
      'My band would be interested in performing if you need local entertainment. We play folk/acoustic music that''s family-friendly.',
      festival_thread_id,
      '00000000-0000-0000-0000-000000000005',
      9,
      0
    ),
    (
      'The cleanup crew is always understaffed. I''ll bring some friends to help with that. What time does cleanup usually start?',
      festival_thread_id,
      '00000000-0000-0000-0000-000000000002',
      4,
      0
    );
  END IF;

  -- Comments on dog park thread
  IF dogpark_thread_id IS NOT NULL THEN
    INSERT INTO comments (content, thread_id, user_id, upvotes, downvotes) VALUES
    (
      'This is a great idea! My dog would love this. The nearest dog park is 20 minutes away by car. Where do I sign the petition?',
      dogpark_thread_id,
      '00000000-0000-0000-0000-000000000004',
      11,
      0
    ),
    (
      'Love the idea but I''m concerned about maintenance costs. Who would be responsible for daily cleanup and upkeep? We don''t want it to become an eyesore.',
      dogpark_thread_id,
      '00000000-0000-0000-0000-000000000005',
      8,
      1
    ),
    (
      'I live next to the library and think this would be wonderful for the neighborhood. The lot just sits empty now. Happy to sign the petition and help with fundraising.',
      dogpark_thread_id,
      '00000000-0000-0000-0000-000000000002',
      13,
      0
    );
  END IF;
END $$;

-- Update comment Wilson scores
UPDATE comments SET wilson_score = calculate_wilson_score(upvotes, downvotes);

-- ============================================================================
-- SAMPLE MODERATORS
-- ============================================================================

-- Make some users moderators
INSERT INTO moderators (user_id, category_id, elected_at, term_end_date, election_votes, approval_rating)
SELECT
  '00000000-0000-0000-0000-000000000001',
  c.id,
  NOW() - INTERVAL '6 months',
  NOW() + INTERVAL '18 months',
  89,
  92.5
FROM categories c WHERE c.slug = 'municipal-affairs'
UNION ALL
SELECT
  '00000000-0000-0000-0000-000000000002',
  c.id,
  NOW() - INTERVAL '3 months',
  NOW() + INTERVAL '21 months',
  76,
  88.3
FROM categories c WHERE c.slug = 'infrastructure'
UNION ALL
SELECT
  '00000000-0000-0000-0000-000000000003',
  c.id,
  NOW() - INTERVAL '1 month',
  NOW() + INTERVAL '23 months',
  54,
  85.7
FROM categories c WHERE c.slug = 'community-events'
ON CONFLICT (user_id, category_id) DO NOTHING;

-- ============================================================================
-- SAMPLE CATEGORY SUBSCRIPTIONS
-- ============================================================================

INSERT INTO category_subscriptions (user_id, category_id, notify_new_threads, notify_popular_threads)
SELECT
  u.id,
  c.id,
  true,
  CASE WHEN u.level::text > 'level_2' THEN true ELSE false END
FROM users u
CROSS JOIN categories c
WHERE u.email LIKE '%@friksi.dev'
  AND c.level = 0 -- Only root categories
ON CONFLICT (user_id, category_id) DO NOTHING;

-- ============================================================================
-- SAMPLE USER BADGES
-- ============================================================================

-- Award some badges to users
INSERT INTO user_badges (user_id, badge_id)
SELECT
  u.id,
  b.id
FROM users u
CROSS JOIN badges b
WHERE u.email = 'admin@friksi.dev'
  AND b.name IN ('First Steps', 'Conversation Starter', 'Trusted Moderator')
UNION ALL
SELECT
  u.id,
  b.id
FROM users u
CROSS JOIN badges b
WHERE u.email = 'active@friksi.dev'
  AND b.name IN ('First Steps', 'Conversation Starter', 'Community Builder', 'Democratic Voter')
UNION ALL
SELECT
  u.id,
  b.id
FROM users u
CROSS JOIN badges b
WHERE u.email = 'newcomer@friksi.dev'
  AND b.name IN ('First Steps', 'Conversation Starter')
ON CONFLICT (user_id, badge_id) DO NOTHING;

-- ============================================================================
-- SAMPLE VOTING SESSION
-- ============================================================================

INSERT INTO voting_sessions (title, description, category_id, start_date, end_date, status, min_level_to_vote, created_by)
SELECT
  'Monthly Community Priorities - November 2024',
  'Vote on the top 3 priorities for our community this month. Results will be shared with the city council.',
  c.id,
  NOW() - INTERVAL '5 days',
  NOW() + INTERVAL '25 days',
  'active',
  'level_3',
  '00000000-0000-0000-0000-000000000001'
FROM categories c WHERE c.slug = 'general-discussion'
LIMIT 1;

-- Add voting options
INSERT INTO voting_options (session_id, title, description)
SELECT
  vs.id,
  'Road Infrastructure Repairs',
  'Focus on fixing potholes and resurfacing major roads'
FROM voting_sessions vs WHERE vs.title LIKE 'Monthly Community Priorities%'
UNION ALL
SELECT
  vs.id,
  'Park and Recreation Improvements',
  'Invest in park maintenance and new recreational facilities'
FROM voting_sessions vs WHERE vs.title LIKE 'Monthly Community Priorities%'
UNION ALL
SELECT
  vs.id,
  'Public Safety Enhancements',
  'Improve street lighting and increase community policing'
FROM voting_sessions vs WHERE vs.title LIKE 'Monthly Community Priorities%'
UNION ALL
SELECT
  vs.id,
  'Environmental Initiatives',
  'Support recycling programs and green energy projects'
FROM voting_sessions vs WHERE vs.title LIKE 'Monthly Community Priorities%';

-- ============================================================================
-- UPDATE CATEGORY COUNTS
-- ============================================================================

-- Update thread and subscriber counts for categories
UPDATE categories SET
  thread_count = (
    SELECT COUNT(*)
    FROM threads t
    WHERE t.category_id = categories.id
      AND t.is_deleted = FALSE
  ),
  subscriber_count = (
    SELECT COUNT(*)
    FROM category_subscriptions cs
    WHERE cs.category_id = categories.id
  );

-- ============================================================================
-- REFRESH MATERIALIZED VIEWS (if any)
-- ============================================================================

-- Add any materialized view refreshes here if needed in the future