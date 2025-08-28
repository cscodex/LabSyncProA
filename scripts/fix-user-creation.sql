-- Fix User Creation Issues for LabSyncPro
-- Run this SQL in your Supabase SQL Editor

-- 1. First, add the missing OAuth columns if they don't exist
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'email',
ADD COLUMN IF NOT EXISTS provider_id TEXT,
ADD COLUMN IF NOT EXISTS registration_completed BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS profile_completed BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false;

-- 2. Create or replace the trigger function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  -- Create user profile when a new user signs up
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
    COALESCE(NEW.raw_user_meta_data->>'first_name', NEW.raw_user_meta_data->>'given_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', NEW.raw_user_meta_data->>'family_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
    COALESCE(NEW.app_metadata->>'provider', 'email'),
    NEW.raw_user_meta_data->>'provider_id',
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture'),
    NEW.raw_user_meta_data->>'phone_number',
    NEW.raw_user_meta_data->>'department',
    NEW.raw_user_meta_data->>'employee_id',
    NEW.raw_user_meta_data->>'student_id',
    CASE
      WHEN COALESCE(NEW.app_metadata->>'provider', 'email') != 'email' THEN true
      ELSE false
    END,
    false, -- profile_completed always starts as false
    CASE
      WHEN COALESCE(NEW.app_metadata->>'provider', 'email') IN ('google', 'apple') THEN true
      WHEN NEW.email_confirmed_at IS NOT NULL THEN true
      ELSE false
    END,
    true, -- is_active
    NOW(),
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

-- 7. Fix any existing auth.users that don't have profiles
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
)
SELECT 
  au.id,
  au.email,
  COALESCE(au.raw_user_meta_data->>'first_name', au.raw_user_meta_data->>'given_name', ''),
  COALESCE(au.raw_user_meta_data->>'last_name', au.raw_user_meta_data->>'family_name', ''),
  COALESCE(au.raw_user_meta_data->>'role', 'student'),
  COALESCE(au.app_metadata->>'provider', 'email'),
  au.raw_user_meta_data->>'provider_id',
  COALESCE(au.raw_user_meta_data->>'avatar_url', au.raw_user_meta_data->>'picture'),
  CASE
    WHEN COALESCE(au.app_metadata->>'provider', 'email') != 'email' THEN true
    ELSE false
  END,
  false,
  CASE
    WHEN COALESCE(au.app_metadata->>'provider', 'email') IN ('google', 'apple') THEN true
    WHEN au.email_confirmed_at IS NOT NULL THEN true
    ELSE false
  END,
  true,
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

-- Create new policies
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

-- Allow service role to do everything
CREATE POLICY "Service role can do everything" ON public.users
  FOR ALL USING (auth.role() = 'service_role');

COMMENT ON FUNCTION public.handle_new_user() IS 'Creates user profile when new user signs up via any method';
COMMENT ON FUNCTION public.handle_user_email_confirmed() IS 'Updates email verification status when user confirms email';
