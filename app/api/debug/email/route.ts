import { NextRequest, NextResponse } from 'next/server';
import { createSupabaseClient } from '@/lib/supabase';
import { EmailDebugger, debugEnvironment } from '@/lib/debug';

export async function GET(request: NextRequest) {
  try {
    const supabase = createSupabaseClient();
    
    // Get environment info
    const envInfo = debugEnvironment();
    
    // Get recent auth users using admin API
    const { data: authUsersData, error: usersError } = await supabase.auth.admin.listUsers({
      page: 1,
      perPage: 10
    });

    const users = authUsersData?.users || [];

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
        authUsers: users.map((u: any) => ({
          id: u.id,
          email: u.email,
          created_at: u.created_at,
          email_confirmed_at: u.email_confirmed_at,
          last_sign_in_at: u.last_sign_in_at,
        })),
        authUsersError: usersError,
        publicUsersCount: publicUsersCount || 0,
        publicUsersError: countError,
      },
      emailStatus: {
        totalUsers: users.length || 0,
        confirmedUsers: users.filter((u: any) => u.email_confirmed_at).length || 0,
        pendingUsers: users.filter((u: any) => !u.email_confirmed_at).length || 0,
        recentRecovery: 0, // Will calculate separately
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
        // Check if user exists using admin API
        try {
          const { data: userData, error: userError } = await supabase.auth.admin.listUsers();
          const user = userData?.users?.find((u: any) => u.email === email);

          return NextResponse.json({
            success: true,
            user: user ? {
              id: user.id,
              email: user.email,
              email_confirmed_at: user.email_confirmed_at,
              created_at: user.created_at,
            } : null,
            error: userError?.message || null,
            exists: !!user,
          });
        } catch (userCheckError) {
          return NextResponse.json({
            success: false,
            error: 'Failed to check user',
            exists: false,
          });
        }

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
