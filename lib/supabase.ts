import { createBrowserClient } from '@supabase/ssr';
import type { Database } from '@/types/database.types';

// Client-side Supabase client
export const createSupabaseClient = () => {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
};

// Admin client for server actions
export const createSupabaseAdminClient = () => {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  );
};



// Auth configuration
export const authConfig = {
  providers: {
    google: {
      enabled: true,
      scopes: 'email profile',
    },
    apple: {
      enabled: true,
      scopes: 'email name',
    },
  },
  redirectTo: `${process.env.NEXT_PUBLIC_SITE_URL}/auth/callback`,
  appearance: {
    theme: 'default',
    variables: {
      default: {
        colors: {
          brand: 'hsl(221.2 83.2% 53.3%)',
          brandAccent: 'hsl(221.2 83.2% 53.3%)',
        },
      },
    },
  },
};

// Rate limiting configuration
export const RATE_LIMITS = {
  login: {
    maxAttempts: 5,
    windowMs: 15 * 60 * 1000, // 15 minutes
  },
  register: {
    maxAttempts: 3,
    windowMs: 60 * 60 * 1000, // 1 hour
  },
  resetPassword: {
    maxAttempts: 3,
    windowMs: 60 * 60 * 1000, // 1 hour
  },
};

// Email templates configuration
export const EMAIL_TEMPLATES = {
  welcome: {
    subject: 'Welcome to LabSyncPro',
    template: 'welcome',
  },
  emailConfirmation: {
    subject: 'Confirm your email address',
    template: 'email-confirmation',
  },
  passwordReset: {
    subject: 'Reset your password',
    template: 'password-reset',
  },
  passwordChanged: {
    subject: 'Password changed successfully',
    template: 'password-changed',
  },
};

// Helper function to handle Supabase errors
export const handleSupabaseError = (error: any): string => {
  if (!error) return 'An unexpected error occurred. Please try again.';

  // Map common Supabase errors to user-friendly messages
  const errorMap: Record<string, string> = {
    'Invalid login credentials': 'Invalid email or password. Please check your credentials and try again.',
    'Email not confirmed': 'Please verify your email address before signing in. Check your inbox for a verification link.',
    'Email verification required. Please check your email and click the verification link.': 'Please verify your email address before signing in. Check your inbox for a verification link.',
    'User already registered': 'An account with this email already exists. Please sign in instead.',
    'Password should be at least 6 characters': 'Password must be at least 6 characters long.',
    'Unable to validate email address: invalid format': 'Please enter a valid email address.',
    'Signup is disabled': 'Account registration is currently disabled. Please contact support.',
    'Signup not allowed for this instance': 'Registration is currently disabled. Please contact support.',
    'Email rate limit exceeded': 'Too many emails sent. Please try again later.',
    'SMS rate limit exceeded': 'Too many SMS sent. Please try again later.',
    'Too many requests': 'Too many attempts. Please wait a moment and try again.',
    'Invalid refresh token': 'Your session has expired. Please sign in again.',
    'Token has expired': 'Your session has expired. Please sign in again.',
  };

  return errorMap[error.message] || error.message || 'An unexpected error occurred. Please try again.';
};

// Helper function to validate email domain (optional)
export const validateEmailDomain = (email: string): boolean => {
  // Add your institution's email domain validation here
  // For example, to only allow university emails:
  // const allowedDomains = ['university.edu', 'student.university.edu'];
  // const domain = email.split('@')[1];
  // return allowedDomains.includes(domain);
  
  // For now, allow all valid email addresses
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
};

// Helper function to generate secure passwords
export const generateSecurePassword = (length: number = 12): string => {
  const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
  let password = '';
  
  // Ensure at least one character from each required category
  password += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[Math.floor(Math.random() * 26)]; // uppercase
  password += 'abcdefghijklmnopqrstuvwxyz'[Math.floor(Math.random() * 26)]; // lowercase
  password += '0123456789'[Math.floor(Math.random() * 10)]; // number
  password += '!@#$%^&*'[Math.floor(Math.random() * 8)]; // special
  
  // Fill the rest randomly
  for (let i = password.length; i < length; i++) {
    password += charset[Math.floor(Math.random() * charset.length)];
  }
  
  // Shuffle the password
  return password.split('').sort(() => Math.random() - 0.5).join('');
};
