-- Production Database Update Script for LabSyncPro
-- Run this in your Supabase SQL Editor to ensure database matches application

-- ========================================
-- PART 1: VERIFY CURRENT STATE
-- ========================================

-- Check current users table structure
SELECT 'CURRENT USERS TABLE STRUCTURE:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'users'
ORDER BY ordinal_position;

-- Check current data
SELECT 'CURRENT DATA STATE:' as info;
SELECT 'auth.users count:' as table_name, COUNT(*) as count FROM auth.users;
SELECT 'public.users count:' as table_name, COUNT(*) as count FROM public.users;

-- Show users without profiles
SELECT 'USERS WITHOUT PROFILES:' as info;
SELECT 
    au.id,
    au.email,
    au.created_at,
    au.raw_user_meta_data->>'provider' as provider
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL;

-- ========================================
-- PART 2: ENSURE REQUIRED COLUMNS EXIST
-- ========================================

-- Add is_active column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.users ADD COLUMN is_active BOOLEAN DEFAULT true NOT NULL;
        RAISE NOTICE 'Added is_active column';
    ELSE
        RAISE NOTICE 'is_active column already exists';
    END IF;
END $$;

-- Add auth_provider column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'auth_provider'
    ) THEN
        ALTER TABLE public.users ADD COLUMN auth_provider TEXT DEFAULT 'email' NOT NULL;
        RAISE NOTICE 'Added auth_provider column';
    ELSE
        RAISE NOTICE 'auth_provider column already exists';
    END IF;
END $$;

-- Add registration_completed column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'registration_completed'
    ) THEN
        ALTER TABLE public.users ADD COLUMN registration_completed BOOLEAN DEFAULT false NOT NULL;
        RAISE NOTICE 'Added registration_completed column';
    ELSE
        RAISE NOTICE 'registration_completed column already exists';
    END IF;
END $$;

-- Add profile_completed column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'profile_completed'
    ) THEN
        ALTER TABLE public.users ADD COLUMN profile_completed BOOLEAN DEFAULT false NOT NULL;
        RAISE NOTICE 'Added profile_completed column';
    ELSE
        RAISE NOTICE 'profile_completed column already exists';
    END IF;
END $$;

-- Add email_verified column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'email_verified'
    ) THEN
        ALTER TABLE public.users ADD COLUMN email_verified BOOLEAN DEFAULT false NOT NULL;
        RAISE NOTICE 'Added email_verified column';
    ELSE
        RAISE NOTICE 'email_verified column already exists';
    END IF;
END $$;

-- ========================================
-- PART 3: UPDATE EXISTING DATA
-- ========================================

-- Update existing users to have proper default values
UPDATE public.users 
SET 
    is_active = COALESCE(is_active, true),
    auth_provider = COALESCE(auth_provider, 
        CASE 
            WHEN email LIKE '%@gmail.com' THEN 'google'
            ELSE 'email'
        END
    ),
    registration_completed = COALESCE(registration_completed, true),
    profile_completed = COALESCE(profile_completed, 
        CASE 
            WHEN first_name IS NOT NULL AND first_name != '' 
            AND last_name IS NOT NULL AND last_name != '' 
            THEN true 
            ELSE false 
        END
    ),
    email_verified = COALESCE(email_verified, true),
    updated_at = NOW()
WHERE 
    is_active IS NULL 
    OR auth_provider IS NULL 
    OR registration_completed IS NULL 
    OR profile_completed IS NULL 
    OR email_verified IS NULL;

-- ========================================
-- PART 4: CREATE PROFILES FOR MISSING USERS
-- ========================================

-- Create profiles for auth.users that don't have public.users records
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

-- ========================================
-- PART 5: VERIFY FINAL STATE
-- ========================================

SELECT '=== FINAL VERIFICATION ===' as info;

-- Check updated table structure
SELECT 'UPDATED TABLE STRUCTURE:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'users'
AND column_name IN ('is_active', 'auth_provider', 'registration_completed', 'profile_completed', 'email_verified')
ORDER BY column_name;

-- Check final data counts
SELECT 'FINAL DATA COUNTS:' as info;
SELECT 'auth.users count:' as table_name, COUNT(*) as count FROM auth.users;
SELECT 'public.users count:' as table_name, COUNT(*) as count FROM public.users;

-- Check if any users still missing profiles
SELECT 'REMAINING USERS WITHOUT PROFILES:' as info;
SELECT COUNT(*) as missing_profiles_count
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL;

-- Show sample of updated users
SELECT 'SAMPLE UPDATED USERS:' as info;
SELECT 
    id,
    email,
    first_name,
    last_name,
    role,
    auth_provider,
    is_active,
    registration_completed,
    profile_completed,
    email_verified
FROM public.users 
ORDER BY created_at DESC 
LIMIT 5;

RAISE NOTICE '=== DATABASE UPDATE COMPLETE ===';
RAISE NOTICE 'All required columns have been added and data updated';
RAISE NOTICE 'Your database is now ready for the LabSyncPro application';
