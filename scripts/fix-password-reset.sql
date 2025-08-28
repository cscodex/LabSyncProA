-- Fix Password Reset Email Issues
-- Run this in Supabase SQL Editor

-- ========================================
-- PART 1: CHECK CURRENT AUTH CONFIGURATION
-- ========================================

-- Check auth configuration
SELECT 'CURRENT AUTH CONFIG:' as info;
SELECT 
    key,
    value
FROM auth.config 
WHERE key IN (
    'SITE_URL',
    'EXTERNAL_EMAIL_ENABLED',
    'MAILER_SECURE_EMAIL_CHANGE_ENABLED',
    'SECURITY_UPDATE_PASSWORD_REQUIRE_REAUTHENTICATION'
);

-- Check if there are any auth users
SELECT 'AUTH USERS COUNT:' as info;
SELECT COUNT(*) as total_users FROM auth.users;

-- Check recent auth attempts
SELECT 'RECENT AUTH ACTIVITY:' as info;
SELECT 
    email,
    created_at,
    email_confirmed_at,
    recovery_sent_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- ========================================
-- PART 2: UPDATE AUTH CONFIGURATION
-- ========================================

-- Ensure proper site URL is set
INSERT INTO auth.config (key, value) 
VALUES ('SITE_URL', 'https://labsyncpro-pptl.onrender.com')
ON CONFLICT (key) 
DO UPDATE SET value = 'https://labsyncpro-pptl.onrender.com';

-- Enable external email
INSERT INTO auth.config (key, value) 
VALUES ('EXTERNAL_EMAIL_ENABLED', 'true')
ON CONFLICT (key) 
DO UPDATE SET value = 'true';

-- Set proper redirect URLs
INSERT INTO auth.config (key, value) 
VALUES ('URI_ALLOW_LIST', 'https://labsyncpro-pptl.onrender.com/**,https://labsyncpro-pptl.onrender.com/auth/update-password')
ON CONFLICT (key) 
DO UPDATE SET value = 'https://labsyncpro-pptl.onrender.com/**,https://labsyncpro-pptl.onrender.com/auth/update-password';

-- ========================================
-- PART 3: TEST PASSWORD RESET FUNCTION
-- ========================================

-- Create a test function to check password reset
CREATE OR REPLACE FUNCTION test_password_reset(user_email TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    user_exists BOOLEAN;
BEGIN
    -- Check if user exists
    SELECT EXISTS(
        SELECT 1 FROM auth.users 
        WHERE email = user_email
    ) INTO user_exists;
    
    IF NOT user_exists THEN
        RETURN json_build_object(
            'success', false,
            'error', 'User not found',
            'email', user_email
        );
    END IF;
    
    -- Update recovery_sent_at to simulate reset request
    UPDATE auth.users 
    SET recovery_sent_at = NOW()
    WHERE email = user_email;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Password reset would be sent',
        'email', user_email,
        'recovery_sent_at', NOW()
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'email', user_email
    );
END;
$$;

-- ========================================
-- PART 4: VERIFICATION QUERIES
-- ========================================

SELECT 'UPDATED AUTH CONFIG:' as info;
SELECT 
    key,
    value
FROM auth.config 
WHERE key IN (
    'SITE_URL',
    'EXTERNAL_EMAIL_ENABLED',
    'URI_ALLOW_LIST'
);

-- Test with a sample email (replace with actual user email)
-- SELECT test_password_reset('your-test-email@example.com');

RAISE NOTICE '=== PASSWORD RESET CONFIGURATION UPDATED ===';
RAISE NOTICE 'Next steps:';
RAISE NOTICE '1. Check Supabase Dashboard -> Auth -> Email Templates';
RAISE NOTICE '2. Ensure Reset Password template is enabled';
RAISE NOTICE '3. Test with: SELECT test_password_reset(''your-email@example.com'');';
RAISE NOTICE '4. Check SMTP settings in Auth -> Settings';
