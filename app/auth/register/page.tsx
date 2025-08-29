'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Eye, EyeOff, Loader2, CheckCircle } from 'lucide-react';
import { toast } from 'sonner';

import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Checkbox } from '@/components/ui/checkbox';
import { Separator } from '@/components/ui/separator';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { ThemeToggle } from '@/components/theme-toggle';
import { PasswordStrength } from '@/components/ui/password-strength';

import { createSupabaseClient, handleSupabaseError } from '@/lib/supabase';
import { registerSchema, type RegisterFormData } from '@/lib/validations/auth';
import { EmailDebugger, debugEnvironment } from '@/lib/debug';
import { DEPARTMENTS } from '@/types/auth.types';
import { SocialAuthButtons } from '@/components/auth/social-auth-buttons';

export default function RegisterPage() {
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [emailSent, setEmailSent] = useState(false);
  const router = useRouter();

  const supabase = createSupabaseClient();

  const {
    register,
    handleSubmit,
    formState: { errors },
    setError,
    watch,
    setValue,
  } = useForm<RegisterFormData>({
    resolver: zodResolver(registerSchema),
    defaultValues: {
      role: 'student',
      acceptTerms: false,
    },
  });

  const password = watch('password');
  const role = watch('role');
  const acceptTerms = watch('acceptTerms');

  const onSubmit = async (data: RegisterFormData) => {
    setIsLoading(true);

    try {
      // FORCE CONSOLE LOGS FOR RENDER DEBUGGING
      console.log('🚀 REGISTRATION_START:', {
        email: data.email,
        timestamp: new Date().toISOString(),
        siteUrl: process.env.NEXT_PUBLIC_SITE_URL,
        supabaseUrl: process.env.NEXT_PUBLIC_SUPABASE_URL
      });
      console.error('🚀 REGISTRATION_START:', data.email); // Ensure visibility in Render

      // Debug environment variables
      debugEnvironment();

      // Log registration attempt
      EmailDebugger.logRegistration(data.email, {
        action: 'registration_attempt',
        role: data.role,
        department: data.department,
        redirectUrl: `${process.env.NEXT_PUBLIC_SITE_URL || window.location.origin}/auth/callback`,
      });

      // Sign up the user with email confirmation
      const { data: authData, error: signUpError } = await supabase.auth.signUp({
        email: data.email,
        password: data.password,
        options: {
          emailRedirectTo: `${process.env.NEXT_PUBLIC_SITE_URL || window.location.origin}/auth/callback`,
          data: {
            first_name: data.firstName,
            last_name: data.lastName,
            role: data.role,
            department: data.department || null,
            employee_id: data.employeeId || null,
            student_id: data.studentId || null,
            phone_number: data.phoneNumber || null,
          },
        },
      });

      // Log Supabase response
      EmailDebugger.logSupabaseResponse(data.email, { data: authData, error: signUpError }, 'registration_signup');

      if (signUpError) {
        EmailDebugger.logError(data.email, signUpError, 'registration_signup_error');
        const errorMessage = handleSupabaseError(signUpError);
        setError('root', { message: errorMessage });
        return;
      }

      if (authData.user) {
        // Create user profile in our users table
        const { error: profileError } = await (supabase as any)
          .from('users')
          .insert({
            id: authData.user.id,
            email: data.email,
            first_name: data.firstName,
            last_name: data.lastName,
            role: data.role,
            department: data.department || null,
            employee_id: data.employeeId || null,
            student_id: data.studentId || null,
            phone_number: data.phoneNumber || null,
            auth_provider: 'email',
            registration_completed: true,
            profile_completed: true,
            email_verified: false,
            is_active: true,
          });

        if (profileError) {
          EmailDebugger.logError(data.email, profileError, 'profile_creation_error');
          console.error('Profile creation error:', profileError);
          // Don't show error to user as the auth account was created successfully
        } else {
          EmailDebugger.logRegistration(data.email, {
            action: 'profile_created_successfully',
            userId: authData.user?.id,
          });
        }
      }

      setEmailSent(true);
      EmailDebugger.logRegistration(data.email, {
        action: 'registration_completed',
        emailSent: true,
        needsEmailVerification: !authData.user?.email_confirmed_at,
      });
      toast.success('Registration successful! Please check your email to verify your account.');
    } catch (error) {
      EmailDebugger.logError(data.email, error, 'registration_catch_error');
      console.error('Registration error:', error);
      setError('root', { message: 'An unexpected error occurred' });
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
              <CheckCircle className="h-16 w-16 text-green-500" />
            </div>
            <CardTitle className="text-2xl font-bold">
              Check your email
            </CardTitle>
            <CardDescription>
              We've sent a verification link to your email address. Please click the link to activate your account.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="text-center text-sm text-muted-foreground">
              Didn't receive the email? Check your spam folder or{' '}
              <Button
                variant="link"
                className="p-0 h-auto text-primary"
                onClick={() => setEmailSent(false)}
              >
                try again
              </Button>
            </div>
            <div className="text-center">
              <Link href="/auth/login">
                <Button variant="outline" className="w-full">
                  Back to Sign In
                </Button>
              </Link>
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
      
      <Card className="auth-card max-w-lg">
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
            Create your account
          </CardTitle>
          <CardDescription className="text-center">
            Join LabSyncPro to manage your laboratory activities
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {errors.root && (
            <Alert variant="destructive">
              <AlertDescription>{errors.root.message}</AlertDescription>
            </Alert>
          )}

          <SocialAuthButtons />

          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <Separator className="w-full" />
            </div>
            <div className="relative flex justify-center text-xs uppercase">
              <span className="bg-background px-2 text-muted-foreground">
                Or continue with email
              </span>
            </div>
          </div>

          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="firstName">First Name</Label>
                <Input
                  id="firstName"
                  placeholder="John"
                  autoComplete="given-name"
                  {...register('firstName')}
                  className={errors.firstName ? 'border-destructive' : ''}
                />
                {errors.firstName && (
                  <p className="text-sm text-destructive">{errors.firstName.message}</p>
                )}
              </div>
              <div className="space-y-2">
                <Label htmlFor="lastName">Last Name</Label>
                <Input
                  id="lastName"
                  placeholder="Doe"
                  autoComplete="family-name"
                  {...register('lastName')}
                  className={errors.lastName ? 'border-destructive' : ''}
                />
                {errors.lastName && (
                  <p className="text-sm text-destructive">{errors.lastName.message}</p>
                )}
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="john.doe@university.edu"
                autoComplete="email"
                {...register('email')}
                className={errors.email ? 'border-destructive' : ''}
              />
              {errors.email && (
                <p className="text-sm text-destructive">{errors.email.message}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="role">Role</Label>
              <Select
                value={role}
                onValueChange={(value) => setValue('role', value as any)}
              >
                <SelectTrigger className={errors.role ? 'border-destructive' : ''}>
                  <SelectValue placeholder="Select your role" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="student">Student</SelectItem>
                  <SelectItem value="instructor">Instructor</SelectItem>
                  <SelectItem value="lab_staff">Lab Staff</SelectItem>
                  <SelectItem value="lab_manager">Lab Manager</SelectItem>
                  <SelectItem value="admin">Admin</SelectItem>
                </SelectContent>
              </Select>
              {errors.role && (
                <p className="text-sm text-destructive">{errors.role.message}</p>
              )}
            </div>

            {role && ['super_admin', 'admin', 'lab_manager', 'instructor', 'lab_staff'].includes(role) && (
              <div className="space-y-2">
                <Label htmlFor="employeeId">Employee ID</Label>
                <Input
                  id="employeeId"
                  placeholder="EMP001"
                  {...register('employeeId')}
                  className={errors.employeeId ? 'border-destructive' : ''}
                />
                {errors.employeeId && (
                  <p className="text-sm text-destructive">{errors.employeeId.message}</p>
                )}
              </div>
            )}

            {role === 'student' && (
              <div className="space-y-2">
                <Label htmlFor="studentId">Student ID</Label>
                <Input
                  id="studentId"
                  placeholder="STU001"
                  {...register('studentId')}
                  className={errors.studentId ? 'border-destructive' : ''}
                />
                {errors.studentId && (
                  <p className="text-sm text-destructive">{errors.studentId.message}</p>
                )}
              </div>
            )}

            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <div className="relative">
                <Input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  placeholder="Create a strong password"
                  autoComplete="new-password"
                  {...register('password')}
                  className={errors.password ? 'border-destructive pr-10' : 'pr-10'}
                />
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  className="absolute right-0 top-0 h-full px-3 py-2 hover:bg-transparent"
                  onClick={() => setShowPassword(!showPassword)}
                  tabIndex={-1}
                >
                  {showPassword ? (
                    <EyeOff className="h-4 w-4" />
                  ) : (
                    <Eye className="h-4 w-4" />
                  )}
                </Button>
              </div>
              {password && <PasswordStrength password={password} />}
              {errors.password && (
                <p className="text-sm text-destructive">{errors.password.message}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="confirmPassword">Confirm Password</Label>
              <div className="relative">
                <Input
                  id="confirmPassword"
                  type={showConfirmPassword ? 'text' : 'password'}
                  placeholder="Confirm your password"
                  autoComplete="new-password"
                  {...register('confirmPassword')}
                  className={errors.confirmPassword ? 'border-destructive pr-10' : 'pr-10'}
                />
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  className="absolute right-0 top-0 h-full px-3 py-2 hover:bg-transparent"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                  tabIndex={-1}
                >
                  {showConfirmPassword ? (
                    <EyeOff className="h-4 w-4" />
                  ) : (
                    <Eye className="h-4 w-4" />
                  )}
                </Button>
              </div>
              {errors.confirmPassword && (
                <p className="text-sm text-destructive">{errors.confirmPassword.message}</p>
              )}
            </div>

            <div className="flex items-start space-x-2">
              <Checkbox
                id="acceptTerms"
                checked={acceptTerms}
                onCheckedChange={(checked) => setValue('acceptTerms', checked as boolean)}
                className="mt-1"
              />
              <Label htmlFor="acceptTerms" className="text-sm cursor-pointer leading-relaxed">
                I agree to the{' '}
                <Link href="/terms" className="text-primary hover:underline">
                  Terms of Service
                </Link>{' '}
                and{' '}
                <Link href="/privacy" className="text-primary hover:underline">
                  Privacy Policy
                </Link>
              </Label>
            </div>
            {errors.acceptTerms && (
              <p className="text-sm text-destructive">{errors.acceptTerms.message}</p>
            )}

            <Button type="submit" className="w-full" disabled={isLoading}>
              {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              Create Account
            </Button>
          </form>

          <div className="text-center text-sm">
            Already have an account?{' '}
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
