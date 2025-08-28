-- Clean Schema Reset for LabSyncPro
-- WARNING: This will delete ALL data and recreate the schema
-- Only run this if you're okay with losing all existing data

-- 1. Drop all existing triggers first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_email_confirmed ON auth.users;
DROP TRIGGER IF EXISTS test_trigger ON auth.users;

-- 2. Drop all existing policies
DROP POLICY IF EXISTS "Users can view their own profile and public profiles" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Service role can do everything" ON public.users;
DROP POLICY IF EXISTS "Trigger can insert users" ON public.users;
DROP POLICY IF EXISTS "Users can view based on role" ON public.users;
DROP POLICY IF EXISTS "Users can update based on role" ON public.users;

-- 3. Drop all existing functions
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.handle_user_email_confirmed();
DROP FUNCTION IF EXISTS public.user_has_permission(UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.promote_user_role(UUID, user_role);
DROP FUNCTION IF EXISTS public.create_admin_user(TEXT, TEXT, TEXT, TEXT, user_role);
DROP FUNCTION IF EXISTS public.update_oauth_user_profile(UUID, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.test_trigger_function();
DROP FUNCTION IF EXISTS public.create_test_admin();

-- 4. Drop all existing tables (this will delete all data)
DROP TABLE IF EXISTS public.role_permissions CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- 5. Drop existing types
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS priority_level CASCADE;

-- 6. Create enum types
CREATE TYPE user_role AS ENUM (
    'super_admin',
    'admin', 
    'lab_manager',
    'instructor',
    'lab_staff',
    'student'
);

CREATE TYPE priority_level AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
);

-- 7. Create the users table with proper structure
CREATE TABLE public.users (
    id UUID PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    first_name TEXT DEFAULT '',
    last_name TEXT DEFAULT '',
    role user_role DEFAULT 'student'::user_role,
    department TEXT,
    phone_number TEXT,
    profile_image_url TEXT,
    employee_id TEXT,
    student_id TEXT,
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    archived_at TIMESTAMP WITH TIME ZONE,
    archived_by UUID,
    
    -- OAuth and registration fields
    auth_provider TEXT DEFAULT 'email',
    provider_id TEXT,
    registration_completed BOOLEAN DEFAULT false,
    profile_completed BOOLEAN DEFAULT false,
    email_verified BOOLEAN DEFAULT false,
    
    CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT users_archived_by_fkey FOREIGN KEY (archived_by) REFERENCES public.users(id)
);

-- 8. Create role permissions table
CREATE TABLE public.role_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role user_role NOT NULL,
    permission TEXT NOT NULL,
    resource TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(role, permission, resource)
);

-- 9. Insert role permissions
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
('student', 'read', 'consumables');

-- 10. Create function to check user permissions
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

-- 11. Create trigger function for new users
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
    
    -- Insert new user profile
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
    
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Log the error but don't fail the auth.users insert
    RAISE LOG 'Failed to create user profile for %: %', NEW.email, SQLERRM;
    RETURN NEW;
END;
$$;

-- 12. Create email confirmation trigger function
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

-- 13. Create the triggers
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER on_auth_user_email_confirmed
    AFTER UPDATE ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_user_email_confirmed();

-- 14. Enable RLS and create policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;

-- Create policies for users table
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Service role can do everything" ON public.users
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Trigger can insert users" ON public.users
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view based on role" ON public.users
    FOR SELECT USING (
        auth.uid() = id OR
        public.user_has_permission(auth.uid(), 'read', 'users')
    );

-- Create policies for role_permissions table
CREATE POLICY "Everyone can read role permissions" ON public.role_permissions
    FOR SELECT USING (true);

CREATE POLICY "Service role can manage role permissions" ON public.role_permissions
    FOR ALL USING (auth.role() = 'service_role');

-- 15. Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated, anon, service_role;
GRANT ALL ON public.users TO authenticated, anon, service_role;
GRANT ALL ON public.role_permissions TO authenticated, anon, service_role;
GRANT EXECUTE ON FUNCTION public.user_has_permission(UUID, TEXT, TEXT) TO authenticated, anon, service_role;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO authenticated, anon, service_role;
GRANT EXECUTE ON FUNCTION public.handle_user_email_confirmed() TO authenticated, anon, service_role;

-- 16. Create indexes for performance
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_role ON public.users(role);
CREATE INDEX idx_users_auth_provider ON public.users(auth_provider);
CREATE INDEX idx_users_registration_completed ON public.users(registration_completed);
CREATE INDEX idx_users_email_verified ON public.users(email_verified);
CREATE INDEX idx_users_is_active ON public.users(is_active);
CREATE INDEX idx_role_permissions_role ON public.role_permissions(role);
CREATE INDEX idx_role_permissions_resource ON public.role_permissions(resource);

-- 17. Create helper functions for user management
CREATE OR REPLACE FUNCTION public.promote_user_role(
    target_user_id UUID,
    new_role user_role
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if current user has permission to manage users
    IF NOT public.user_has_permission(auth.uid(), 'update', 'users') THEN
        RAISE EXCEPTION 'Insufficient permissions to change user roles';
    END IF;

    -- Update user role
    UPDATE public.users
    SET
        role = new_role,
        updated_at = NOW()
    WHERE id = target_user_id;

    RETURN FOUND;
END;
$$;

-- 18. Create role hierarchy view
CREATE OR REPLACE VIEW public.role_hierarchy AS
SELECT
    role,
    CASE role
        WHEN 'super_admin' THEN 6
        WHEN 'admin' THEN 5
        WHEN 'lab_manager' THEN 4
        WHEN 'instructor' THEN 3
        WHEN 'lab_staff' THEN 2
        WHEN 'student' THEN 1
    END as hierarchy_level,
    CASE role
        WHEN 'super_admin' THEN 'Full system access'
        WHEN 'admin' THEN 'Administrative access'
        WHEN 'lab_manager' THEN 'Lab management access'
        WHEN 'instructor' THEN 'Teaching and booking access'
        WHEN 'lab_staff' THEN 'Equipment assistance access'
        WHEN 'student' THEN 'Basic booking access'
    END as description
FROM (
    SELECT unnest(enum_range(NULL::user_role)) as role
) roles;

-- Grant permissions on new objects
GRANT EXECUTE ON FUNCTION public.promote_user_role(UUID, user_role) TO authenticated;
GRANT SELECT ON public.role_hierarchy TO authenticated, anon;

-- 19. Final status and instructions
SELECT 'Clean schema reset completed successfully!' as status,
       'No test users created to avoid foreign key issues' as note,
       'Users will be created automatically via triggers when they sign up' as user_creation,
       'Ready for Google OAuth testing with charan881130@gmail.com' as oauth_status;

-- 20. Instructions for creating admin user manually (if needed)
-- To create an admin user manually, first sign up normally, then run:
-- UPDATE public.users SET role = 'super_admin'::user_role WHERE email = 'your-email@example.com';
