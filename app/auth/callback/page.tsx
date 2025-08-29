'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Loader2, AlertCircle } from 'lucide-react';
import { toast } from 'sonner';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { ThemeToggle } from '@/components/theme-toggle';

import { createSupabaseClient } from '@/lib/supabase';
import { EmailDebugger } from '@/lib/debug';

export default function AuthCallbackPage() {
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();
  const supabase = createSupabaseClient();

  useEffect(() => {
    const handleAuthCallback = async () => {
      try {
        console.log('Auth callback started');

        // Handle OAuth callback by exchanging code for session
        const { data, error } = await supabase.auth.exchangeCodeForSession(window.location.href);

        if (error) {
          console.error('Auth callback error:', error);
          EmailDebugger.logError('unknown', error, 'auth_callback_error');
          setError('Authentication failed. Please try again.');
          setIsLoading(false);
          return;
        }

        if (data.session?.user) {
          console.log('Auth callback successful:', data.session.user.email);
          EmailDebugger.logEmailConfirmation(data.session.user.email || 'unknown', {
            action: 'auth_callback_success',
            userId: data.session.user.id,
            emailConfirmed: data.session.user.email_confirmed_at ? 'Yes' : 'No',
            provider: data.session.user.app_metadata?.provider || 'email',
          });

          // Simple redirect to dashboard - let the auth context and route protection handle the rest
          toast.success('Authentication completed!');
          router.replace('/dashboard');
        } else {
          console.log('No session found in callback, redirecting to login');
          router.replace('/auth/login');
        }
      } catch (err) {
        console.error('Auth callback catch error:', err);
        EmailDebugger.logError('unknown', err, 'auth_callback_catch_error');
        setError('Authentication failed. Please try again.');
        setIsLoading(false);
      }
    };

    // Add a small delay to ensure the URL is processed
    const timer = setTimeout(handleAuthCallback, 500);

    return () => clearTimeout(timer);
  }, [router, supabase]);

  if (isLoading) {
    return (
      <div className="auth-container">
        <div className="absolute top-4 right-4">
          <ThemeToggle />
        </div>
        
        <Card className="auth-card">
          <CardContent className="flex items-center justify-center py-8">
            <div className="text-center space-y-4">
              <Loader2 className="h-8 w-8 animate-spin mx-auto" />
              <p className="text-muted-foreground">Completing authentication...</p>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (error) {
    return (
      <div className="auth-container">
        <div className="absolute top-4 right-4">
          <ThemeToggle />
        </div>
        
        <Card className="auth-card">
          <CardHeader className="text-center">
            <div className="flex justify-center mb-4">
              <AlertCircle className="h-16 w-16 text-destructive" />
            </div>
            <CardTitle className="text-2xl font-bold">
              Authentication Error
            </CardTitle>
            <CardDescription>
              There was a problem completing your authentication
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <Alert variant="destructive">
              <AlertDescription>{error}</AlertDescription>
            </Alert>
            
            <div className="space-y-2">
              <Button
                className="w-full"
                onClick={() => router.push('/auth/login')}
              >
                Try Again
              </Button>
              
              <Button
                variant="outline"
                className="w-full"
                onClick={() => router.push('/auth/register')}
              >
                Create New Account
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return null;
}
