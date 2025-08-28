-- Check Auth Schema Structure
-- Run this first to see what columns exist in auth.users

-- 1. Check what columns exist in auth.users table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'auth' 
AND table_name = 'users'
ORDER BY ordinal_position;

-- 2. Check if we have any existing users and their metadata structure
SELECT 
  id,
  email,
  created_at,
  email_confirmed_at,
  -- Check what metadata columns exist
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'raw_user_meta_data'
    ) THEN 'raw_user_meta_data exists'
    ELSE 'raw_user_meta_data does not exist'
  END as raw_user_meta_data_check,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'app_metadata'
    ) THEN 'app_metadata exists'
    ELSE 'app_metadata does not exist'
  END as app_metadata_check,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = 'user_metadata'
    ) THEN 'user_metadata exists'
    ELSE 'user_metadata does not exist'
  END as user_metadata_check
FROM auth.users 
LIMIT 5;
