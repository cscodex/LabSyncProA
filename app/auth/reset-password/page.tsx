'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Loader2, Mail, ArrowLeft } from 'lucide-react';
import { toast } from 'sonner';

import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { ThemeToggle } from '@/components/theme-toggle';

import { createSupabaseClient, handleSupabaseError } from '@/lib/supabase';
import { resetPasswordSchema, type ResetPasswordFormData } from '@/lib/validations/auth';
import { EmailDebugger, debugEnvironment } from '@/lib/debug';

export default function ResetPasswordPage() {
  const [isLoading, setIsLoading] = useState(false);
  const [emailSent, setEmailSent] = useState(false);
  const [email, setEmail] = useState('');

  const supabase = createSupabaseClient();

  const {
    register,
    handleSubmit,
    formState: { errors },
    setError,
  } = useForm<ResetPasswordFormData>({
    resolver: zodResolver(resetPasswordSchema),
  });

  const onSubmit = async (data: ResetPasswordFormData) => {
    setIsLoading(true);

    try {
      // FORCE CONSOLE LOGS FOR RENDER DEBUGGING
      console.log('🔑 PASSWORD_RESET_START:', {
        email: data.email,
        timestamp: new Date().toISOString(),
        siteUrl: process.env.NEXT_PUBLIC_SITE_URL,
        redirectUrl: `${process.env.NEXT_PUBLIC_SITE_URL || window.location.origin}/auth/update-password`
      });
      console.error('🔑 PASSWORD_RESET_START:', data.email); // Ensure visibility in Render

      // Debug environment variables
      debugEnvironment();

      // Log password reset attempt
      EmailDebugger.logPasswordReset(data.email, {
        action: 'password_reset_attempt',
        redirectUrl: `${process.env.NEXT_PUBLIC_SITE_URL || window.location.origin}/auth/update-password`,
      });

      const { error } = await supabase.auth.resetPasswordForEmail(data.email, {
        redirectTo: `${process.env.NEXT_PUBLIC_SITE_URL || window.location.origin}/auth/update-password`,
      });

      // Log Supabase response
      EmailDebugger.logSupabaseResponse(data.email, { error }, 'password_reset_request');

      if (error) {
        EmailDebugger.logError(data.email, error, 'password_reset_error');
        const errorMessage = handleSupabaseError(error);
        setError('root', { message: errorMessage });
        return;
      }

      setEmail(data.email);
      setEmailSent(true);
      EmailDebugger.logPasswordReset(data.email, {
        action: 'password_reset_email_sent',
        emailSent: true,
      });
      toast.success('Password reset email sent!');
    } catch (error) {
      EmailDebugger.logError(data.email, error, 'password_reset_catch_error');
      console.error('Reset password error:', error);
      setError('root', { message: 'An unexpected error occurred' });
    } finally {
      setIsLoading(false);
    }
  };

  const handleResendEmail = async () => {
    if (!email) return;

    setIsLoading(true);
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/auth/update-password`,
      });

      if (error) {
        toast.error(handleSupabaseError(error));
        return;
      }

      toast.success('Password reset email sent again!');
    } catch (error) {
      console.error('Resend email error:', error);
      toast.error('Failed to resend email');
    } finally {
      setIsLoading(false);
    }
  };

  if (emailSent) {
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
              Check your email
            </CardTitle>
            <CardDescription>
              We've sent a password reset link to <strong>{email}</strong>
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="text-center text-sm text-muted-foreground">
              <p>Click the link in the email to reset your password.</p>
              <p className="mt-2">The link will expire in 1 hour for security reasons.</p>
            </div>
            
            <div className="space-y-2">
              <Button
                variant="outline"
                className="w-full"
                onClick={handleResendEmail}
                disabled={isLoading}
              >
                {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                Resend Email
              </Button>
              
              <Link href="/auth/login">
                <Button variant="ghost" className="w-full">
                  <ArrowLeft className="mr-2 h-4 w-4" />
                  Back to Sign In
                </Button>
              </Link>
            </div>

            <div className="text-center text-sm text-muted-foreground">
              Didn't receive the email? Check your spam folder or contact support.
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
        <CardHeader className="space-y-1">
          <div className="flex items-center justify-center mb-4">
            <div className="flex items-center space-x-2">
              <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
                <span className="text-primary-foreground font-bold text-lg">L</span>
              </div>
              <span className="text-2xl font-bold text-primary">LabSyncPro</span>
            </div>
          </div>
          <CardTitle className="text-2xl font-bold text-center">
            Reset your password
          </CardTitle>
          <CardDescription className="text-center">
            Enter your email address and we'll send you a link to reset your password
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {errors.root && (
            <Alert variant="destructive">
              <AlertDescription>{errors.root.message}</AlertDescription>
            </Alert>
          )}

          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="Enter your email address"
                autoComplete="email"
                {...register('email')}
                className={errors.email ? 'border-destructive' : ''}
              />
              {errors.email && (
                <p className="text-sm text-destructive">{errors.email.message}</p>
              )}
            </div>

            <Button type="submit" className="w-full" disabled={isLoading}>
              {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              Send Reset Link
            </Button>
          </form>

          <div className="text-center">
            <Link href="/auth/login">
              <Button variant="ghost" className="w-full">
                <ArrowLeft className="mr-2 h-4 w-4" />
                Back to Sign In
              </Button>
            </Link>
          </div>

          <div className="text-center text-sm text-muted-foreground">
            Remember your password?{' '}
            <Link 
              href="/auth/login" 
              className="text-primary hover:text-primary/80 underline-offset-4 hover:underline"
            >
              Sign in
            </Link>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
