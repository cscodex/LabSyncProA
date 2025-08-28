'use client';

import { createSupabaseClient } from '@/lib/supabase';
import type { User } from '@supabase/supabase-js';

export interface UserProfile {
  id: string;
  email: string;
  first_name: string;
  last_name: string;
  role: string;
  auth_provider: string;
  provider_id?: string;
  registration_completed: boolean;
  profile_completed: boolean;
  email_verified: boolean;
  is_active: boolean;
  profile_image_url?: string;
  phone_number?: string;
  department?: string;
  employee_id?: string;
  student_id?: string;
}

export interface AuthState {
  user: User | null;
  profile: UserProfile | null;
  loading: boolean;
  needsProfileCompletion: boolean;
  needsEmailVerification: boolean;
}

/**
 * Check if user needs to complete their profile
 */
export const checkProfileCompletion = (profile: UserProfile | null): boolean => {
  if (!profile) return true;
  
  // OAuth users need to complete profile if they haven't filled required fields
  if (profile.auth_provider !== 'email') {
    return !profile.profile_completed || 
           !profile.first_name || 
           !profile.last_name || 
           !profile.role;
  }
  
  // Email users need to complete registration
  return !profile.registration_completed;
};

/**
 * Check if user needs email verification
 */
export const checkEmailVerification = (user: User | null, profile: UserProfile | null): boolean => {
  if (!user || !profile) return true;
  
  // OAuth users from trusted providers (Google, Apple) are considered verified
  if (profile.auth_provider === 'google' || profile.auth_provider === 'apple') {
    return false;
  }
  
  // Email users need verification
  return !user.email_confirmed_at || !profile.email_verified;
};

/**
 * Get user registration source message
 */
export const getRegistrationSourceMessage = (profile: UserProfile | null): string => {
  if (!profile) return '';
  
  switch (profile.auth_provider) {
    case 'google':
      return 'You signed up using Google. Please complete your profile to continue.';
    case 'apple':
      return 'You signed up using Apple. Please complete your profile to continue.';
    case 'email':
      if (!profile.registration_completed) {
        return 'Please complete your registration by verifying your email address.';
      }
      return 'Welcome back! You can sign in with your email and password.';
    default:
      return 'Please complete your profile to continue.';
  }
};

/**
 * Create or update user profile from OAuth data
 */
export const handleOAuthProfile = async (user: User): Promise<UserProfile | null> => {
  const supabase = createSupabaseClient();
  
  try {
    // Check if profile already exists
    const { data: existingProfile, error: fetchError } = await supabase
      .from('users')
      .select('*')
      .eq('id', user.id)
      .single();

    if (fetchError && fetchError.code !== 'PGRST116') {
      console.error('Error fetching user profile:', fetchError);
      return null;
    }

    const userMetadata = user.user_metadata || {};
    const appMetadata = user.app_metadata || {};
    
    // Determine auth provider
    const authProvider = appMetadata.provider || 'email';
    
    // Extract profile data from OAuth metadata
    const profileData = {
      id: user.id,
      email: user.email!,
      first_name: userMetadata.first_name || userMetadata.given_name || '',
      last_name: userMetadata.last_name || userMetadata.family_name || '',
      role: userMetadata.role || 'student',
      auth_provider: authProvider,
      provider_id: userMetadata.provider_id || userMetadata.sub,
      profile_image_url: userMetadata.avatar_url || userMetadata.picture,
      phone_number: userMetadata.phone_number || userMetadata.phone,
      department: userMetadata.department,
      employee_id: userMetadata.employee_id,
      student_id: userMetadata.student_id,
      registration_completed: authProvider !== 'email', // OAuth users skip email registration
      profile_completed: false, // Will be set to true when user completes profile
      email_verified: authProvider === 'google' || authProvider === 'apple' || !!user.email_confirmed_at,
    };

    if (existingProfile) {
      // Update existing profile
      const { data: updatedProfile, error: updateError } = await (supabase as any)
        .from('users')
        .update({
          ...profileData,
          updated_at: new Date().toISOString(),
        })
        .eq('id', user.id)
        .select()
        .single();

      if (updateError) {
        console.error('Error updating user profile:', updateError);
        return null;
      }

      return updatedProfile;
    } else {
      // Create new profile
      const { data: newProfile, error: insertError } = await (supabase as any)
        .from('users')
        .insert(profileData)
        .select()
        .single();

      if (insertError) {
        console.error('Error creating user profile:', insertError);
        return null;
      }

      return newProfile;
    }
  } catch (error) {
    console.error('Error handling OAuth profile:', error);
    return null;
  }
};

/**
 * Complete user profile (for OAuth users)
 */
export const completeUserProfile = async (
  userId: string,
  profileData: Partial<UserProfile>
): Promise<boolean> => {
  const supabase = createSupabaseClient();
  
  try {
    const { error } = await (supabase as any)
      .from('users')
      .update({
        ...profileData,
        profile_completed: true,
        registration_completed: true,
        updated_at: new Date().toISOString(),
      })
      .eq('id', userId);

    if (error) {
      console.error('Error completing user profile:', error);
      return false;
    }

    return true;
  } catch (error) {
    console.error('Error completing user profile:', error);
    return false;
  }
};

/**
 * Get user profile by ID
 */
export const getUserProfile = async (userId: string): Promise<UserProfile | null> => {
  const supabase = createSupabaseClient();
  
  try {
    const { data: profile, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .single();

    if (error) {
      console.error('Error fetching user profile:', error);
      return null;
    }

    return profile;
  } catch (error) {
    console.error('Error fetching user profile:', error);
    return null;
  }
};

/**
 * Check if user can access the application
 */
export const canAccessApplication = (user: User | null, profile: UserProfile | null): boolean => {
  if (!user || !profile) return false;
  
  // Check if email is verified (for email users)
  if (profile.auth_provider === 'email' && !checkEmailVerification(user, profile)) {
    return false;
  }
  
  // Check if profile is completed
  if (checkProfileCompletion(profile)) {
    return false;
  }
  
  // Check if user is active
  if (!profile.is_active) {
    return false;
  }
  
  return true;
};

/**
 * Get redirect path based on user state
 */
export const getRedirectPath = (user: User | null, profile: UserProfile | null): string => {
  if (!user) return '/auth/login';
  
  if (!profile) return '/auth/complete-profile';
  
  // Check email verification
  if (checkEmailVerification(user, profile)) {
    return '/auth/verify-email';
  }
  
  // Check profile completion
  if (checkProfileCompletion(profile)) {
    return '/auth/complete-profile';
  }
  
  // User is fully set up
  return '/dashboard';
};
