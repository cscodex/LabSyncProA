-- Simple Password Reset Diagnostics and Fix
-- Run this in Supabase SQL Editor

-- ========================================
-- DIAGNOSTICS: Check Current State
-- ========================================

SELECT '=== CURRENT AUTH STATE ===' as section;

-- Check total users
SELECT 'Total auth users:' as metric, COUNT(*) as value FROM auth.users;
SELECT 'Total public users:' as metric, COUNT(*) as value FROM public.users;

-- Check recent users and their email status
SELECT 'Recent users and email status:' as info;
SELECT 
    email,
    email_confirmed_at IS NOT NULL as email_confirmed,
    recovery_sent_at,
    created_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- Check for users with recent recovery attempts
SELECT 'Recent password reset attempts:' as info;
SELECT 
    email,
    recovery_sent_at,
    CASE 
        WHEN recovery_sent_at > NOW() - INTERVAL '1 hour' THEN 'Very recent (< 1 hour)'
        WHEN recovery_sent_at > NOW() - INTERVAL '24 hours' THEN 'Recent (< 24 hours)'
        ELSE 'Old (> 24 hours)'
    END as recency
FROM auth.users 
WHERE recovery_sent_at IS NOT NULL
ORDER BY recovery_sent_at DESC 
LIMIT 10;

-- ========================================
-- TEST FUNCTION: Simulate Password Reset
-- ========================================

CREATE OR REPLACE FUNCTION test_password_reset_flow(user_email TEXT)
RETURNS TABLE(
    step TEXT,
    status TEXT,
    details TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_exists BOOLEAN;
    user_confirmed BOOLEAN;
    user_id UUID;
BEGIN
    -- Step 1: Check if user exists
    SELECT EXISTS(
        SELECT 1 FROM auth.users WHERE email = user_email
    ) INTO user_exists;
    
    RETURN QUERY SELECT 
        'User Exists'::TEXT,
        CASE WHEN user_exists THEN 'PASS' ELSE 'FAIL' END::TEXT,
        CASE WHEN user_exists THEN 'User found in auth.users' ELSE 'User not found' END::TEXT;
    
    IF NOT user_exists THEN
        RETURN;
    END IF;
    
    -- Step 2: Check if email is confirmed
    SELECT 
        email_confirmed_at IS NOT NULL,
        id
    INTO user_confirmed, user_id
    FROM auth.users 
    WHERE email = user_email;
    
    RETURN QUERY SELECT 
        'Email Confirmed'::TEXT,
        CASE WHEN user_confirmed THEN 'PASS' ELSE 'WARNING' END::TEXT,
        CASE WHEN user_confirmed THEN 'Email is confirmed' ELSE 'Email not confirmed - may affect reset' END::TEXT;
    
    -- Step 3: Check if user has public profile
    RETURN QUERY SELECT 
        'Public Profile'::TEXT,
        CASE WHEN EXISTS(SELECT 1 FROM public.users WHERE id = user_id) THEN 'PASS' ELSE 'WARNING' END::TEXT,
        CASE WHEN EXISTS(SELECT 1 FROM public.users WHERE id = user_id) THEN 'Profile exists' ELSE 'No public profile' END::TEXT;
    
    -- Step 4: Simulate recovery request
    UPDATE auth.users 
    SET recovery_sent_at = NOW()
    WHERE email = user_email;
    
    RETURN QUERY SELECT 
        'Recovery Simulation'::TEXT,
        'PASS'::TEXT,
        'Updated recovery_sent_at timestamp'::TEXT;
    
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 
        'Error'::TEXT,
        'FAIL'::TEXT,
        SQLERRM::TEXT;
END;
$$;

-- ========================================
-- INSTRUCTIONS FOR MANUAL TESTING
-- ========================================

SELECT '=== TESTING INSTRUCTIONS ===' as section;

-- To test with your email, uncomment and modify this line:
-- SELECT * FROM test_password_reset_flow('your-email@example.com');

SELECT 'To test password reset:' as instruction;
SELECT '1. Replace your-email@example.com with your actual email' as step;
SELECT '2. Run: SELECT * FROM test_password_reset_flow(''your-email@example.com'');' as step;
SELECT '3. Check the results for any FAIL or WARNING statuses' as step;

-- ========================================
-- COMMON FIXES
-- ========================================

SELECT '=== COMMON FIXES ===' as section;

-- Create missing public profiles for auth users
INSERT INTO public.users (
    id, email, first_name, last_name, role, auth_provider,
    registration_completed, profile_completed, email_verified, is_active,
    created_at, updated_at
)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'given_name', au.raw_user_meta_data->>'first_name', ''),
    COALESCE(au.raw_user_meta_data->>'family_name', au.raw_user_meta_data->>'last_name', ''),
    'student'::user_role,
    CASE 
        WHEN au.email LIKE '%@gmail.com' THEN 'google'
        WHEN au.raw_user_meta_data->>'provider' = 'google' THEN 'google'
        ELSE 'email'
    END,
    true,
    false,
    COALESCE(au.email_confirmed_at IS NOT NULL, false),
    true,
    au.created_at,
    NOW()
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL
ON CONFLICT (id) DO NOTHING;

SELECT 'Created missing public profiles for:' as result, COUNT(*) as count
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL;

-- ========================================
-- FINAL STATUS
-- ========================================

SELECT '=== FINAL STATUS ===' as section;
SELECT 'Auth users:' as table_name, COUNT(*) as count FROM auth.users;
SELECT 'Public users:' as table_name, COUNT(*) as count FROM public.users;
SELECT 'Users missing profiles:' as issue, COUNT(*) as count
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL;

RAISE NOTICE '=== PASSWORD RESET DIAGNOSTICS COMPLETE ===';
RAISE NOTICE 'Next steps if password reset still fails:';
RAISE NOTICE '1. Check Supabase Dashboard -> Auth -> Email Templates';
RAISE NOTICE '2. Verify SMTP settings in Auth -> Settings';
RAISE NOTICE '3. Ensure NEXT_PUBLIC_SITE_URL is set in Render: https://labsyncpro-pptl.onrender.com';
RAISE NOTICE '4. Check redirect URLs in Supabase Auth -> URL Configuration';
RAISE NOTICE '5. Test with: SELECT * FROM test_password_reset_flow(''your-email@example.com'');';
