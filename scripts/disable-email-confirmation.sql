-- Disable Email Confirmation Requirement
-- This is a workaround for email configuration issues
-- Run this in Supabase SQL Editor

-- ========================================
-- OPTION 1: Mark all existing users as confirmed
-- ========================================

-- Update all unconfirmed users to be confirmed
UPDATE auth.users 
SET email_confirmed_at = COALESCE(email_confirmed_at, NOW())
WHERE email_confirmed_at IS NULL;

-- Update corresponding public profiles
UPDATE public.users 
SET email_verified = true
WHERE email_verified = false;

SELECT 'Updated existing users to confirmed status' as result;

-- ========================================
-- OPTION 2: Create a trigger to auto-confirm new users
-- ========================================

-- Function to auto-confirm users on signup
CREATE OR REPLACE FUNCTION auto_confirm_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Auto-confirm email for new users
    IF NEW.email_confirmed_at IS NULL THEN
        NEW.email_confirmed_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if it exists
DROP TRIGGER IF EXISTS auto_confirm_user_trigger ON auth.users;

-- Create trigger to auto-confirm new users
CREATE TRIGGER auto_confirm_user_trigger
    BEFORE INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION auto_confirm_user();

SELECT 'Created auto-confirmation trigger for new users' as result;

-- ========================================
-- OPTION 3: Create function to manually confirm users
-- ========================================

CREATE OR REPLACE FUNCTION confirm_user_email(user_email TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_id UUID;
    result JSON;
BEGIN
    -- Find user by email
    SELECT id INTO user_id
    FROM auth.users
    WHERE email = user_email;
    
    IF user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'User not found',
            'email', user_email
        );
    END IF;
    
    -- Confirm the user's email
    UPDATE auth.users 
    SET email_confirmed_at = NOW()
    WHERE id = user_id;
    
    -- Update public profile
    UPDATE public.users 
    SET email_verified = true
    WHERE id = user_id;
    
    RETURN json_build_object(
        'success', true,
        'message', 'User email confirmed',
        'email', user_email,
        'user_id', user_id,
        'confirmed_at', NOW()
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'email', user_email
    );
END;
$$;

SELECT 'Created manual confirmation function' as result;

-- ========================================
-- VERIFICATION
-- ========================================

-- Check current status
SELECT 'Current user status:' as info;
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_users,
    COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as unconfirmed_users
FROM auth.users;

-- Show recent users
SELECT 'Recent users:' as info;
SELECT 
    email,
    email_confirmed_at IS NOT NULL as confirmed,
    created_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- ========================================
-- USAGE INSTRUCTIONS
-- ========================================

-- To manually confirm a specific user:
-- SELECT confirm_user_email('user@example.com');

-- To check if auto-confirmation is working:
-- Try registering a new user and check if they're auto-confirmed

RAISE NOTICE '=== EMAIL CONFIRMATION DISABLED ===';
RAISE NOTICE 'All existing users have been confirmed';
RAISE NOTICE 'New users will be auto-confirmed on signup';
RAISE NOTICE 'To manually confirm a user: SELECT confirm_user_email(''email@example.com'');';
RAISE NOTICE 'This bypasses the email verification requirement';
RAISE NOTICE 'Users can now login immediately after registration';
