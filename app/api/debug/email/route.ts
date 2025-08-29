import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseClient } from '@/lib/supabase';
import { EmailDebugger, debugEnvironment } from '@/lib/debug';

export async function GET(request: NextRequest) {
  try {
    const supabase = createSupabaseClient();
    
    // Get environment info
    const envInfo = debugEnvironment();
    
    // Get recent auth users
    const { data: users, error: usersError } = await supabase
      .from('auth.users')
      .select('id, email, created_at, email_confirmed_at, confirmation_sent_at, recovery_sent_at')
      .order('created_at', { ascending: false })
      .limit(10);

    if (usersError) {
      console.error('Error fetching users:', usersError);
    }

    // Get public users count
    const { count: publicUsersCount, error: countError } = await supabase
      .from('users')
      .select('*', { count: 'exact', head: true });

    const debugInfo = {
      timestamp: new Date().toISOString(),
      environment: envInfo,
      database: {
        authUsers: users || [],
        authUsersError: usersError,
        publicUsersCount: publicUsersCount || 0,
        publicUsersError: countError,
      },
      emailStatus: {
        totalUsers: users?.length || 0,
        confirmedUsers: users?.filter(u => u.email_confirmed_at).length || 0,
        pendingUsers: users?.filter(u => !u.email_confirmed_at).length || 0,
        recentRecovery: users?.filter(u => u.recovery_sent_at).length || 0,
      },
    };

    // Log this debug request
    EmailDebugger.log({
      type: 'email_confirmation',
      email: 'debug-api',
      timestamp: new Date().toISOString(),
      details: {
        action: 'debug_api_called',
        userAgent: request.headers.get('user-agent'),
        ip: request.headers.get('x-forwarded-for'),
      },
    });

    return NextResponse.json(debugInfo);
  } catch (error) {
    console.error('Debug API error:', error);
    return NextResponse.json(
      { error: 'Debug API failed', details: error },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { email, action } = body;

    if (!email || !action) {
      return NextResponse.json(
        { error: 'Email and action are required' },
        { status: 400 }
      );
    }

    const supabase = createSupabaseClient();

    switch (action) {
      case 'test_registration':
        // Test registration flow
        EmailDebugger.logRegistration(email, {
          action: 'debug_test_registration',
          source: 'debug_api',
        });
        
        return NextResponse.json({
          success: true,
          message: 'Registration test logged',
          email,
        });

      case 'test_password_reset':
        // Test password reset flow
        EmailDebugger.logPasswordReset(email, {
          action: 'debug_test_password_reset',
          source: 'debug_api',
        });
        
        return NextResponse.json({
          success: true,
          message: 'Password reset test logged',
          email,
        });

      case 'check_user':
        // Check if user exists
        const { data: user, error } = await supabase
          .from('auth.users')
          .select('id, email, email_confirmed_at, created_at')
          .eq('email', email)
          .single();

        return NextResponse.json({
          success: true,
          user: user || null,
          error: error?.message || null,
          exists: !!user,
        });

      default:
        return NextResponse.json(
          { error: 'Invalid action' },
          { status: 400 }
        );
    }
  } catch (error) {
    console.error('Debug API POST error:', error);
    return NextResponse.json(
      { error: 'Debug API failed', details: error },
      { status: 500 }
    );
  }
}
