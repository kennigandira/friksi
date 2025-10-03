-- ============================================
-- MIGRATION: Secure User Profile Creation
-- Issue #11: Move profile creation to database trigger
-- ============================================
-- This migration fixes a critical security vulnerability where user profiles
-- were created client-side, allowing malicious users to set their own level,
-- XP, and trust score. Now profiles are created automatically by a database
-- trigger with secure defaults.
-- ============================================

-- Function to create user profile automatically
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Insert profile for new auth user with secure defaults
  INSERT INTO public.users (
    id,
    username,
    email,
    level,
    xp,
    trust_score,
    account_status,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    -- Extract username from metadata, fallback to email username
    COALESCE(
      NEW.raw_user_meta_data->>'username',
      split_part(NEW.email, '@', 1)
    ),
    NEW.email,
    1,          -- Always start at level 1
    0,          -- Always start with 0 XP
    50.0,       -- Default trust score
    'active',   -- Account starts active
    NOW(),
    NOW()
  );

  RETURN NEW;
EXCEPTION
  WHEN unique_violation THEN
    -- Profile already exists (shouldn't happen, but handle gracefully)
    RAISE NOTICE 'Profile already exists for user %', NEW.id;
    RETURN NEW;
  WHEN OTHERS THEN
    -- Log error but don't fail auth signup
    RAISE WARNING 'Failed to create profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$;

-- Create trigger on auth.users INSERT
-- This runs automatically when a new user signs up via Supabase Auth
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_user_profile();

-- Update RLS policy to prevent direct inserts
-- Only the trigger (SECURITY DEFINER) can insert users
DROP POLICY IF EXISTS "New users can insert profile" ON users;
DROP POLICY IF EXISTS "Users can insert profile" ON users;

-- Prevent all direct inserts to users table
CREATE POLICY "Prevent direct user inserts" ON users
  FOR INSERT
  WITH CHECK (false);

-- Allow service role to insert (for migrations, scripts, etc.)
-- Service role bypasses RLS, so this is safe
-- Note: Regular users cannot insert even if they try to spoof level/xp/trust_score

-- Add comment documenting the security model
COMMENT ON TRIGGER on_auth_user_created ON auth.users IS
  'Automatically creates user profile with secure defaults when user signs up. '
  'Prevents client-side manipulation of level, XP, and trust score.';

COMMENT ON FUNCTION create_user_profile() IS
  'Creates user profile in public.users table with secure defaults. '
  'Called automatically by trigger on auth.users INSERT. '
  'SECURITY DEFINER ensures it has permission to insert regardless of RLS policies.';

-- Log successful migration
DO $$
BEGIN
  RAISE NOTICE 'Migration 00019: Secure profile creation trigger installed successfully';
END $$;