import { UserRole } from './database.types';

export interface AuthUser {
  id: string;
  email: string;
  first_name: string;
  last_name: string;
  role: UserRole;
  department: string | null;
  profile_image_url: string | null;
  is_active: boolean;
  employee_id?: string | null;
  student_id?: string | null;
  phone_number?: string | null;
  created_at?: string;
}

export interface LoginFormData {
  email: string;
  password: string;
  rememberMe?: boolean;
}

export interface RegisterFormData {
  email: string;
  password: string;
  confirmPassword: string;
  firstName: string;
  lastName: string;
  role: UserRole;
  department?: string;
  employeeId?: string;
  studentId?: string;
  phoneNumber?: string;
  acceptTerms: boolean;
}

export interface ResetPasswordFormData {
  email: string;
}

export interface UpdatePasswordFormData {
  password: string;
  confirmPassword: string;
}

export interface ProfileCompletionFormData {
  firstName: string;
  lastName: string;
  role: UserRole;
  department?: string;
  employeeId?: string;
  studentId?: string;
  phoneNumber?: string;
}

export interface AuthState {
  user: AuthUser | null;
  loading: boolean;
  initialized: boolean;
}

export interface AuthContextType extends AuthState {
  signOut: () => Promise<void>;
  refreshUser: () => Promise<void>;
  updateProfile: (data: Partial<AuthUser>) => Promise<void>;
}

export type AuthProvider = 'google' | 'apple';

export interface SocialAuthOptions {
  provider: AuthProvider;
  redirectTo?: string;
  scopes?: string;
}

export interface PasswordStrength {
  score: number;
  feedback: string[];
  isValid: boolean;
}

export interface AuthError {
  message: string;
  code?: string;
  field?: string;
}

// Role-based permissions
export const ROLE_PERMISSIONS = {
  super_admin: ['*'],
  admin: [
    'users:read',
    'users:write',
    'labs:read',
    'labs:write',
    'equipment:read',
    'equipment:write',
    'courses:read',
    'courses:write',
    'reports:read',
  ],
  lab_manager: [
    'labs:read',
    'labs:write',
    'equipment:read',
    'equipment:write',
    'users:read',
    'sessions:read',
    'sessions:write',
  ],
  instructor: [
    'courses:read',
    'courses:write',
    'sessions:read',
    'sessions:write',
    'students:read',
    'grading:read',
    'grading:write',
  ],
  lab_staff: [
    'equipment:read',
    'equipment:write',
    'sessions:read',
    'maintenance:read',
    'maintenance:write',
  ],
  student: [
    'sessions:read',
    'submissions:read',
    'submissions:write',
    'grades:read',
  ],
} as const;

export type Permission = typeof ROLE_PERMISSIONS[keyof typeof ROLE_PERMISSIONS][number];

// Department options
export const DEPARTMENTS = [
  'Computer Science',
  'Information Technology',
  'Software Engineering',
  'Data Science',
  'Cybersecurity',
  'Network Engineering',
  'Digital Media',
  'Game Development',
  'Web Development',
  'Mobile Development',
  'Other',
] as const;

export type Department = typeof DEPARTMENTS[number];
