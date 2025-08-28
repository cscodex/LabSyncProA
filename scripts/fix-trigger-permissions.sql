-- Fix Trigger Permissions and Setup
-- This script ensures triggers can actually run and create users

-- 1. First, check what's currently in the auth.users table
SELECT 'Current auth.users:' as info;
SELECT id, email, created_at FROM auth.users ORDER BY created_at DESC LIMIT 5;

-- 2. Check what's in public.users table
SELECT 'Current public.users:' as info;
SELECT id, email, role, created_at FROM public.users ORDER BY created_at DESC LIMIT 5;

-- 3. Drop existing triggers to recreate them properly
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_email_confirmed ON auth.users;

-- 4. Grant necessary permissions for triggers to work
-- The trigger function needs to be able to insert into public.users
GRANT USAGE ON SCHEMA public TO postgres;
GRANT ALL ON public.users TO postgres;
GRANT ALL ON public.role_permissions TO postgres;

-- Also grant to authenticated and service_role
GRANT USAGE ON SCHEMA public TO authenticated, service_role;
GRANT ALL ON public.users TO authenticated, service_role;
GRANT ALL ON public.role_permissions TO authenticated, service_role;

-- 5. Ensure RLS allows trigger inserts
-- Temporarily disable RLS to test
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- 6. Create a simplified trigger function that definitely works
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Simple logging
    RAISE NOTICE 'Trigger fired for user: %', NEW.email;
    
    -- Check if user already exists
    IF EXISTS (SELECT 1 FROM public.users WHERE id = NEW.id) THEN
        RAISE NOTICE 'User % already exists, skipping', NEW.email;
        RETURN NEW;
    END IF;
    
    -- Insert with minimal data to avoid any type issues
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
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        'student'::user_role,
        CASE 
            WHEN NEW.email LIKE '%@gmail.com' THEN 'google'
            ELSE 'email'
        END,
        true,
        false,
        CASE 
            WHEN NEW.email_confirmed_at IS NOT NULL THEN true
            WHEN NEW.email LIKE '%@gmail.com' THEN true
            ELSE false
        END,
        true,
        COALESCE(NEW.created_at, NOW()),
        NOW()
    );
    
    RAISE NOTICE 'Successfully created profile for user: %', NEW.email;
    RETURN NEW;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error creating profile for %: %', NEW.email, SQLERRM;
    -- Don't fail the auth.users insert
    RETURN NEW;
END;
$$;

-- 7. Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO postgres, authenticated, service_role;

-- 8. Create the trigger with proper permissions
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW 
    EXECUTE FUNCTION public.handle_new_user();

-- 9. Test the trigger by creating a test user (this will be cleaned up)
DO $$
DECLARE
    test_user_id UUID := gen_random_uuid();
BEGIN
    -- Insert a test user into auth.users to see if trigger fires
    INSERT INTO auth.users (
        id,
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        created_at,
        updated_at,
        confirmation_token,
        recovery_token
    ) VALUES (
        test_user_id,
        '00000000-0000-0000-0000-000000000000',
        'test-trigger@example.com',
        'test',
        NOW(),
        NOW(),
        NOW(),
        '',
        ''
    );
    
    -- Check if the trigger created a profile
    IF EXISTS (SELECT 1 FROM public.users WHERE id = test_user_id) THEN
        RAISE NOTICE 'SUCCESS: Trigger is working! Profile created for test user.';
        
        -- Clean up test user
        DELETE FROM public.users WHERE id = test_user_id;
        DELETE FROM auth.users WHERE id = test_user_id;
        
    ELSE
        RAISE NOTICE 'FAILED: Trigger did not create profile for test user.';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error testing trigger: %', SQLERRM;
END $$;

-- 10. Create profiles for existing auth.users that don't have them
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
)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'first_name', ''),
    COALESCE(au.raw_user_meta_data->>'last_name', ''),
    'student'::user_role,
    CASE 
        WHEN au.email LIKE '%@gmail.com' THEN 'google'
        ELSE 'email'
    END,
    true,
    false,
    CASE 
        WHEN au.email_confirmed_at IS NOT NULL THEN true
        WHEN au.email LIKE '%@gmail.com' THEN true
        ELSE false
    END,
    true,
    au.created_at,
    NOW()
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL;

-- 11. Re-enable RLS with proper policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Service role can do everything" ON public.users;
DROP POLICY IF EXISTS "Trigger can insert users" ON public.users;

-- Create policies that allow triggers to work
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Service role can do everything" ON public.users
    FOR ALL USING (auth.role() = 'service_role');

-- This is crucial - allow inserts without user context (for triggers)
CREATE POLICY "Allow trigger inserts" ON public.users
    FOR INSERT WITH CHECK (true);

-- 12. Final check
SELECT 'Trigger fix completed!' as status;
SELECT 'Auth users count:' as info, COUNT(*) as count FROM auth.users;
SELECT 'Public users count:' as info, COUNT(*) as count FROM public.users;

-- Show any users that still don't have profiles
SELECT 'Users without profiles:' as info;
SELECT au.email 
FROM auth.users au 
LEFT JOIN public.users pu ON au.id = pu.id 
WHERE pu.id IS NULL;
