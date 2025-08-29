-- Quick Email Test - Run this immediately to check email status
-- This will help diagnose why emails stopped working

-- ========================================
-- IMMEDIATE EMAIL STATUS CHECK
-- ========================================

SELECT '=== IMMEDIATE EMAIL STATUS CHECK ===' as section;
SELECT NOW() as current_time;

-- Check recent email activity (last 30 minutes)
SELECT 'Recent Email Activity (Last 30 minutes):' as info;
SELECT 
    email,
    created_at,
    email_confirmed_at,
    confirmation_sent_at,
    recovery_sent_at,
    CASE 
        WHEN recovery_sent_at > NOW() - INTERVAL '30 minutes' THEN '🔑 Password Reset Attempted'
        WHEN confirmation_sent_at > NOW() - INTERVAL '30 minutes' THEN '📧 Confirmation Email Sent'
        WHEN created_at > NOW() - INTERVAL '30 minutes' THEN '👤 New User Created'
        ELSE '⏰ Older Activity'
    END as recent_activity,
    EXTRACT(EPOCH FROM (NOW() - GREATEST(created_at, COALESCE(confirmation_sent_at, created_at), COALESCE(recovery_sent_at, created_at))))/60 as minutes_ago
FROM auth.users 
WHERE created_at > NOW() - INTERVAL '30 minutes'
   OR confirmation_sent_at > NOW() - INTERVAL '30 minutes'
   OR recovery_sent_at > NOW() - INTERVAL '30 minutes'
ORDER BY GREATEST(created_at, COALESCE(confirmation_sent_at, created_at), COALESCE(recovery_sent_at, created_at)) DESC;

-- Check if any emails are stuck in pending state
SELECT 'Emails Stuck in Pending (Created but not confirmed):' as info;
SELECT 
    email,
    created_at,
    confirmation_sent_at,
    EXTRACT(EPOCH FROM (NOW() - created_at))/60 as minutes_waiting,
    CASE 
        WHEN confirmation_sent_at IS NULL THEN '❌ No confirmation email sent'
        WHEN EXTRACT(EPOCH FROM (NOW() - confirmation_sent_at))/60 > 15 THEN '⚠️ Email sent >15 min ago'
        ELSE '✅ Recent email sent'
    END as email_status
FROM auth.users 
WHERE email_confirmed_at IS NULL
  AND created_at > NOW() - INTERVAL '2 hours'
ORDER BY created_at DESC;

-- Check recent password reset attempts
SELECT 'Recent Password Reset Attempts:' as info;
SELECT 
    email,
    recovery_sent_at,
    EXTRACT(EPOCH FROM (NOW() - recovery_sent_at))/60 as minutes_ago,
    CASE 
        WHEN EXTRACT(EPOCH FROM (NOW() - recovery_sent_at))/60 > 15 THEN '⚠️ Reset email sent >15 min ago'
        ELSE '✅ Recent reset email'
    END as reset_status
FROM auth.users 
WHERE recovery_sent_at > NOW() - INTERVAL '2 hours'
ORDER BY recovery_sent_at DESC;

-- ========================================
-- QUICK EMAIL SYSTEM TEST
-- ========================================

-- Function to test email system status
CREATE OR REPLACE FUNCTION quick_email_test()
RETURNS TABLE(
    test_name TEXT,
    status TEXT,
    details TEXT,
    timestamp TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Test 1: Check if we can access auth.users
    BEGIN
        PERFORM COUNT(*) FROM auth.users LIMIT 1;
        RETURN QUERY SELECT 
            'Database Access'::TEXT,
            'PASS'::TEXT,
            'Can access auth.users table'::TEXT,
            NOW();
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 
            'Database Access'::TEXT,
            'FAIL'::TEXT,
            SQLERRM::TEXT,
            NOW();
    END;
    
    -- Test 2: Check recent email activity
    RETURN QUERY SELECT 
        'Recent Activity'::TEXT,
        CASE WHEN COUNT(*) > 0 THEN 'ACTIVE' ELSE 'QUIET' END::TEXT,
        ('Found ' || COUNT(*) || ' recent email events')::TEXT,
        NOW()
    FROM auth.users 
    WHERE created_at > NOW() - INTERVAL '1 hour'
       OR confirmation_sent_at > NOW() - INTERVAL '1 hour'
       OR recovery_sent_at > NOW() - INTERVAL '1 hour';
    
    -- Test 3: Check for stuck emails
    RETURN QUERY SELECT 
        'Stuck Emails'::TEXT,
        CASE WHEN COUNT(*) > 0 THEN 'WARNING' ELSE 'GOOD' END::TEXT,
        ('Found ' || COUNT(*) || ' unconfirmed emails >15 min old')::TEXT,
        NOW()
    FROM auth.users 
    WHERE email_confirmed_at IS NULL
      AND confirmation_sent_at < NOW() - INTERVAL '15 minutes';
      
END;
$$;

-- Run the quick test
SELECT 'QUICK EMAIL SYSTEM TEST:' as info;
SELECT * FROM quick_email_test();

-- ========================================
-- TROUBLESHOOTING CHECKLIST
-- ========================================

SELECT '=== TROUBLESHOOTING CHECKLIST ===' as section;

SELECT 'Check these items:' as checklist;
SELECT '1. ✅ Gmail SMTP configured in Supabase Auth -> Settings' as item;
SELECT '2. ✅ Email templates enabled in Supabase Auth -> Email Templates' as item;
SELECT '3. ✅ Site URL set correctly in Supabase Auth -> URL Configuration' as item;
SELECT '4. ✅ NEXT_PUBLIC_SITE_URL environment variable set in Render' as item;
SELECT '5. ✅ Check Gmail inbox and spam folder' as item;
SELECT '6. ✅ Check Render deployment logs for EMAIL_DEBUG messages' as item;

-- Show current configuration status
SELECT 'Current Email Statistics:' as stats;
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_users,
    COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as pending_users,
    COUNT(CASE WHEN recovery_sent_at > NOW() - INTERVAL '24 hours' THEN 1 END) as recent_resets,
    COUNT(CASE WHEN created_at > NOW() - INTERVAL '1 hour' THEN 1 END) as recent_signups
FROM auth.users;

RAISE NOTICE '=== QUICK EMAIL TEST COMPLETE ===';
RAISE NOTICE 'If emails stopped working 15 minutes ago:';
RAISE NOTICE '1. Check if Gmail SMTP settings changed in Supabase';
RAISE NOTICE '2. Check if Gmail App Password expired';
RAISE NOTICE '3. Check Render logs for EMAIL_DEBUG messages';
RAISE NOTICE '4. Try the email status API: /api/email-status';
RAISE NOTICE '5. Check Gmail account for any security alerts';
