-- Fix Password Reset Email Issues
-- Run this in Supabase SQL Editor

-- ========================================
-- PART 1: CHECK CURRENT AUTH STATE
-- ========================================

-- Check if there are any auth users
SELECT 'AUTH USERS COUNT:' as info;
SELECT COUNT(*) as total_users FROM auth.users;

-- Check recent auth attempts and recovery status
SELECT 'RECENT AUTH ACTIVITY:' as info;
SELECT
    email,
    created_at,
    email_confirmed_at,
    recovery_sent_at,
    CASE
        WHEN recovery_sent_at IS NOT NULL THEN 'Recovery email sent'
        WHEN email_confirmed_at IS NOT NULL THEN 'Email confirmed'
        ELSE 'Pending confirmation'
    END as status
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;

-- Check for users with recent recovery attempts
SELECT 'RECENT RECOVERY ATTEMPTS:' as info;
SELECT
    email,
    recovery_sent_at,
    created_at
FROM auth.users
WHERE recovery_sent_at IS NOT NULL
ORDER BY recovery_sent_at DESC
LIMIT 5;

-- ========================================
-- PART 2: TEST PASSWORD RESET FUNCTION
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
-- PART 3: VERIFICATION AND TESTING
-- ========================================

-- Test with a sample email (replace with actual user email)
-- SELECT test_password_reset('your-test-email@example.com');

-- Check if any users have pending recovery tokens
SELECT 'USERS WITH RECOVERY TOKENS:' as info;
SELECT
    email,
    recovery_sent_at,
    EXTRACT(EPOCH FROM (NOW() - recovery_sent_at))/3600 as hours_since_recovery
FROM auth.users
WHERE recovery_sent_at IS NOT NULL
AND recovery_sent_at > NOW() - INTERVAL '24 hours'
ORDER BY recovery_sent_at DESC;

-- Clean up old recovery attempts (optional)
-- UPDATE auth.users
-- SET recovery_sent_at = NULL
-- WHERE recovery_sent_at < NOW() - INTERVAL '24 hours';

RAISE NOTICE '=== PASSWORD RESET DIAGNOSTICS COMPLETE ===';
RAISE NOTICE 'Next steps:';
RAISE NOTICE '1. Check Supabase Dashboard -> Auth -> Email Templates';
RAISE NOTICE '2. Ensure Reset Password template is enabled';
RAISE NOTICE '3. Test with: SELECT test_password_reset(''your-email@example.com'');';
RAISE NOTICE '4. Check SMTP settings in Auth -> Settings';
RAISE NOTICE '5. Verify NEXT_PUBLIC_SITE_URL is set in Render environment';
RAISE NOTICE '6. Check that redirect URLs are configured in Supabase Auth settings';
