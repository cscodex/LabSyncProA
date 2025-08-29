// Debug utilities for email verification and password reset
// These logs will appear in Render deployment logs

interface DebugEmailEvent {
  type: 'registration' | 'password_reset' | 'email_confirmation' | 'error';
  email: string;
  timestamp: string;
  details: any;
  userAgent?: string;
  ip?: string;
}

export class EmailDebugger {
  private static isProduction = process.env.NODE_ENV === 'production';
  private static isDevelopment = process.env.NODE_ENV === 'development';

  static log(event: DebugEmailEvent) {
    const logData = {
      ...event,
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV,
      siteUrl: process.env.NEXT_PUBLIC_SITE_URL,
    };

    // ALWAYS log in production and development for debugging
    console.log('🔍 EMAIL_DEBUG:', JSON.stringify(logData, null, 2));
    console.error('🔍 EMAIL_DEBUG_ERROR:', JSON.stringify(logData, null, 2)); // Also log as error to ensure visibility

    // Additional console methods to ensure visibility in Render
    if (this.isProduction) {
      console.warn('📧 RENDER_EMAIL_DEBUG:', JSON.stringify(logData, null, 2));
    }
  }

  static logRegistration(email: string, details: any, request?: any) {
    this.log({
      type: 'registration',
      email,
      timestamp: new Date().toISOString(),
      details: {
        ...details,
        supabaseUrl: process.env.NEXT_PUBLIC_SUPABASE_URL,
        redirectUrl: `${process.env.NEXT_PUBLIC_SITE_URL}/auth/callback`,
      },
      userAgent: request?.headers?.['user-agent'],
      ip: request?.headers?.['x-forwarded-for'] || request?.headers?.['x-real-ip'],
    });
  }

  static logPasswordReset(email: string, details: any, request?: any) {
    this.log({
      type: 'password_reset',
      email,
      timestamp: new Date().toISOString(),
      details: {
        ...details,
        supabaseUrl: process.env.NEXT_PUBLIC_SUPABASE_URL,
        redirectUrl: `${process.env.NEXT_PUBLIC_SITE_URL}/auth/update-password`,
      },
      userAgent: request?.headers?.['user-agent'],
      ip: request?.headers?.['x-forwarded-for'] || request?.headers?.['x-real-ip'],
    });
  }

  static logEmailConfirmation(email: string, details: any) {
    this.log({
      type: 'email_confirmation',
      email,
      timestamp: new Date().toISOString(),
      details,
    });
  }

  static logError(email: string, error: any, context: string) {
    this.log({
      type: 'error',
      email,
      timestamp: new Date().toISOString(),
      details: {
        context,
        error: {
          message: error?.message,
          code: error?.code,
          status: error?.status,
          stack: error?.stack,
        },
        environment: {
          nodeEnv: process.env.NODE_ENV,
          siteUrl: process.env.NEXT_PUBLIC_SITE_URL,
          supabaseUrl: process.env.NEXT_PUBLIC_SUPABASE_URL,
        },
      },
    });
  }

  static logSupabaseResponse(email: string, response: any, context: string) {
    this.log({
      type: 'email_confirmation',
      email,
      timestamp: new Date().toISOString(),
      details: {
        context,
        response: {
          data: response?.data ? 'Present' : 'Missing',
          error: response?.error ? {
            message: response.error.message,
            code: response.error.code,
            status: response.error.status,
          } : null,
          user: response?.data?.user ? {
            id: response.data.user.id,
            email: response.data.user.email,
            emailConfirmed: response.data.user.email_confirmed_at ? 'Yes' : 'No',
            createdAt: response.data.user.created_at,
          } : null,
        },
      },
    });
  }
}

// Helper function to check environment variables
export function debugEnvironment() {
  const envVars = {
    NODE_ENV: process.env.NODE_ENV,
    NEXT_PUBLIC_SITE_URL: process.env.NEXT_PUBLIC_SITE_URL,
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ? 'Set' : 'Missing',
    SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY ? 'Set' : 'Missing',
  };

  console.log('🔧 ENVIRONMENT_DEBUG:', JSON.stringify(envVars, null, 2));
  return envVars;
}

// Helper to log request details
export function debugRequest(request: any, context: string) {
  const requestInfo = {
    context,
    method: request?.method,
    url: request?.url,
    headers: {
      userAgent: request?.headers?.['user-agent'],
      origin: request?.headers?.origin,
      referer: request?.headers?.referer,
      xForwardedFor: request?.headers?.['x-forwarded-for'],
    },
    timestamp: new Date().toISOString(),
  };

  console.log('🌐 REQUEST_DEBUG:', JSON.stringify(requestInfo, null, 2));
  return requestInfo;
}
