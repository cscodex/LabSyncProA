-- Debug Current Database State
-- Run this to check if the schema reset worked properly

-- 1. Check if users table exists and has correct structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'users'
ORDER BY ordinal_position;

-- 2. Check if user_role enum exists
SELECT 
    enumlabel as role_value
FROM pg_enum 
WHERE enumtypid = (
    SELECT oid FROM pg_type WHERE typname = 'user_role'
)
ORDER BY enumsortorder;

-- 3. Check if triggers exist
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'auth' 
AND event_object_table = 'users';

-- 4. Check current users in both tables
SELECT 
    'auth.users' as table_name,
    COUNT(*) as user_count,
    array_agg(email) as emails
FROM auth.users
UNION ALL
SELECT 
    'public.users' as table_name,
    COUNT(*) as user_count,
    array_agg(email) as emails
FROM public.users;

-- 5. Check for any users in auth.users without profiles
SELECT 
    au.id,
    au.email,
    au.created_at as auth_created,
    pu.id as has_profile,
    pu.role as profile_role
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
ORDER BY au.created_at DESC;

-- 6. Check RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'users';

-- 7. Test trigger function manually (if it exists)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_schema = 'public' 
        AND routine_name = 'handle_new_user'
    ) THEN
        RAISE NOTICE 'Trigger function handle_new_user exists';
    ELSE
        RAISE NOTICE 'Trigger function handle_new_user does NOT exist';
    END IF;
END $$;

SELECT 'Debug check completed' as status;
