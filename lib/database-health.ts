// Database health check utilities
import { createSupabaseClient } from './supabase';

export async function checkDatabaseHealth(): Promise<boolean> {
  try {
    const supabase = createSupabaseClient();
    
    // Quick health check with 3-second timeout
    const { error } = await Promise.race([
      supabase.from('users').select('count').limit(1),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Health check timeout')), 3000)
      )
    ]) as any;

    if (error) {
      console.warn('Database health check failed:', error);
      return false;
    }

    return true;
  } catch (error) {
    console.warn('Database health check error:', error);
    return false;
  }
}

export async function fetchUserProfileWithFallback(userId: string): Promise<any> {
  try {
    const supabase = createSupabaseClient();
    
    // Check database health first
    const isHealthy = await checkDatabaseHealth();
    if (!isHealthy) {
      console.log('Database unhealthy, skipping profile fetch');
      return null;
    }

    // Fetch profile with reasonable timeout
    const { data: profile, error } = await Promise.race([
      supabase.from('users').select('*').eq('id', userId).single(),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Profile fetch timeout')), 8000)
      )
    ]) as any;

    if (error) {
      console.warn('Profile fetch error:', error);
      return null;
    }

    return profile;
  } catch (error) {
    console.warn('Profile fetch failed:', error);
    return null;
  }
}
