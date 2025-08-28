-- Multi-Role User System Setup for LabSyncPro
-- This script sets up different user roles and permissions

-- 1. Create enum for user roles if it doesn't exist
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

-- 2. Update the users table to use the enum
ALTER TABLE public.users 
ALTER COLUMN role TYPE user_role USING role::user_role;

-- 3. Create role permissions table
CREATE TABLE IF NOT EXISTS public.role_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role user_role NOT NULL,
    permission TEXT NOT NULL,
    resource TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(role, permission, resource)
);

-- 4. Insert role permissions
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

-- 5. Create function to check user permissions
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
    user_role user_role;
    has_permission BOOLEAN := FALSE;
BEGIN
    -- Get user role
    SELECT role INTO user_role
    FROM public.users
    WHERE id = user_id;
    
    IF user_role IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Check if user has specific permission
    SELECT EXISTS(
        SELECT 1 FROM public.role_permissions
        WHERE role = user_role
        AND permission = permission_name
        AND (resource = resource_name OR resource = '*')
    ) INTO has_permission;
    
    RETURN has_permission;
END;
$$;

-- 6. Create admin user creation function
CREATE OR REPLACE FUNCTION public.create_admin_user(
    admin_email TEXT,
    admin_password TEXT,
    admin_first_name TEXT,
    admin_last_name TEXT,
    admin_role user_role DEFAULT 'admin'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_user_id UUID;
BEGIN
    -- Create auth user
    INSERT INTO auth.users (
        id,
        email,
        encrypted_password,
        email_confirmed_at,
        created_at,
        updated_at
    ) VALUES (
        gen_random_uuid(),
        admin_email,
        crypt(admin_password, gen_salt('bf')),
        NOW(),
        NOW(),
        NOW()
    ) RETURNING id INTO new_user_id;
    
    -- Create profile
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
        new_user_id,
        admin_email,
        admin_first_name,
        admin_last_name,
        admin_role,
        'email',
        true,
        true,
        true,
        true,
        NOW(),
        NOW()
    );
    
    RETURN new_user_id;
END;
$$;

-- 7. Create test users for different roles
DO $$
DECLARE
    admin_exists BOOLEAN;
BEGIN
    -- Check if any admin users exist
    SELECT EXISTS(
        SELECT 1 FROM public.users
        WHERE role IN ('super_admin', 'admin')
    ) INTO admin_exists;

    -- Create test users if none exist
    IF NOT admin_exists THEN
        -- Super Admin
        INSERT INTO public.users (
            id, email, first_name, last_name, role, auth_provider,
            registration_completed, profile_completed, email_verified, is_active
        ) VALUES (
            gen_random_uuid(), 'admin@labsyncpro.com', 'System', 'Administrator',
            'super_admin', 'email', true, true, true, true
        );

        -- Lab Manager
        INSERT INTO public.users (
            id, email, first_name, last_name, role, auth_provider,
            registration_completed, profile_completed, email_verified, is_active
        ) VALUES (
            gen_random_uuid(), 'labmanager@labsyncpro.com', 'Lab', 'Manager',
            'lab_manager', 'email', true, true, true, true
        );

        -- Instructor
        INSERT INTO public.users (
            id, email, first_name, last_name, role, auth_provider,
            registration_completed, profile_completed, email_verified, is_active
        ) VALUES (
            gen_random_uuid(), 'instructor@labsyncpro.com', 'John', 'Instructor',
            'instructor', 'email', true, true, true, true
        );

        -- Lab Staff
        INSERT INTO public.users (
            id, email, first_name, last_name, role, auth_provider,
            registration_completed, profile_completed, email_verified, is_active
        ) VALUES (
            gen_random_uuid(), 'staff@labsyncpro.com', 'Lab', 'Staff',
            'lab_staff', 'email', true, true, true, true
        );

        RAISE NOTICE 'Created test users for all roles';
        RAISE NOTICE 'Admin: admin@labsyncpro.com';
        RAISE NOTICE 'Lab Manager: labmanager@labsyncpro.com';
        RAISE NOTICE 'Instructor: instructor@labsyncpro.com';
        RAISE NOTICE 'Lab Staff: staff@labsyncpro.com';
    END IF;
END $$;

-- 8. Create RLS policies for role-based access
CREATE POLICY "Users can view based on role" ON public.users
    FOR SELECT USING (
        auth.uid() = id OR
        public.user_has_permission(auth.uid(), 'read', 'users')
    );

CREATE POLICY "Users can update based on role" ON public.users
    FOR UPDATE USING (
        auth.uid() = id OR
        public.user_has_permission(auth.uid(), 'update', 'users')
    );

-- 9. Create user management functions
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

-- 10. Create role hierarchy view
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

-- 11. Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.role_permissions TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_has_permission(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.promote_user_role(UUID, user_role) TO authenticated;
GRANT SELECT ON public.role_hierarchy TO authenticated;

-- 12. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_role_permissions_role ON public.role_permissions(role);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);

COMMENT ON FUNCTION public.user_has_permission(UUID, TEXT, TEXT) IS 'Check if user has specific permission for a resource';
COMMENT ON FUNCTION public.promote_user_role(UUID, user_role) IS 'Promote or change user role (requires admin permissions)';
COMMENT ON TABLE public.role_permissions IS 'Defines what each role can do with each resource';

SELECT 'Multi-role user system setup completed!' as status;
