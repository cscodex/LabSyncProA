-- Safe Role System Fix for LabSyncPro
-- This script works around dependency issues by keeping the existing role column

-- 1. First, drop all policies that might depend on the role column
DROP POLICY IF EXISTS "Users can view their own profile and public profiles" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Service role can do everything" ON public.users;
DROP POLICY IF EXISTS "Trigger can insert users" ON public.users;
DROP POLICY IF EXISTS "Users can view based on role" ON public.users;
DROP POLICY IF EXISTS "Users can update based on role" ON public.users;

-- 2. Create enum for user roles if it doesn't exist
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM (
        'super_admin',
        'admin', 
        'lab_manager',
        'instructor',
        'lab_staff',
        'student'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. Instead of dropping the role column, let's rename it and create a new one
-- First, check what type the current role column is
DO $$
DECLARE
    role_type TEXT;
BEGIN
    SELECT data_type INTO role_type
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'users' 
    AND column_name = 'role';
    
    RAISE NOTICE 'Current role column type: %', role_type;
    
    -- If it's already user_role enum, we're good
    IF role_type = 'USER-DEFINED' THEN
        RAISE NOTICE 'Role column is already enum type, skipping conversion';
    ELSE
        -- Rename the old role column
        ALTER TABLE public.users RENAME COLUMN role TO role_old;
        
        -- Add new role column with enum type
        ALTER TABLE public.users ADD COLUMN role user_role DEFAULT 'student'::user_role;
        
        -- Convert values from old column to new column
        UPDATE public.users 
        SET role = CASE 
            WHEN role_old = 'super_admin' THEN 'super_admin'::user_role
            WHEN role_old = 'admin' THEN 'admin'::user_role
            WHEN role_old = 'lab_manager' THEN 'lab_manager'::user_role
            WHEN role_old = 'instructor' THEN 'instructor'::user_role
            WHEN role_old = 'lab_staff' THEN 'lab_staff'::user_role
            WHEN role_old = 'student' THEN 'student'::user_role
            ELSE 'student'::user_role
        END;
        
        -- Drop the old column (this might still fail if there are dependencies)
        BEGIN
            ALTER TABLE public.users DROP COLUMN role_old;
            RAISE NOTICE 'Successfully dropped old role column';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not drop old role column: %. Keeping both columns for now.', SQLERRM;
        END;
    END IF;
END $$;

-- 4. Add OAuth columns if they don't exist
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'email',
ADD COLUMN IF NOT EXISTS provider_id TEXT,
ADD COLUMN IF NOT EXISTS registration_completed BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS profile_completed BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false;

-- 5. Create role permissions table
CREATE TABLE IF NOT EXISTS public.role_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role user_role NOT NULL,
    permission TEXT NOT NULL,
    resource TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(role, permission, resource)
);

-- 6. Insert role permissions
INSERT INTO public.role_permissions (role, permission, resource) VALUES
-- Super Admin - can do everything
('super_admin', 'create', '*'),
('super_admin', 'read', '*'),
('super_admin', 'update', '*'),
('super_admin', 'delete', '*'),
('super_admin', 'manage', '*'),

-- Admin - can manage most things except system settings
('admin', 'create', 'users'),
('admin', 'read', 'users'),
('admin', 'update', 'users'),
('admin', 'delete', 'users'),
('admin', 'create', 'labs'),
('admin', 'read', 'labs'),
('admin', 'update', 'labs'),
('admin', 'delete', 'labs'),
('admin', 'create', 'equipment'),
('admin', 'read', 'equipment'),
('admin', 'update', 'equipment'),
('admin', 'delete', 'equipment'),
('admin', 'read', 'reports'),
('admin', 'create', 'reports'),

-- Lab Manager - can manage their assigned labs
('lab_manager', 'read', 'users'),
('lab_manager', 'update', 'users'),
('lab_manager', 'create', 'equipment'),
('lab_manager', 'read', 'equipment'),
('lab_manager', 'update', 'equipment'),
('lab_manager', 'delete', 'equipment'),
('lab_manager', 'create', 'bookings'),
('lab_manager', 'read', 'bookings'),
('lab_manager', 'update', 'bookings'),
('lab_manager', 'delete', 'bookings'),
('lab_manager', 'create', 'consumables'),
('lab_manager', 'read', 'consumables'),
('lab_manager', 'update', 'consumables'),
('lab_manager', 'read', 'reports'),
('lab_manager', 'create', 'reports'),

-- Instructor - can manage their classes and bookings
('instructor', 'read', 'users'),
('instructor', 'read', 'equipment'),
('instructor', 'create', 'bookings'),
('instructor', 'read', 'bookings'),
('instructor', 'update', 'bookings'),
('instructor', 'delete', 'bookings'),
('instructor', 'read', 'consumables'),
('instructor', 'read', 'reports'),

-- Lab Staff - can assist with equipment and bookings
('lab_staff', 'read', 'users'),
('lab_staff', 'read', 'equipment'),
('lab_staff', 'update', 'equipment'),
('lab_staff', 'read', 'bookings'),
('lab_staff', 'update', 'bookings'),
('lab_staff', 'read', 'consumables'),
('lab_staff', 'update', 'consumables'),

-- Student - can view and book equipment
('student', 'read', 'equipment'),
('student', 'create', 'bookings'),
('student', 'read', 'bookings'),
('student', 'update', 'bookings'),
('student', 'read', 'consumables')

ON CONFLICT (role, permission, resource) DO NOTHING;

-- 7. Create function to check user permissions
CREATE OR REPLACE FUNCTION public.user_has_permission(
    user_id UUID,
    permission_name TEXT,
    resource_name TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_role_val user_role;
    has_permission BOOLEAN := FALSE;
BEGIN
    -- Get user role
    SELECT role INTO user_role_val
    FROM public.users
    WHERE id = user_id;
    
    IF user_role_val IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Check if user has specific permission
    SELECT EXISTS(
        SELECT 1 FROM public.role_permissions
        WHERE role = user_role_val
        AND permission = permission_name
        AND (resource = resource_name OR resource = '*')
    ) INTO has_permission;
    
    RETURN has_permission;
END;
$$;

-- 8. Create a safe trigger function that handles role casting properly
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    user_exists BOOLEAN := FALSE;
    user_role_val user_role := 'student';
BEGIN
    -- Log the trigger execution
    RAISE LOG 'handle_new_user trigger fired for user: %', NEW.email;
    
    -- Check if user already exists in public.users
    SELECT EXISTS(SELECT 1 FROM public.users WHERE id = NEW.id) INTO user_exists;
    
    IF user_exists THEN
        RAISE LOG 'User % already exists in public.users, skipping insert', NEW.email;
        RETURN NEW;
    END IF;
    
    -- Determine user role with proper casting and error handling
    BEGIN
        user_role_val := COALESCE(NEW.raw_user_meta_data->>'role', 'student')::user_role;
    EXCEPTION WHEN OTHERS THEN
        user_role_val := 'student'::user_role;
    END;
    
    -- Insert new user profile with comprehensive error handling
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
            user_role_val,
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
                'student'::user_role,
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

-- 9. Recreate the triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 10. Recreate RLS policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Service role can do everything" ON public.users
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Trigger can insert users" ON public.users
    FOR INSERT WITH CHECK (true);

-- 11. Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.role_permissions TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_has_permission(UUID, TEXT, TEXT) TO authenticated;

-- 12. Create test users with proper role casting
INSERT INTO public.users (
    id, email, first_name, last_name, role, auth_provider,
    registration_completed, profile_completed, email_verified, is_active
) VALUES 
(gen_random_uuid(), 'admin@labsyncpro.com', 'System', 'Administrator', 'super_admin'::user_role, 'email', true, true, true, true),
(gen_random_uuid(), 'labmanager@labsyncpro.com', 'Lab', 'Manager', 'lab_manager'::user_role, 'email', true, true, true, true),
(gen_random_uuid(), 'instructor@labsyncpro.com', 'John', 'Instructor', 'instructor'::user_role, 'email', true, true, true, true),
(gen_random_uuid(), 'staff@labsyncpro.com', 'Lab', 'Staff', 'lab_staff'::user_role, 'email', true, true, true, true)
ON CONFLICT (email) DO NOTHING;

SELECT 'Safe role system setup completed successfully!' as status;
