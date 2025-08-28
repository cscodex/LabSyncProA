-- Test Gmail SMTP Configuration
-- Run this after setting up Gmail SMTP in Supabase

-- ========================================
-- PART 1: CHECK CURRENT EMAIL STATUS
-- ========================================

SELECT '=== GMAIL SMTP TEST ===' as section;

-- Check recent email attempts
SELECT 'Recent Email Activity:' as info;
SELECT 
    email,
    created_at,
    email_confirmed_at,
    confirmation_sent_at,
    recovery_sent_at,
    CASE 
        WHEN email_confirmed_at IS NOT NULL THEN 'Email Confirmed ✓'
        WHEN confirmation_sent_at IS NOT NULL THEN 'Confirmation Email Sent'
        WHEN recovery_sent_at IS NOT NULL THEN 'Recovery Email Sent'
        ELSE 'No Email Activity'
    END as email_status
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 10;

-- ========================================
-- PART 2: CREATE TEST FUNCTION
-- ========================================

-- Function to simulate email sending test
CREATE OR REPLACE FUNCTION test_gmail_smtp(test_email TEXT)
RETURNS TABLE(
    test_step TEXT,
    status TEXT,
    message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_exists BOOLEAN;
    user_id UUID;
BEGIN
    -- Step 1: Check if user exists
    SELECT EXISTS(
        SELECT 1 FROM auth.users WHERE email = test_email
    ) INTO user_exists;
    
    IF user_exists THEN
        -- User exists - test password reset
        RETURN QUERY SELECT 
            'User Status'::TEXT,
            'EXISTS'::TEXT,
            'User found - can test password reset'::TEXT;
        
        -- Update recovery timestamp to simulate reset request
        UPDATE auth.users 
        SET recovery_sent_at = NOW()
        WHERE email = test_email;
        
        RETURN QUERY SELECT 
            'Password Reset Test'::TEXT,
            'SIMULATED'::TEXT,
            'Recovery timestamp updated - check if email is sent'::TEXT;
            
    ELSE
        -- User doesn't exist - ready for registration test
        RETURN QUERY SELECT 
            'User Status'::TEXT,
            'NEW'::TEXT,
            'Email available for registration test'::TEXT;
        
        RETURN QUERY SELECT 
            'Registration Test'::TEXT,
            'READY'::TEXT,
            'Try registering with this email to test confirmation'::TEXT;
    END IF;
    
    -- Check SMTP configuration status
    RETURN QUERY SELECT 
        'SMTP Configuration'::TEXT,
        'CHECK_DASHBOARD'::TEXT,
        'Verify Gmail SMTP settings in Supabase Auth -> Settings'::TEXT;
        
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 
        'Error'::TEXT,
        'FAIL'::TEXT,
        SQLERRM::TEXT;
END;
$$;

-- ========================================
-- PART 3: EMAIL TEMPLATE VERIFICATION
-- ========================================

-- Check if we have proper email templates
SELECT 'Email Template Check:' as info;
SELECT 'Verify these templates exist in Supabase Dashboard:' as instruction;
SELECT '1. Confirm signup template (enabled)' as template;
SELECT '2. Reset password template (enabled)' as template;
SELECT '3. Templates should use {{ .ConfirmationURL }} variable' as template;

-- ========================================
-- PART 4: TESTING INSTRUCTIONS
-- ========================================

SELECT '=== TESTING INSTRUCTIONS ===' as section;

-- Test with your email
-- SELECT * FROM test_gmail_smtp('your-test-email@gmail.com');

SELECT 'To test Gmail SMTP:' as step;
SELECT '1. Ensure Gmail App Password is set in Supabase SMTP settings' as instruction;
SELECT '2. Run: SELECT * FROM test_gmail_smtp(''your-email@gmail.com'');' as instruction;
SELECT '3. Try registering with a new email address' as instruction;
SELECT '4. Check Gmail inbox and spam folder' as instruction;
SELECT '5. Try password reset with existing user' as instruction;

-- ========================================
-- PART 5: TROUBLESHOOTING
-- ========================================

SELECT '=== TROUBLESHOOTING ===' as section;

SELECT 'If emails still not working:' as issue;
SELECT '1. Check Gmail App Password is correct (16 characters)' as solution;
SELECT '2. Verify 2FA is enabled on Gmail account' as solution;
SELECT '3. Check Supabase logs for SMTP errors' as solution;
SELECT '4. Ensure SMTP settings are saved in Supabase' as solution;
SELECT '5. Try with different Gmail account' as solution;
SELECT '6. Check if Gmail is blocking the app' as solution;

-- Show current user stats
SELECT '=== CURRENT STATS ===' as section;
SELECT 'Total users:' as metric, COUNT(*) as value FROM auth.users;
SELECT 'Confirmed users:' as metric, COUNT(*) as value FROM auth.users WHERE email_confirmed_at IS NOT NULL;
SELECT 'Pending confirmation:' as metric, COUNT(*) as value FROM auth.users WHERE email_confirmed_at IS NULL;
SELECT 'Recent recovery attempts:' as metric, COUNT(*) as value FROM auth.users WHERE recovery_sent_at > NOW() - INTERVAL '24 hours';

RAISE NOTICE '=== GMAIL SMTP TEST READY ===';
RAISE NOTICE 'Next steps:';
RAISE NOTICE '1. Configure Gmail SMTP in Supabase Dashboard';
RAISE NOTICE '2. Run: SELECT * FROM test_gmail_smtp(''your-email@gmail.com'');';
RAISE NOTICE '3. Test registration with new email';
RAISE NOTICE '4. Test password reset with existing email';
RAISE NOTICE '5. Check Gmail inbox for emails';
