'use client';

import { createContext, useContext, useEffect, useState } from 'react';
import { User } from '@supabase/supabase-js';
import { createSupabaseClient } from '@/lib/supabase';
import type { AuthUser, AuthContextType } from '@/types/auth.types';
import { toast } from 'sonner';

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [initialized, setInitialized] = useState(false);
  const supabase = createSupabaseClient();

  const fetchUserProfile = async (authUser: User) => {
    console.log('Fetching profile for user:', authUser.email);

    // Create basic user object immediately to prevent loading issues
    const basicUser: AuthUser = {
      id: authUser.id,
      email: authUser.email!,
      first_name: authUser.user_metadata?.first_name || authUser.user_metadata?.given_name || '',
      last_name: authUser.user_metadata?.last_name || authUser.user_metadata?.family_name || '',
      role: 'student',
      department: null,
      profile_image_url: authUser.user_metadata?.avatar_url || authUser.user_metadata?.picture || null,
      is_active: true,
      employee_id: null,
      student_id: null,
      phone_number: null,
    };

    // Set user immediately to prevent loading issues
    setUser(basicUser);
    setLoading(false);
    console.log('Basic user object created immediately');

    // Try to fetch/create database profile in background
    try {
      console.log('Attempting to fetch database profile...');

      const { data: profile, error } = await supabase
        .from('users')
        .select('*')
        .eq('id', authUser.id)
        .single();

      if (error && error.code === 'PGRST116') {
        // Profile doesn't exist - try to create it
        console.log('Database profile not found, creating...');

        const { error: insertError } = await (supabase as any)
          .from('users')
          .insert({
            id: authUser.id,
            email: authUser.email!,
            first_name: basicUser.first_name,
            last_name: basicUser.last_name,
            role: 'student',
            auth_provider: authUser.email?.includes('@gmail.com') ? 'google' : 'email',
            registration_completed: true,
            profile_completed: false,
            email_verified: true,
            is_active: true,
          });

        if (insertError) {
          console.error('Failed to create database profile:', insertError);
        } else {
          console.log('Database profile created successfully');
        }
      } else if (error) {
        console.error('Database query error:', error);
      } else if (profile) {
        // Profile found - update user object with database data
        console.log('Database profile found, updating user object');

        const updatedUser: AuthUser = {
          id: (profile as any).id,
          email: (profile as any).email,
          first_name: (profile as any).first_name || basicUser.first_name,
          last_name: (profile as any).last_name || basicUser.last_name,
          role: (profile as any).role || 'student',
          department: (profile as any).department,
          profile_image_url: (profile as any).profile_image_url || basicUser.profile_image_url,
          is_active: (profile as any).is_active ?? true,
          employee_id: (profile as any).employee_id,
          student_id: (profile as any).student_id,
          phone_number: (profile as any).phone_number,
          created_at: (profile as any).created_at,
        };

        setUser(updatedUser);
        console.log('User object updated with database data');
      }
    } catch (error) {
      console.error('Background profile operation failed:', error);
      // User object is already set, so this doesn't affect the UI
    }
  };



  const refreshUser = async () => {
    try {
      const { data: { user: authUser } } = await supabase.auth.getUser();
      if (authUser) {
        await fetchUserProfile(authUser);
      } else {
        setUser(null);
      }
    } catch (error) {
      console.error('Error refreshing user:', error);
      setUser(null);
    }
  };

  const updateProfile = async (data: Partial<AuthUser>) => {
    if (!user) return;

    try {
      // Temporarily disabled until database schema is updated
      console.log('Update user temporarily disabled until schema is updated');
      console.log('Data to update:', data);

      // Update local state only for now
      setUser((prev: AuthUser | null) => prev ? { ...prev, ...data } : null);
      toast.success('Profile updated successfully (local only)');
    } catch (error) {
      console.error('Error updating profile:', error);
      toast.error('Failed to update profile');
      throw error;
    }
  };

  const signOut = async () => {
    try {
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
      
      setUser(null);
      toast.success('Signed out successfully');
    } catch (error) {
      console.error('Error signing out:', error);
      toast.error('Failed to sign out');
    }
  };

  useEffect(() => {
    let mounted = true;

    // Hard timeout to ensure loading never gets stuck
    const hardTimeout = setTimeout(() => {
      if (mounted) {
        console.log('Hard timeout reached - forcing loading to false');
        setLoading(false);
        setInitialized(true);
      }
    }, 5000); // 5 second maximum

    const getInitialSession = async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession();
        console.log('Initial session check:', session?.user?.email);

        if (!mounted) return;

        if (session?.user) {
          await fetchUserProfile(session.user);
        } else {
          console.log('No session found');
          setUser(null);
          setLoading(false);
        }
      } catch (error) {
        console.error('Error getting initial session:', error);
        if (mounted) {
          setUser(null);
          setLoading(false);
        }
      } finally {
        if (mounted) {
          console.log('Setting initialized to true');
          setInitialized(true);
        }
      }
    };

    getInitialSession();

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event: string, session: any) => {
        console.log('Auth state changed:', event, session?.user?.email);

        if (!mounted) return;

        if (session?.user) {
          await fetchUserProfile(session.user);
        } else {
          setUser(null);
          setLoading(false);
        }

        if (!initialized && mounted) {
          setInitialized(true);
        }
      }
    );

    return () => {
      mounted = false;
      clearTimeout(hardTimeout);
      subscription.unsubscribe();
    };
  }, []); // No dependencies to prevent loops

  const value: AuthContextType = {
    user,
    loading,
    initialized,
    signOut,
    refreshUser,
    updateProfile,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
