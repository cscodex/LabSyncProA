import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseClient } from '@/lib/supabase';

export async function GET(request: NextRequest) {
  console.log('🔍 EMAIL_STATUS_CHECK: Starting email status check');
  console.error('🔍 EMAIL_STATUS_CHECK: Starting email status check'); // Ensure visibility
  
  try {
    const supabase = createSupabaseClient();
    
    // Check environment variables
    const envCheck = {
      NODE_ENV: process.env.NODE_ENV,
      NEXT_PUBLIC_SITE_URL: process.env.NEXT_PUBLIC_SITE_URL,
      NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
      NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ? 'SET' : 'MISSING',
      SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY ? 'SET' : 'MISSING',
    };
    
    console.log('🔍 EMAIL_STATUS_ENV:', JSON.stringify(envCheck, null, 2));
    console.error('🔍 EMAIL_STATUS_ENV:', JSON.stringify(envCheck, null, 2));
    
    // Test Supabase connection
    const { data: testData, error: testError } = await supabase
      .from('users')
      .select('count')
      .limit(1);
    
    console.log('🔍 SUPABASE_CONNECTION_TEST:', { 
      success: !testError, 
      error: testError?.message,
      data: testData ? 'Connected' : 'No data'
    });
    
    // Get recent auth activity
    const { data: recentUsers, error: usersError } = await supabase.auth.admin.listUsers({
      page: 1,
      perPage: 5
    });
    
    const emailStatus = {
      timestamp: new Date().toISOString(),
      environment: envCheck,
      supabaseConnection: {
        connected: !testError,
        error: testError?.message || null,
      },
      recentUsers: {
        count: recentUsers?.users?.length || 0,
        error: usersError?.message || null,
        users: recentUsers?.users?.map(u => ({
          email: u.email,
          emailConfirmed: u.email_confirmed_at ? 'YES' : 'NO',
          createdAt: u.created_at,
          lastSignIn: u.last_sign_in_at,
        })) || [],
      },
      checks: {
        siteUrlSet: !!process.env.NEXT_PUBLIC_SITE_URL,
        supabaseUrlSet: !!process.env.NEXT_PUBLIC_SUPABASE_URL,
        anonKeySet: !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
        serviceKeySet: !!process.env.SUPABASE_SERVICE_ROLE_KEY,
      }
    };
    
    console.log('🔍 EMAIL_STATUS_COMPLETE:', JSON.stringify(emailStatus, null, 2));
    console.error('🔍 EMAIL_STATUS_COMPLETE:', JSON.stringify(emailStatus, null, 2));
    
    return NextResponse.json(emailStatus);
    
  } catch (error) {
    const errorInfo = {
      timestamp: new Date().toISOString(),
      error: {
        message: error instanceof Error ? error.message : 'Unknown error',
        stack: error instanceof Error ? error.stack : null,
      }
    };
    
    console.error('🔍 EMAIL_STATUS_ERROR:', JSON.stringify(errorInfo, null, 2));
    
    return NextResponse.json(errorInfo, { status: 500 });
  }
}

// Test email sending capability
export async function POST(request: NextRequest) {
  console.log('🔍 EMAIL_TEST: Starting email test');
  console.error('🔍 EMAIL_TEST: Starting email test');
  
  try {
    const { email, type } = await request.json();
    
    if (!email) {
      return NextResponse.json({ error: 'Email required' }, { status: 400 });
    }
    
    const supabase = createSupabaseClient();
    
    if (type === 'registration') {
      console.log('🔍 EMAIL_TEST_REGISTRATION:', { email, timestamp: new Date().toISOString() });
      
      // Test registration email
      const { data, error } = await supabase.auth.signUp({
        email: email,
        password: 'TempPassword123!',
        options: {
          emailRedirectTo: `${process.env.NEXT_PUBLIC_SITE_URL}/auth/callback`,
        }
      });
      
      console.log('🔍 EMAIL_TEST_REGISTRATION_RESULT:', {
        success: !error,
        error: error?.message,
        userCreated: !!data.user,
        emailSent: !error,
        timestamp: new Date().toISOString()
      });
      
      return NextResponse.json({
        success: !error,
        error: error?.message,
        userCreated: !!data.user,
        message: error ? 'Registration failed' : 'Registration test completed'
      });
      
    } else if (type === 'password_reset') {
      console.log('🔍 EMAIL_TEST_PASSWORD_RESET:', { email, timestamp: new Date().toISOString() });
      
      // Test password reset email
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${process.env.NEXT_PUBLIC_SITE_URL}/auth/update-password`,
      });
      
      console.log('🔍 EMAIL_TEST_PASSWORD_RESET_RESULT:', {
        success: !error,
        error: error?.message,
        timestamp: new Date().toISOString()
      });
      
      return NextResponse.json({
        success: !error,
        error: error?.message,
        message: error ? 'Password reset failed' : 'Password reset test completed'
      });
    }
    
    return NextResponse.json({ error: 'Invalid test type' }, { status: 400 });
    
  } catch (error) {
    console.error('🔍 EMAIL_TEST_ERROR:', {
      error: error instanceof Error ? error.message : 'Unknown error',
      timestamp: new Date().toISOString()
    });
    
    return NextResponse.json({
      error: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}
