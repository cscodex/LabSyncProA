-- LabSyncPro Supabase Auth Configuration
-- Run these SQL commands in your Supabase SQL Editor to configure authentication settings

-- 1. Enable Row Level Security on auth tables (if not already enabled)
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- 2. Create a function to check if email is verified
CREATE OR REPLACE FUNCTION auth.email_verified()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT COALESCE(auth.jwt() ->> 'email_confirmed_at' IS NOT NULL, false);
$$;

-- 3. Create a policy to only allow verified users to access protected resources
-- This will be applied to your users table
CREATE POLICY "Users must have verified email" ON public.users
  FOR ALL USING (
    auth.uid() = id AND 
    (auth.jwt() ->> 'email_confirmed_at') IS NOT NULL
  );

-- 4. Create a function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  -- Only create user profile if email is confirmed
  IF NEW.email_confirmed_at IS NOT NULL THEN
    INSERT INTO public.users (
      id,
      email,
      first_name,
      last_name,
      role,
      profile_image_url,
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
      COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
      COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
      NEW.raw_user_meta_data->>'avatar_url',
      NOW(),
      NOW()
    );
  END IF;
  
  RETURN NEW;
END;
$$;

-- 5. Create trigger for new user registration
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. Create a function to prevent unverified users from signing in
CREATE OR REPLACE FUNCTION auth.check_email_verified()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if this is a sign-in attempt (last_sign_in_at is being updated)
  IF OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at AND 
     NEW.email_confirmed_at IS NULL THEN
    RAISE EXCEPTION 'Email verification required. Please check your email and click the verification link.'
      USING ERRCODE = 'email_not_confirmed';
  END IF;
  
  RETURN NEW;
END;
$$;

-- 7. Create trigger to check email verification on sign-in
DROP TRIGGER IF EXISTS check_email_verified_on_signin ON auth.users;
CREATE TRIGGER check_email_verified_on_signin
  BEFORE UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION auth.check_email_verified();

-- 8. Update existing users to require email verification (optional)
-- Uncomment the following lines if you want to require existing users to verify their email
-- UPDATE auth.users 
-- SET email_confirmed_at = NULL 
-- WHERE email_confirmed_at IS NULL;

-- 9. Create a view for verified users only
CREATE OR REPLACE VIEW public.verified_users AS
SELECT 
  u.*,
  au.email_confirmed_at,
  au.last_sign_in_at
FROM public.users u
JOIN auth.users au ON u.id = au.id
WHERE au.email_confirmed_at IS NOT NULL;

-- 10. Grant permissions
GRANT SELECT ON public.verified_users TO authenticated;
GRANT SELECT ON public.verified_users TO anon;

-- 11. Create a function to resend verification email
CREATE OR REPLACE FUNCTION public.resend_verification_email(user_email text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_record auth.users%ROWTYPE;
BEGIN
  -- Find the user
  SELECT * INTO user_record
  FROM auth.users
  WHERE email = user_email;
  
  IF NOT FOUND THEN
    RETURN json_build_object('error', 'User not found');
  END IF;
  
  IF user_record.email_confirmed_at IS NOT NULL THEN
    RETURN json_build_object('error', 'Email already verified');
  END IF;
  
  -- Note: Actual email sending would be handled by Supabase Auth
  -- This function is for reference and logging
  INSERT INTO public.email_logs (
    user_id,
    email_type,
    recipient_email,
    sent_at
  ) VALUES (
    user_record.id,
    'verification_resend',
    user_email,
    NOW()
  );
  
  RETURN json_build_object('success', 'Verification email queued for resend');
END;
$$;

-- 12. Create email logs table for tracking
CREATE TABLE IF NOT EXISTS public.email_logs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  email_type text NOT NULL,
  recipient_email text NOT NULL,
  sent_at timestamp with time zone DEFAULT NOW(),
  delivered_at timestamp with time zone,
  opened_at timestamp with time zone,
  clicked_at timestamp with time zone
);

-- Enable RLS on email logs
ALTER TABLE public.email_logs ENABLE ROW LEVEL SECURITY;

-- Create policy for email logs
CREATE POLICY "Users can view their own email logs" ON public.email_logs
  FOR SELECT USING (auth.uid() = user_id);

-- Grant permissions
GRANT SELECT ON public.email_logs TO authenticated;
GRANT INSERT ON public.email_logs TO service_role;

-- 13. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email_confirmed ON auth.users(email_confirmed_at);
CREATE INDEX IF NOT EXISTS idx_email_logs_user_id ON public.email_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_email_logs_sent_at ON public.email_logs(sent_at);

COMMENT ON TABLE public.email_logs IS 'Tracks email delivery and engagement for audit purposes';
COMMENT ON FUNCTION public.handle_new_user() IS 'Creates user profile only after email verification';
COMMENT ON FUNCTION auth.check_email_verified() IS 'Prevents sign-in for unverified users';
COMMENT ON VIEW public.verified_users IS 'View of users with verified email addresses only';
