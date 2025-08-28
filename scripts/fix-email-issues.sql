-- Fix All Email Issues (Registration & Password Reset)
-- Run this in Supabase SQL Editor

-- ========================================
-- PART 1: DIAGNOSTICS
-- ========================================

SELECT '=== EMAIL DIAGNOSTICS ===' as section;

-- Check current users and their email status
SELECT 'User Email Status:' as info;
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_users,
    COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as unconfirmed_users,
    COUNT(CASE WHEN recovery_sent_at IS NOT NULL THEN 1 END) as users_with_recovery_attempts
FROM auth.users;

-- Show recent signup attempts
SELECT 'Recent Signup Attempts:' as info;
SELECT 
    email,
    created_at,
    email_confirmed_at,
    CASE 
        WHEN email_confirmed_at IS NOT NULL THEN 'Confirmed'
        WHEN created_at > NOW() - INTERVAL '1 hour' THEN 'Recent signup - pending confirmation'
        ELSE 'Old signup - not confirmed'
    END as status
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 10;

-- Check for users without public profiles
SELECT 'Users Missing Public Profiles:' as info;
SELECT COUNT(*) as missing_profiles
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL;

-- ========================================
-- PART 2: CREATE MISSING PROFILES
-- ========================================

-- Count missing profiles before creating them
DO $$
DECLARE
    missing_count INTEGER;
    created_count INTEGER;
BEGIN
    -- Count missing profiles
    SELECT COUNT(*) INTO missing_count
    FROM auth.users au
    LEFT JOIN public.users pu ON au.id = pu.id
    WHERE pu.id IS NULL;

    RAISE NOTICE 'Found % users without profiles', missing_count;

    -- Create profiles for users who don't have them
    INSERT INTO public.users (
        id, email, first_name, last_name, role, auth_provider,
        registration_completed, profile_completed, email_verified, is_active,
        created_at, updated_at
    )
    SELECT
        au.id,
        au.email,
        COALESCE(au.raw_user_meta_data->>'first_name', au.raw_user_meta_data->>'given_name', ''),
        COALESCE(au.raw_user_meta_data->>'last_name', au.raw_user_meta_data->>'family_name', ''),
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

    GET DIAGNOSTICS created_count = ROW_COUNT;
    RAISE NOTICE 'Created % user profiles', created_count;
END $$;

SELECT 'Profile creation completed' as status;

-- ========================================
-- PART 3: EMAIL TESTING FUNCTIONS
-- ========================================

-- Function to test registration flow
CREATE OR REPLACE FUNCTION test_registration_flow(test_email TEXT)
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
    has_profile BOOLEAN;
BEGIN
    -- Check if user already exists
    SELECT EXISTS(
        SELECT 1 FROM auth.users WHERE email = test_email
    ) INTO user_exists;
    
    RETURN QUERY SELECT 
        'User Existence Check'::TEXT,
        CASE WHEN user_exists THEN 'WARNING' ELSE 'PASS' END::TEXT,
        CASE WHEN user_exists THEN 'User already exists - cannot register again' ELSE 'Email available for registration' END::TEXT;
    
    IF user_exists THEN
        -- Check confirmation status
        SELECT email_confirmed_at IS NOT NULL
        INTO user_confirmed
        FROM auth.users 
        WHERE email = test_email;
        
        RETURN QUERY SELECT 
            'Email Confirmation'::TEXT,
            CASE WHEN user_confirmed THEN 'PASS' ELSE 'FAIL' END::TEXT,
            CASE WHEN user_confirmed THEN 'Email is confirmed' ELSE 'Email not confirmed - check email templates' END::TEXT;
        
        -- Check profile existence
        SELECT EXISTS(
            SELECT 1 FROM public.users pu 
            JOIN auth.users au ON pu.id = au.id 
            WHERE au.email = test_email
        ) INTO has_profile;
        
        RETURN QUERY SELECT 
            'Public Profile'::TEXT,
            CASE WHEN has_profile THEN 'PASS' ELSE 'FAIL' END::TEXT,
            CASE WHEN has_profile THEN 'Public profile exists' ELSE 'Missing public profile' END::TEXT;
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 
        'Error'::TEXT,
        'FAIL'::TEXT,
        SQLERRM::TEXT;
END;
$$;

-- Function to test password reset flow
CREATE OR REPLACE FUNCTION test_password_reset_flow(test_email TEXT)
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
    -- Check if user exists
    SELECT EXISTS(
        SELECT 1 FROM auth.users WHERE email = test_email
    ) INTO user_exists;
    
    RETURN QUERY SELECT 
        'User Exists'::TEXT,
        CASE WHEN user_exists THEN 'PASS' ELSE 'FAIL' END::TEXT,
        CASE WHEN user_exists THEN 'User found' ELSE 'User not found - register first' END::TEXT;
    
    IF user_exists THEN
        SELECT 
            email_confirmed_at IS NOT NULL,
            id
        INTO user_confirmed, user_id
        FROM auth.users 
        WHERE email = test_email;
        
        RETURN QUERY SELECT 
            'Email Confirmed'::TEXT,
            CASE WHEN user_confirmed THEN 'PASS' ELSE 'WARNING' END::TEXT,
            CASE WHEN user_confirmed THEN 'Email confirmed' ELSE 'Email not confirmed - may affect reset' END::TEXT;
        
        -- Simulate password reset
        UPDATE auth.users 
        SET recovery_sent_at = NOW()
        WHERE email = test_email;
        
        RETURN QUERY SELECT 
            'Password Reset Simulation'::TEXT,
            'PASS'::TEXT,
            'Recovery timestamp updated'::TEXT;
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 
        'Error'::TEXT,
        'FAIL'::TEXT,
        SQLERRM::TEXT;
END;
$$;

-- ========================================
-- PART 4: CLEANUP AND VERIFICATION
-- ========================================

-- Clean up old recovery attempts (optional)
UPDATE auth.users 
SET recovery_sent_at = NULL 
WHERE recovery_sent_at < NOW() - INTERVAL '24 hours';

-- Final status check
SELECT '=== FINAL STATUS ===' as section;
SELECT 'Total auth users:' as metric, COUNT(*) as value FROM auth.users;
SELECT 'Confirmed users:' as metric, COUNT(*) as value FROM auth.users WHERE email_confirmed_at IS NOT NULL;
SELECT 'Users with profiles:' as metric, COUNT(*) as value FROM public.users;
SELECT 'Missing profiles:' as metric, COUNT(*) as value
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL;

-- ========================================
-- TESTING INSTRUCTIONS
-- ========================================

SELECT '=== TESTING INSTRUCTIONS ===' as section;

-- Test registration flow (replace with your email)
-- SELECT * FROM test_registration_flow('your-email@example.com');

-- Test password reset flow (replace with your email)
-- SELECT * FROM test_password_reset_flow('your-email@example.com');

RAISE NOTICE '=== EMAIL CONFIGURATION DIAGNOSTICS COMPLETE ===';
RAISE NOTICE 'Next steps:';
RAISE NOTICE '1. Set NEXT_PUBLIC_SITE_URL in Render: https://labsyncpro-pptl.onrender.com';
RAISE NOTICE '2. Check Supabase Auth -> Email Templates (Confirm signup, Reset password)';
RAISE NOTICE '3. Verify SMTP settings in Auth -> Settings';
RAISE NOTICE '4. Test with: SELECT * FROM test_registration_flow(''your-email@example.com'');';
RAISE NOTICE '5. Test with: SELECT * FROM test_password_reset_flow(''your-email@example.com'');';
RAISE NOTICE '6. Check Supabase Auth -> URL Configuration for proper redirect URLs';
