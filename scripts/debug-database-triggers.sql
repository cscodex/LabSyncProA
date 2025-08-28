-- Debug Database Triggers for LabSyncPro
-- Run this SQL to investigate why triggers are not firing

-- 1. Check if the trigger functions exist
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('handle_new_user', 'handle_user_email_confirmed');

-- 2. Check if the triggers exist and are enabled
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing,
    action_statement,
    trigger_schema
FROM information_schema.triggers 
WHERE trigger_schema = 'auth' 
AND event_object_table = 'users';

-- 3. Check current users in auth.users vs public.users
SELECT 
    'auth.users' as table_name,
    COUNT(*) as user_count
FROM auth.users
UNION ALL
SELECT 
    'public.users' as table_name,
    COUNT(*) as user_count
FROM public.users;

-- 4. Check for users in auth.users that don't have profiles in public.users
SELECT 
    au.id,
    au.email,
    au.created_at as auth_created,
    pu.id as profile_exists,
    pu.created_at as profile_created
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
ORDER BY au.created_at DESC
LIMIT 10;

-- 5. Check if the public.users table has the required columns
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'users'
ORDER BY ordinal_position;

-- 6. Check permissions on the public.users table
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.table_privileges 
WHERE table_schema = 'public' 
AND table_name = 'users';

-- 7. Test if we can manually insert into public.users
-- (This will help identify permission issues)
DO $$
DECLARE
    test_user_id UUID;
BEGIN
    -- Get a random UUID for testing
    test_user_id := gen_random_uuid();
    
    -- Try to insert a test record
    BEGIN
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
            is_active
        ) VALUES (
            test_user_id,
            'test@example.com',
            'Test',
            'User',
            'student',
            'email',
            false,
            false,
            false,
            true
        );
        
        RAISE NOTICE 'SUCCESS: Can insert into public.users table';
        
        -- Clean up test record
        DELETE FROM public.users WHERE id = test_user_id;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: Cannot insert into public.users table: %', SQLERRM;
    END;
END $$;

-- 8. Check if RLS is blocking the trigger
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'users';

-- 9. Check RLS policies on public.users
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'users';

-- 10. Test the trigger function manually
DO $$
DECLARE
    test_user_record auth.users%ROWTYPE;
BEGIN
    -- Create a mock user record for testing
    test_user_record.id := gen_random_uuid();
    test_user_record.email := 'trigger-test@example.com';
    test_user_record.created_at := NOW();
    test_user_record.email_confirmed_at := NULL;
    
    -- Try to call the trigger function manually
    BEGIN
        PERFORM public.handle_new_user();
        RAISE NOTICE 'SUCCESS: Trigger function exists and can be called';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: Trigger function failed: %', SQLERRM;
    END;
END $$;

-- 11. Check if there are any conflicting triggers
SELECT 
    t.trigger_name,
    t.event_manipulation,
    t.action_timing,
    t.action_statement
FROM information_schema.triggers t
WHERE t.event_object_schema = 'auth'
AND t.event_object_table = 'users'
ORDER BY t.action_order;

-- 12. Check auth.users table structure to understand available columns
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'auth' 
AND table_name = 'users'
ORDER BY ordinal_position;

-- 13. Create a simple test to see if triggers fire at all
CREATE OR REPLACE FUNCTION public.test_trigger_function()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Just log that the trigger fired
    RAISE NOTICE 'TRIGGER FIRED: User % created at %', NEW.email, NEW.created_at;
    RETURN NEW;
END;
$$;

-- Create a test trigger
DROP TRIGGER IF EXISTS test_trigger ON auth.users;
CREATE TRIGGER test_trigger
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.test_trigger_function();

-- Instructions for testing:
-- After running this script:
-- 1. Try to create a new user via Google OAuth
-- 2. Check the logs for "TRIGGER FIRED" message
-- 3. If you see the message, the trigger system works
-- 4. If not, there's a deeper issue with trigger permissions

SELECT 'Debug script completed. Check the results above for issues.' as status;
