-- Simple Trigger Fix for LabSyncPro
-- This script fixes just the trigger issues without complex role system

-- 1. Add OAuth columns if they don't exist
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'email',
ADD COLUMN IF NOT EXISTS provider_id TEXT,
ADD COLUMN IF NOT EXISTS registration_completed BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS profile_completed BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false;

-- 2. Create a simple trigger function that works with existing schema
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    user_exists BOOLEAN := FALSE;
BEGIN
    -- Log the trigger execution
    RAISE LOG 'handle_new_user trigger fired for user: %', NEW.email;
    
    -- Check if user already exists in public.users
    SELECT EXISTS(SELECT 1 FROM public.users WHERE id = NEW.id) INTO user_exists;
    
    IF user_exists THEN
        RAISE LOG 'User % already exists in public.users, skipping insert', NEW.email;
        RETURN NEW;
    END IF;
    
    -- Insert new user profile with simple role handling
    BEGIN
        INSERT INTO public.users (
            id,
            email,
            first_name,
            last_name,
            role,
            auth_provider,
            provider_id,
            profile_image_url,
            phone_number,
            department,
            employee_id,
            student_id,
            registration_completed,
            profile_completed,
            email_verified,
            is_active,
            created_at,
            updated_at
        )
        VALUES (
            NEW.id,
            NEW.email,
            COALESCE(
                NEW.raw_user_meta_data->>'first_name',
                NEW.raw_user_meta_data->>'given_name',
                ''
            ),
            COALESCE(
                NEW.raw_user_meta_data->>'last_name',
                NEW.raw_user_meta_data->>'family_name',
                ''
            ),
            -- Simple role assignment - keep as text for now
            COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
            CASE 
                WHEN NEW.raw_user_meta_data->>'provider' IS NOT NULL THEN NEW.raw_user_meta_data->>'provider'
                WHEN NEW.email LIKE '%@gmail.com' THEN 'google'
                ELSE 'email'
            END,
            NEW.raw_user_meta_data->>'sub',
            COALESCE(
                NEW.raw_user_meta_data->>'avatar_url',
                NEW.raw_user_meta_data->>'picture'
            ),
            NEW.raw_user_meta_data->>'phone_number',
            NEW.raw_user_meta_data->>'department',
            NEW.raw_user_meta_data->>'employee_id',
            NEW.raw_user_meta_data->>'student_id',
            CASE 
                WHEN NEW.raw_user_meta_data->>'provider' IS NOT NULL THEN true
                WHEN NEW.email LIKE '%@gmail.com' THEN true
                ELSE false
            END,
            false, -- profile_completed always starts as false
            CASE 
                WHEN NEW.email_confirmed_at IS NOT NULL THEN true
                WHEN NEW.email LIKE '%@gmail.com' THEN true
                ELSE false
            END,
            true, -- is_active
            COALESCE(NEW.created_at, NOW()),
            NOW()
        );
        
        RAISE LOG 'Successfully created user profile for: %', NEW.email;
        
    EXCEPTION WHEN OTHERS THEN
        -- Log the error but don't fail the auth.users insert
        RAISE LOG 'Failed to create user profile for %: %', NEW.email, SQLERRM;
        
        -- Try a minimal insert as fallback
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
                is_active,
                created_at,
                updated_at
            )
            VALUES (
                NEW.id,
                NEW.email,
                '',
                '',
                'student',
                'email',
                false,
                false,
                NEW.email_confirmed_at IS NOT NULL,
                true,
                COALESCE(NEW.created_at, NOW()),
                NOW()
            );
            
            RAISE LOG 'Created minimal user profile for: %', NEW.email;
            
        EXCEPTION WHEN OTHERS THEN
            RAISE LOG 'Even minimal user profile creation failed for %: %', NEW.email, SQLERRM;
        END;
    END;
    
    RETURN NEW;
END;
$$;

-- 3. Create email confirmation trigger function
CREATE OR REPLACE FUNCTION public.handle_user_email_confirmed()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    -- Update email_verified when email is confirmed
    IF OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL THEN
        UPDATE public.users 
        SET 
            email_verified = true,
            updated_at = NOW()
        WHERE id = NEW.id;
        
        RAISE LOG 'Email verified for user: %', NEW.email;
    END IF;
    
    RETURN NEW;
END;
$$;

-- 4. Drop existing triggers and recreate them
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_email_confirmed ON auth.users;
DROP TRIGGER IF EXISTS test_trigger ON auth.users;

-- Create the triggers
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER on_auth_user_email_confirmed
    AFTER UPDATE ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_user_email_confirmed();

-- 5. Fix any existing auth.users that don't have profiles
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
    COALESCE(
        au.raw_user_meta_data->>'first_name',
        au.raw_user_meta_data->>'given_name',
        ''
    ),
    COALESCE(
        au.raw_user_meta_data->>'last_name',
        au.raw_user_meta_data->>'family_name',
        ''
    ),
    COALESCE(au.raw_user_meta_data->>'role', 'student'),
    CASE 
        WHEN au.raw_user_meta_data->>'provider' IS NOT NULL THEN au.raw_user_meta_data->>'provider'
        WHEN au.email LIKE '%@gmail.com' THEN 'google'
        ELSE 'email'
    END,
    CASE 
        WHEN au.raw_user_meta_data->>'provider' IS NOT NULL THEN true
        WHEN au.email LIKE '%@gmail.com' THEN true
        ELSE false
    END,
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
WHERE pu.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- 6. Set up basic RLS policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Service role can do everything" ON public.users;
DROP POLICY IF EXISTS "Trigger can insert users" ON public.users;

-- Create basic policies
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Service role can do everything" ON public.users
    FOR ALL USING (auth.role() = 'service_role');

-- Allow triggers to insert (this is crucial!)
CREATE POLICY "Trigger can insert users" ON public.users
    FOR INSERT WITH CHECK (true);

-- 7. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated, anon, service_role;
GRANT ALL ON public.users TO authenticated, anon, service_role;

-- 8. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_auth_provider ON public.users(auth_provider);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_registration_completed ON public.users(registration_completed);
CREATE INDEX IF NOT EXISTS idx_users_email_verified ON public.users(email_verified);

-- 9. Test the trigger system
DO $$
BEGIN
    RAISE NOTICE 'Simple trigger system setup completed successfully!';
    RAISE NOTICE 'Test by creating a new user via Google OAuth';
    RAISE NOTICE 'Check the logs for trigger execution messages';
END $$;

COMMENT ON FUNCTION public.handle_new_user() IS 'Creates user profile when new user signs up - simple version without enum roles';
COMMENT ON FUNCTION public.handle_user_email_confirmed() IS 'Updates email verification status when user confirms email';

SELECT 'Simple trigger fix completed successfully!' as status;
