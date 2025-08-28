-- Complete Debug and Fix for LabSyncPro
-- This script will diagnose and fix all issues

-- ========================================
-- PART 1: COMPREHENSIVE DIAGNOSTICS
-- ========================================

-- 1. Check if triggers exist and are enabled
SELECT 'TRIGGER DIAGNOSTICS:' as section;
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing,
    action_statement,
    trigger_schema
FROM information_schema.triggers 
WHERE event_object_schema = 'auth' 
AND event_object_table = 'users';

-- 2. Check if trigger functions exist
SELECT 'FUNCTION DIAGNOSTICS:' as section;
SELECT 
    routine_name,
    routine_type,
    routine_schema
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%user%';

-- 3. Check current data state
SELECT 'DATA STATE:' as section;
SELECT 'auth.users count:' as table_name, COUNT(*) as count FROM auth.users;
SELECT 'public.users count:' as table_name, COUNT(*) as count FROM public.users;

-- 4. Show recent auth.users
SELECT 'RECENT AUTH USERS:' as section;
SELECT 
    id,
    email,
    created_at,
    email_confirmed_at,
    raw_user_meta_data->>'provider' as provider,
    raw_user_meta_data->>'iss' as issuer
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 5. Show users without profiles
SELECT 'USERS WITHOUT PROFILES:' as section;
SELECT 
    au.id,
    au.email,
    au.created_at,
    au.raw_user_meta_data->>'provider' as provider
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL;

-- ========================================
-- PART 2: COMPLETE CLEANUP AND REBUILD
-- ========================================

-- 6. Drop everything and start fresh
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_email_confirmed ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_user_updated() CASCADE;
DROP FUNCTION IF EXISTS public.handle_user_email_confirmed() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user_insert(auth.users) CASCADE;

-- 7. Temporarily disable RLS to ensure triggers can work
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- 8. Create the most basic trigger function that WILL work
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Log everything for debugging
    RAISE NOTICE '=== TRIGGER FIRED ===';
    RAISE NOTICE 'User ID: %', NEW.id;
    RAISE NOTICE 'Email: %', NEW.email;
    RAISE NOTICE 'Created at: %', NEW.created_at;
    RAISE NOTICE 'Email confirmed: %', NEW.email_confirmed_at;
    RAISE NOTICE 'Raw metadata: %', NEW.raw_user_meta_data;
    
    -- Check if user already exists
    IF EXISTS (SELECT 1 FROM public.users WHERE id = NEW.id) THEN
        RAISE NOTICE 'User already exists, skipping';
        RETURN NEW;
    END IF;
    
    -- Insert with absolute minimal data to avoid any issues
    INSERT INTO public.users (
        id,
        email,
        first_name,
        last_name,
        role,
        auth_provider,
        registration_completed,
        profile_completed,
        email_verified,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'given_name', NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'family_name', NEW.raw_user_meta_data->>'last_name', ''),
        'student'::user_role,
        CASE 
            WHEN NEW.email LIKE '%@gmail.com' THEN 'google'
            WHEN NEW.raw_user_meta_data->>'iss' = 'https://accounts.google.com' THEN 'google'
            WHEN NEW.raw_user_meta_data->>'provider' = 'google' THEN 'google'
            ELSE 'email'
        END,
        true,
        false,
        COALESCE(NEW.email_confirmed_at IS NOT NULL, false),
        true,
        COALESCE(NEW.created_at, NOW()),
        NOW()
    );
    
    RAISE NOTICE '=== PROFILE CREATED SUCCESSFULLY ===';
    RETURN NEW;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '=== TRIGGER ERROR: % ===', SQLERRM;
    -- Don't fail the auth insert
    RETURN NEW;
END;
$$;

-- 9. Grant all necessary permissions
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO postgres;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO service_role;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO anon;

-- 10. Create the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW 
    EXECUTE FUNCTION public.handle_new_user();

-- 11. Test the trigger immediately
DO $$
DECLARE
    test_id UUID := gen_random_uuid();
    profile_created BOOLEAN := false;
BEGIN
    RAISE NOTICE '=== TESTING TRIGGER ===';
    
    -- Insert test user
    INSERT INTO auth.users (
        id,
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        created_at,
        updated_at,
        confirmation_token,
        recovery_token,
        raw_user_meta_data
    ) VALUES (
        test_id,
        '00000000-0000-0000-0000-000000000000',
        'trigger-test-' || extract(epoch from now()) || '@test.com',
        'test',
        NOW(),
        NOW(),
        NOW(),
        '',
        '',
        '{"provider": "google", "given_name": "Test", "family_name": "User"}'::jsonb
    );
    
    -- Check if profile was created
    SELECT EXISTS(SELECT 1 FROM public.users WHERE id = test_id) INTO profile_created;
    
    IF profile_created THEN
        RAISE NOTICE '=== TRIGGER TEST: SUCCESS ===';
    ELSE
        RAISE NOTICE '=== TRIGGER TEST: FAILED ===';
    END IF;
    
    -- Clean up
    DELETE FROM public.users WHERE id = test_id;
    DELETE FROM auth.users WHERE id = test_id;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '=== TRIGGER TEST ERROR: % ===', SQLERRM;
END $$;

-- 12. Create profiles for ALL existing auth.users
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
        WHEN au.raw_user_meta_data->>'iss' = 'https://accounts.google.com' THEN 'google'
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

-- 13. Re-enable RLS with simple policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Service role can do everything" ON public.users;
DROP POLICY IF EXISTS "Allow trigger inserts" ON public.users;
DROP POLICY IF EXISTS "Trigger can insert users" ON public.users;

-- Create simple, working policies
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Service role full access" ON public.users
    FOR ALL USING (auth.role() = 'service_role');

-- CRITICAL: Allow inserts without user context (for triggers)
CREATE POLICY "Allow all inserts" ON public.users
    FOR INSERT WITH CHECK (true);

-- 14. Final verification
SELECT '=== FINAL STATUS ===' as section;
SELECT 'Trigger exists:' as check, 
       EXISTS(
           SELECT 1 FROM information_schema.triggers 
           WHERE trigger_name = 'on_auth_user_created'
       ) as result;

SELECT 'Function exists:' as check,
       EXISTS(
           SELECT 1 FROM information_schema.routines 
           WHERE routine_name = 'handle_new_user'
       ) as result;

SELECT 'Auth users:' as table_name, COUNT(*) as count FROM auth.users;
SELECT 'Public users:' as table_name, COUNT(*) as count FROM public.users;

SELECT 'Users still missing profiles:' as check, COUNT(*) as count
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL;

RAISE NOTICE '=== SETUP COMPLETE ===';
RAISE NOTICE 'Now test by signing up with a new Google account';
RAISE NOTICE 'Check Supabase logs for trigger messages';
RAISE NOTICE 'If trigger still does not fire, there may be a Supabase configuration issue';
