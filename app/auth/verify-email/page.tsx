'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Mail, Loader2, CheckCircle, RefreshCw } from 'lucide-react';
import { toast } from 'sonner';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { ThemeToggle } from '@/components/theme-toggle';

import { createSupabaseClient } from '@/lib/supabase';
import { useAuth } from '@/contexts/auth-context';

export default function VerifyEmailPage() {
  const [isResending, setIsResending] = useState(false);
  const [emailSent, setEmailSent] = useState(false);
  const [countdown, setCountdown] = useState(0);
  const router = useRouter();
  const { user, refreshUser } = useAuth();
  const supabase = createSupabaseClient();

  useEffect(() => {
    // Check if user is already verified
    const checkVerification = async () => {
      if (user) {
        const { data: { user: currentUser } } = await supabase.auth.getUser();
        if (currentUser?.email_confirmed_at) {
          router.push('/dashboard');
        }
      }
    };

    checkVerification();
  }, [user, router, supabase]);

  useEffect(() => {
    // Countdown timer for resend button
    if (countdown > 0) {
      const timer = setTimeout(() => setCountdown(countdown - 1), 1000);
      return () => clearTimeout(timer);
    }
  }, [countdown]);

  const handleResendEmail = async () => {
    if (!user?.email) {
      toast.error('No email address found');
      return;
    }

    setIsResending(true);

    try {
      const { error } = await supabase.auth.resend({
        type: 'signup',
        email: user.email,
        options: {
          emailRedirectTo: `${window.location.origin}/auth/callback`,
        },
      });

      if (error) {
        toast.error(error.message);
        return;
      }

      setEmailSent(true);
      setCountdown(60); // 60 second cooldown
      toast.success('Verification email sent! Please check your inbox.');
    } catch (error) {
      console.error('Error resending email:', error);
      toast.error('Failed to resend email. Please try again.');
    } finally {
      setIsResending(false);
    }
  };

  const handleRefreshStatus = async () => {
    try {
      await refreshUser();
      const { data: { user: currentUser } } = await supabase.auth.getUser();
      
      if (currentUser?.email_confirmed_at) {
        toast.success('Email verified successfully!');
        router.push('/dashboard');
      } else {
        toast.info('Email not yet verified. Please check your inbox.');
      }
    } catch (error) {
      console.error('Error refreshing status:', error);
      toast.error('Failed to refresh status');
    }
  };

  const handleSignOut = async () => {
    try {
      await supabase.auth.signOut();
      router.push('/auth/login');
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  if (!user) {
    return (
      <div className="auth-container">
        <div className="absolute top-4 right-4">
          <ThemeToggle />
        </div>
        
        <Card className="auth-card">
          <CardContent className="flex items-center justify-center py-8">
            <div className="text-center space-y-4">
              <Loader2 className="h-8 w-8 animate-spin mx-auto" />
              <p className="text-muted-foreground">Loading...</p>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="auth-container">
      <div className="absolute top-4 right-4">
        <ThemeToggle />
      </div>
      
      <Card className="auth-card">
        <CardHeader className="space-y-1 text-center">
          <div className="flex justify-center mb-4">
            <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center">
              <Mail className="h-8 w-8 text-primary" />
            </div>
          </div>
          <CardTitle className="text-2xl font-bold">
            Verify your email address
          </CardTitle>
          <CardDescription>
            We've sent a verification link to <strong>{user.email}</strong>
          </CardDescription>
        </CardHeader>
        
        <CardContent className="space-y-4">
          <Alert>
            <CheckCircle className="h-4 w-4" />
            <AlertDescription>
              <strong>Almost there!</strong> Click the verification link in your email to activate your account and access LabSyncPro.
            </AlertDescription>
          </Alert>

          <div className="text-center text-sm text-muted-foreground space-y-2">
            <p>The verification link will expire in 24 hours for security reasons.</p>
            <p>Make sure to check your spam or junk folder if you don't see the email.</p>
          </div>

          <div className="space-y-3">
            <Button
              variant="outline"
              className="w-full"
              onClick={handleRefreshStatus}
            >
              <RefreshCw className="mr-2 h-4 w-4" />
              I've verified my email
            </Button>

            <Button
              variant="outline"
              className="w-full"
              onClick={handleResendEmail}
              disabled={isResending || countdown > 0}
            >
              {isResending ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Sending...
                </>
              ) : countdown > 0 ? (
                `Resend in ${countdown}s`
              ) : (
                <>
                  <Mail className="mr-2 h-4 w-4" />
                  Resend verification email
                </>
              )}
            </Button>

            {emailSent && (
              <Alert>
                <Mail className="h-4 w-4" />
                <AlertDescription>
                  Verification email sent! Please check your inbox and spam folder.
                </AlertDescription>
              </Alert>
            )}
          </div>

          <div className="pt-4 border-t">
            <div className="text-center space-y-2">
              <p className="text-sm text-muted-foreground">
                Wrong email address or need help?
              </p>
              <Button
                variant="ghost"
                className="text-sm"
                onClick={handleSignOut}
              >
                Sign out and try again
              </Button>
            </div>
          </div>

          <div className="text-center text-xs text-muted-foreground">
            <p>
              If you continue to have issues, please contact our support team for assistance.
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
