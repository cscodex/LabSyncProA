-- Safe User Creation Fix for LabSyncPro
-- This version checks for column existence before using them

-- 1. Add the missing OAuth columns if they don't exist
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'email',
ADD COLUMN IF NOT EXISTS provider_id TEXT,
ADD COLUMN IF NOT EXISTS registration_completed BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS profile_completed BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false;

-- 2. Create a simple trigger function that works with basic auth.users columns
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  -- Create user profile when a new user signs up
  -- Using only guaranteed columns: id, email, created_at, email_confirmed_at
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
    '', -- Will be updated later via profile completion
    '', -- Will be updated later via profile completion
    'student', -- Default role
    'email', -- Default to email auth
    false, -- Will be set to true when profile is completed
    false, -- Will be set to true when profile is completed
    CASE 
      WHEN NEW.email_confirmed_at IS NOT NULL THEN true
      ELSE false 
    END,
    true, -- is_active
    NEW.created_at,
    NOW()
  );
  
  RETURN NEW;
END;
$$;

-- 3. Drop existing trigger if it exists and create new one
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. Create trigger for email confirmation updates
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
  END IF;
  
  RETURN NEW;
END;
$$;

-- 5. Create trigger for email confirmation
DROP TRIGGER IF EXISTS on_auth_user_email_confirmed ON auth.users;
CREATE TRIGGER on_auth_user_email_confirmed
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_user_email_confirmed();

-- 6. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_auth_provider ON public.users(auth_provider);
CREATE INDEX IF NOT EXISTS idx_users_provider_id ON public.users(provider_id) WHERE provider_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_registration_completed ON public.users(registration_completed);
CREATE INDEX IF NOT EXISTS idx_users_email_verified ON public.users(email_verified);

-- 7. Fix any existing auth.users that don't have profiles (simple version)
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
  '', -- Empty first name - will be filled via profile completion
  '', -- Empty last name - will be filled via profile completion
  'student', -- Default role
  'email', -- Default auth provider
  false, -- Not completed
  false, -- Profile not completed
  CASE 
    WHEN au.email_confirmed_at IS NOT NULL THEN true
    ELSE false 
  END,
  true, -- Active
  au.created_at,
  NOW()
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL;

-- 8. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.users TO authenticated;
GRANT ALL ON public.users TO service_role;

-- 9. Enable RLS and create policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Service role can do everything" ON public.users;

-- Create new policies
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

-- Allow service role to do everything
CREATE POLICY "Service role can do everything" ON public.users
  FOR ALL USING (auth.role() = 'service_role');

-- 10. Create a function to manually update OAuth users after they sign up
CREATE OR REPLACE FUNCTION public.update_oauth_user_profile(
  user_id UUID,
  first_name TEXT DEFAULT '',
  last_name TEXT DEFAULT '',
  provider TEXT DEFAULT 'google',
  provider_user_id TEXT DEFAULT NULL,
  avatar_url TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.users 
  SET 
    first_name = COALESCE(update_oauth_user_profile.first_name, public.users.first_name),
    last_name = COALESCE(update_oauth_user_profile.last_name, public.users.last_name),
    auth_provider = update_oauth_user_profile.provider,
    provider_id = update_oauth_user_profile.provider_user_id,
    profile_image_url = update_oauth_user_profile.avatar_url,
    registration_completed = true,
    email_verified = true,
    updated_at = NOW()
  WHERE id = user_id;
  
  RETURN FOUND;
END;
$$;

COMMENT ON FUNCTION public.handle_new_user() IS 'Creates basic user profile when new user signs up';
COMMENT ON FUNCTION public.handle_user_email_confirmed() IS 'Updates email verification status when user confirms email';
COMMENT ON FUNCTION public.update_oauth_user_profile(UUID, TEXT, TEXT, TEXT, TEXT, TEXT) IS 'Updates user profile with OAuth provider information';
