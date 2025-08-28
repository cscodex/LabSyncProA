-- Email Configuration Diagnostics (Keep Email Verification)
-- Run this in Supabase SQL Editor to diagnose email issues

-- ========================================
-- PART 1: CHECK CURRENT STATE
-- ========================================

SELECT '=== EMAIL SYSTEM DIAGNOSTICS ===' as section;

-- Check user counts and email status
SELECT 'User Statistics:' as info;
SELECT 
    COUNT(*) as total_auth_users,
    COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_users,
    COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as unconfirmed_users,
    COUNT(CASE WHEN recovery_sent_at IS NOT NULL THEN 1 END) as users_with_recovery_attempts
FROM auth.users;

-- Show recent signup attempts
SELECT 'Recent Signup Attempts (Last 24 hours):' as info;
SELECT 
    email,
    created_at,
    email_confirmed_at,
    confirmation_sent_at,
    CASE 
        WHEN email_confirmed_at IS NOT NULL THEN 'Confirmed ✓'
        WHEN confirmation_sent_at IS NOT NULL THEN 'Email sent, awaiting confirmation'
        ELSE 'No confirmation email sent'
    END as status
FROM auth.users 
WHERE created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- Check for failed email attempts
SELECT 'Users with pending confirmations:' as info;
SELECT 
    email,
    created_at,
    confirmation_sent_at,
    EXTRACT(EPOCH FROM (NOW() - confirmation_sent_at))/3600 as hours_since_confirmation_sent
FROM auth.users 
WHERE confirmation_sent_at IS NOT NULL 
AND email_confirmed_at IS NULL
ORDER BY confirmation_sent_at DESC
LIMIT 10;

-- Check password reset attempts
SELECT 'Recent Password Reset Attempts:' as info;
SELECT 
    email,
    recovery_sent_at,
    EXTRACT(EPOCH FROM (NOW() - recovery_sent_at))/3600 as hours_since_recovery_sent
FROM auth.users 
WHERE recovery_sent_at IS NOT NULL
AND recovery_sent_at > NOW() - INTERVAL '24 hours'
ORDER BY recovery_sent_at DESC;

-- ========================================
-- PART 2: CREATE MISSING PROFILES
-- ========================================

-- Create profiles for auth users without public profiles
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
    
    IF missing_count > 0 THEN
        RAISE NOTICE 'Found % users without public profiles', missing_count;
        
        -- Create missing profiles
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
        RAISE NOTICE 'Created % public profiles', created_count;
    ELSE
        RAISE NOTICE 'All users already have public profiles';
    END IF;
END $$;

-- ========================================
-- PART 3: TEST FUNCTIONS
-- ========================================

-- Function to test email sending capability
CREATE OR REPLACE FUNCTION test_email_system(test_email TEXT)
RETURNS TABLE(
    check_name TEXT,
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
    user_id UUID;
BEGIN
    -- Check 1: User existence
    SELECT EXISTS(
        SELECT 1 FROM auth.users WHERE email = test_email
    ) INTO user_exists;
    
    RETURN QUERY SELECT 
        'User Exists'::TEXT,
        CASE WHEN user_exists THEN 'PASS' ELSE 'INFO' END::TEXT,
        CASE WHEN user_exists THEN 'User found in database' ELSE 'User not found - can register' END::TEXT;
    
    IF user_exists THEN
        -- Get user details
        SELECT 
            email_confirmed_at IS NOT NULL,
            id
        INTO user_confirmed, user_id
        FROM auth.users 
        WHERE email = test_email;
        
        -- Check 2: Email confirmation status
        RETURN QUERY SELECT 
            'Email Confirmed'::TEXT,
            CASE WHEN user_confirmed THEN 'PASS' ELSE 'PENDING' END::TEXT,
            CASE WHEN user_confirmed THEN 'Email is confirmed' ELSE 'Email awaiting confirmation' END::TEXT;
        
        -- Check 3: Public profile exists
        SELECT EXISTS(
            SELECT 1 FROM public.users WHERE id = user_id
        ) INTO has_profile;
        
        RETURN QUERY SELECT 
            'Public Profile'::TEXT,
            CASE WHEN has_profile THEN 'PASS' ELSE 'MISSING' END::TEXT,
            CASE WHEN has_profile THEN 'Profile exists' ELSE 'Profile missing - will be created' END::TEXT;
        
        -- Check 4: Recent email activity
        RETURN QUERY SELECT 
            'Email Activity'::TEXT,
            'INFO'::TEXT,
            CASE 
                WHEN confirmation_sent_at > NOW() - INTERVAL '1 hour' THEN 'Confirmation email sent recently'
                WHEN recovery_sent_at > NOW() - INTERVAL '1 hour' THEN 'Recovery email sent recently'
                ELSE 'No recent email activity'
            END::TEXT
        FROM auth.users 
        WHERE email = test_email;
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT 
        'Error'::TEXT,
        'FAIL'::TEXT,
        SQLERRM::TEXT;
END;
$$;

-- ========================================
-- PART 4: FINAL STATUS
-- ========================================

SELECT '=== FINAL STATUS ===' as section;
SELECT 'Auth users:' as metric, COUNT(*) as count FROM auth.users;
SELECT 'Public profiles:' as metric, COUNT(*) as count FROM public.users;
SELECT 'Confirmed emails:' as metric, COUNT(*) as count FROM auth.users WHERE email_confirmed_at IS NOT NULL;
SELECT 'Missing profiles:' as metric, COUNT(*) as count
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL;

-- ========================================
-- TESTING INSTRUCTIONS
-- ========================================

SELECT '=== TESTING INSTRUCTIONS ===' as section;

-- To test your email system:
-- SELECT * FROM test_email_system('your-email@example.com');

RAISE NOTICE '=== EMAIL DIAGNOSTICS COMPLETE ===';
RAISE NOTICE 'To test your email system:';
RAISE NOTICE '1. Run: SELECT * FROM test_email_system(''your-email@example.com'');';
RAISE NOTICE '2. Check Supabase Dashboard -> Auth -> Email Templates';
RAISE NOTICE '3. Verify SMTP settings in Auth -> Settings';
RAISE NOTICE '4. Ensure redirect URLs are correct in Auth -> URL Configuration';
RAISE NOTICE '5. Test registration with a new email address';
RAISE NOTICE '6. Check spam folder if emails are not received';
