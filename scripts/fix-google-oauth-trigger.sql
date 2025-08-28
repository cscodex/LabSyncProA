-- Fix Google OAuth Trigger Issues
-- This script ensures Google OAuth users get profiles created

-- 1. Check current state
SELECT 'Current auth.users (recent):' as info;
SELECT id, email, created_at, 
       raw_user_meta_data->>'provider' as provider,
       raw_user_meta_data->>'first_name' as first_name,
       raw_user_meta_data->>'picture' as picture
FROM auth.users 
ORDER BY created_at DESC LIMIT 5;

SELECT 'Current public.users (recent):' as info;
SELECT id, email, role, auth_provider, created_at 
FROM public.users 
ORDER BY created_at DESC LIMIT 5;

-- 2. Drop and recreate the trigger function with better Google OAuth handling
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_exists BOOLEAN := FALSE;
    provider_name TEXT := 'email';
    first_name_val TEXT := '';
    last_name_val TEXT := '';
    profile_image TEXT := NULL;
BEGIN
    -- Enhanced logging
    RAISE NOTICE 'TRIGGER FIRED: handle_new_user for email: %', NEW.email;
    RAISE NOTICE 'User metadata: %', NEW.raw_user_meta_data;
    RAISE NOTICE 'App metadata: %', NEW.app_metadata;
    
    -- Check if user already exists
    SELECT EXISTS(SELECT 1 FROM public.users WHERE id = NEW.id) INTO user_exists;
    
    IF user_exists THEN
        RAISE NOTICE 'User % already exists in public.users, skipping', NEW.email;
        RETURN NEW;
    END IF;
    
    -- Determine provider and extract metadata
    IF NEW.raw_user_meta_data IS NOT NULL THEN
        -- Check for Google OAuth
        IF NEW.raw_user_meta_data->>'iss' = 'https://accounts.google.com' 
           OR NEW.raw_user_meta_data->>'provider' = 'google'
           OR NEW.email LIKE '%@gmail.com' THEN
            provider_name := 'google';
            first_name_val := COALESCE(
                NEW.raw_user_meta_data->>'given_name',
                NEW.raw_user_meta_data->>'first_name',
                ''
            );
            last_name_val := COALESCE(
                NEW.raw_user_meta_data->>'family_name',
                NEW.raw_user_meta_data->>'last_name',
                ''
            );
            profile_image := NEW.raw_user_meta_data->>'picture';
        ELSE
            -- Regular email signup
            first_name_val := COALESCE(NEW.raw_user_meta_data->>'first_name', '');
            last_name_val := COALESCE(NEW.raw_user_meta_data->>'last_name', '');
        END IF;
    END IF;
    
    RAISE NOTICE 'Determined provider: %, first_name: %, last_name: %', 
                 provider_name, first_name_val, last_name_val;
    
    -- Insert user profile
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
            registration_completed,
            profile_completed,
            email_verified,
            is_active,
            created_at,
            updated_at
        ) VALUES (
            NEW.id,
            NEW.email,
            first_name_val,
            last_name_val,
            'student'::user_role,
            provider_name,
            NEW.raw_user_meta_data->>'sub',
            profile_image,
            CASE WHEN provider_name = 'google' THEN true ELSE false END,
            false,
            CASE 
                WHEN NEW.email_confirmed_at IS NOT NULL THEN true
                WHEN provider_name = 'google' THEN true
                ELSE false
            END,
            true,
            COALESCE(NEW.created_at, NOW()),
            NOW()
        );
        
        RAISE NOTICE 'SUCCESS: Created profile for user % with provider %', NEW.email, provider_name;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: Failed to create profile for %: %', NEW.email, SQLERRM;
        -- Don't fail the auth.users insert
    END;
    
    RETURN NEW;
END;
$$;

-- 3. Grant permissions
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO postgres, authenticated, service_role;

-- 4. Recreate the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW 
    EXECUTE FUNCTION public.handle_new_user();

-- 5. Also create an UPDATE trigger for when OAuth data is added later
CREATE OR REPLACE FUNCTION public.handle_user_updated()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if this is a new OAuth user (metadata was added)
    IF OLD.raw_user_meta_data IS NULL AND NEW.raw_user_meta_data IS NOT NULL THEN
        RAISE NOTICE 'OAuth metadata added for user: %', NEW.email;
        
        -- Check if they don't have a profile yet
        IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = NEW.id) THEN
            RAISE NOTICE 'Creating delayed profile for OAuth user: %', NEW.email;
            -- Call the same function as the insert trigger
            PERFORM public.handle_new_user_insert(NEW);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Helper function for the update trigger
CREATE OR REPLACE FUNCTION public.handle_new_user_insert(user_record auth.users)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    provider_name TEXT := 'email';
    first_name_val TEXT := '';
    last_name_val TEXT := '';
    profile_image TEXT := NULL;
BEGIN
    -- Same logic as the main trigger
    IF user_record.raw_user_meta_data IS NOT NULL THEN
        IF user_record.raw_user_meta_data->>'iss' = 'https://accounts.google.com' 
           OR user_record.raw_user_meta_data->>'provider' = 'google'
           OR user_record.email LIKE '%@gmail.com' THEN
            provider_name := 'google';
            first_name_val := COALESCE(
                user_record.raw_user_meta_data->>'given_name',
                user_record.raw_user_meta_data->>'first_name',
                ''
            );
            last_name_val := COALESCE(
                user_record.raw_user_meta_data->>'family_name',
                user_record.raw_user_meta_data->>'last_name',
                ''
            );
            profile_image := user_record.raw_user_meta_data->>'picture';
        END IF;
    END IF;
    
    INSERT INTO public.users (
        id, email, first_name, last_name, role, auth_provider, provider_id,
        profile_image_url, registration_completed, profile_completed, 
        email_verified, is_active, created_at, updated_at
    ) VALUES (
        user_record.id, user_record.email, first_name_val, last_name_val,
        'student'::user_role, provider_name, user_record.raw_user_meta_data->>'sub',
        profile_image, provider_name = 'google', false,
        CASE WHEN user_record.email_confirmed_at IS NOT NULL OR provider_name = 'google' THEN true ELSE false END,
        true, COALESCE(user_record.created_at, NOW()), NOW()
    );
END;
$$;

-- Create update trigger
DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;
CREATE TRIGGER on_auth_user_updated
    AFTER UPDATE ON auth.users
    FOR EACH ROW 
    EXECUTE FUNCTION public.handle_user_updated();

-- 6. Fix any existing Google users without profiles
INSERT INTO public.users (
    id, email, first_name, last_name, role, auth_provider, provider_id,
    profile_image_url, registration_completed, profile_completed, 
    email_verified, is_active, created_at, updated_at
)
SELECT 
    au.id,
    au.email,
    COALESCE(
        au.raw_user_meta_data->>'given_name',
        au.raw_user_meta_data->>'first_name',
        ''
    ),
    COALESCE(
        au.raw_user_meta_data->>'family_name',
        au.raw_user_meta_data->>'last_name',
        ''
    ),
    'student'::user_role,
    CASE 
        WHEN au.raw_user_meta_data->>'iss' = 'https://accounts.google.com' 
             OR au.raw_user_meta_data->>'provider' = 'google'
             OR au.email LIKE '%@gmail.com' THEN 'google'
        ELSE 'email'
    END,
    au.raw_user_meta_data->>'sub',
    au.raw_user_meta_data->>'picture',
    CASE 
        WHEN au.raw_user_meta_data->>'iss' = 'https://accounts.google.com' 
             OR au.raw_user_meta_data->>'provider' = 'google'
             OR au.email LIKE '%@gmail.com' THEN true
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

-- 7. Test the trigger with logging
SELECT 'Google OAuth trigger fix completed!' as status;
SELECT 'Check the logs when you sign in with Google to see trigger messages' as note;

-- Show current state
SELECT 'Final state - auth.users:' as info, COUNT(*) as count FROM auth.users;
SELECT 'Final state - public.users:' as info, COUNT(*) as count FROM public.users;
