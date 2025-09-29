-- ============================================
-- MIGRATION: Add is_bot column to users table
-- Restores is_bot column that was moved to bot_detection
-- ============================================

-- Add is_bot column to users table
ALTER TABLE users
ADD COLUMN IF NOT EXISTS is_bot BOOLEAN DEFAULT false;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_users_is_bot ON users(is_bot);

-- Update existing users with is_bot value from bot_detection table
UPDATE users
SET is_bot = COALESCE(bot_detection.is_bot, false)
FROM bot_detection
WHERE users.id = bot_detection.user_id;

-- Set up trigger to keep users.is_bot in sync with bot_detection.is_bot
CREATE OR REPLACE FUNCTION sync_user_is_bot()
RETURNS TRIGGER AS $$
BEGIN
    -- When bot_detection.is_bot is updated, update users.is_bot
    IF TG_OP = 'UPDATE' AND OLD.is_bot IS DISTINCT FROM NEW.is_bot THEN
        UPDATE users SET is_bot = NEW.is_bot WHERE id = NEW.user_id;
    END IF;

    -- When bot_detection row is inserted, update users.is_bot
    IF TG_OP = 'INSERT' THEN
        UPDATE users SET is_bot = NEW.is_bot WHERE id = NEW.user_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to sync is_bot changes
DROP TRIGGER IF EXISTS sync_user_is_bot_trigger ON bot_detection;
CREATE TRIGGER sync_user_is_bot_trigger
    AFTER INSERT OR UPDATE ON bot_detection
    FOR EACH ROW EXECUTE FUNCTION sync_user_is_bot();