'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Loader2, CheckCircle, User } from 'lucide-react';
import { toast } from 'sonner';
import { z } from 'zod';

import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { ThemeToggle } from '@/components/theme-toggle';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';

import { createSupabaseClient } from '@/lib/supabase';
import { completeUserProfile, getUserProfile, getRegistrationSourceMessage } from '@/lib/auth-helpers';
import type { UserProfile } from '@/lib/auth-helpers';

const profileCompletionSchema = z.object({
  first_name: z.string().min(1, 'First name is required'),
  last_name: z.string().min(1, 'Last name is required'),
  role: z.enum(['student', 'instructor', 'lab_staff', 'lab_manager', 'admin'], {
    required_error: 'Please select your role',
  }),
  department: z.string().optional(),
  phone_number: z.string().optional(),
  employee_id: z.string().optional(),
  student_id: z.string().optional(),
});

type ProfileCompletionData = z.infer<typeof profileCompletionSchema>;

export default function CompleteProfilePage() {
  const [isLoading, setIsLoading] = useState(false);
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [loadingProfile, setLoadingProfile] = useState(true);
  const router = useRouter();
  const supabase = createSupabaseClient();

  const {
    register,
    handleSubmit,
    formState: { errors },
    setValue,
    watch,
    setError,
  } = useForm<ProfileCompletionData>({
    resolver: zodResolver(profileCompletionSchema),
  });

  const role = watch('role');

  useEffect(() => {
    const loadUserProfile = async () => {
      try {
        const { data: { user } } = await supabase.auth.getUser();
        
        if (!user) {
          router.push('/auth/login');
          return;
        }

        const profile = await getUserProfile(user.id);
        
        if (!profile) {
          toast.error('Unable to load profile. Please try again.');
          router.push('/auth/login');
          return;
        }

        setUserProfile(profile);
        
        // Pre-fill form with existing data
        setValue('first_name', profile.first_name || '');
        setValue('last_name', profile.last_name || '');
        setValue('role', profile.role as any || 'student');
        setValue('department', profile.department || '');
        setValue('phone_number', profile.phone_number || '');
        setValue('employee_id', profile.employee_id || '');
        setValue('student_id', profile.student_id || '');

        // If profile is already completed, redirect to dashboard
        if (profile.profile_completed && profile.registration_completed) {
          router.push('/dashboard');
        }
      } catch (error) {
        console.error('Error loading user profile:', error);
        toast.error('Unable to load profile. Please try again.');
        router.push('/auth/login');
      } finally {
        setLoadingProfile(false);
      }
    };

    loadUserProfile();
  }, [router, supabase, setValue]);

  const onSubmit = async (data: ProfileCompletionData) => {
    if (!userProfile) return;

    setIsLoading(true);

    try {
      const success = await completeUserProfile(userProfile.id, data);

      if (!success) {
        setError('root', { message: 'Failed to complete profile. Please try again.' });
        return;
      }

      toast.success('Profile completed successfully!');
      router.push('/dashboard');
    } catch (error) {
      console.error('Profile completion error:', error);
      setError('root', { message: 'An unexpected error occurred. Please try again.' });
    } finally {
      setIsLoading(false);
    }
  };

  if (loadingProfile) {
    return (
      <div className="auth-container">
        <div className="absolute top-4 right-4">
          <ThemeToggle />
        </div>
        
        <Card className="auth-card">
          <CardContent className="flex items-center justify-center py-8">
            <div className="text-center space-y-4">
              <Loader2 className="h-8 w-8 animate-spin mx-auto" />
              <p className="text-muted-foreground">Loading your profile...</p>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (!userProfile) {
    return (
      <div className="auth-container">
        <div className="absolute top-4 right-4">
          <ThemeToggle />
        </div>
        
        <Card className="auth-card">
          <CardHeader className="text-center">
            <CardTitle className="text-2xl font-bold">Profile Not Found</CardTitle>
            <CardDescription>
              Unable to load your profile. Please try signing in again.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Button 
              className="w-full" 
              onClick={() => router.push('/auth/login')}
            >
              Back to Sign In
            </Button>
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
      
      <Card className="auth-card max-w-2xl">
        <CardHeader className="space-y-1 text-center">
          <div className="flex justify-center mb-4">
            <Avatar className="h-20 w-20">
              <AvatarImage src={userProfile.profile_image_url} />
              <AvatarFallback>
                <User className="h-10 w-10" />
              </AvatarFallback>
            </Avatar>
          </div>
          <CardTitle className="text-2xl font-bold">
            Complete Your Profile
          </CardTitle>
          <CardDescription>
            {getRegistrationSourceMessage(userProfile)}
          </CardDescription>
        </CardHeader>
        
        <CardContent className="space-y-4">
          {errors.root && (
            <Alert variant="destructive">
              <AlertDescription>{errors.root.message}</AlertDescription>
            </Alert>
          )}

          <Alert>
            <CheckCircle className="h-4 w-4" />
            <AlertDescription>
              <strong>Email:</strong> {userProfile.email} 
              {userProfile.email_verified && (
                <span className="text-green-600 ml-2">✓ Verified</span>
              )}
            </AlertDescription>
          </Alert>

          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="first_name">First Name</Label>
                <Input
                  id="first_name"
                  placeholder="John"
                  {...register('first_name')}
                  className={errors.first_name ? 'border-destructive' : ''}
                />
                {errors.first_name && (
                  <p className="text-sm text-destructive">{errors.first_name.message}</p>
                )}
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="last_name">Last Name</Label>
                <Input
                  id="last_name"
                  placeholder="Doe"
                  {...register('last_name')}
                  className={errors.last_name ? 'border-destructive' : ''}
                />
                {errors.last_name && (
                  <p className="text-sm text-destructive">{errors.last_name.message}</p>
                )}
              </div>
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

            <div className="space-y-2">
              <Label htmlFor="department">Department (Optional)</Label>
              <Input
                id="department"
                placeholder="Computer Science"
                {...register('department')}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="phone_number">Phone Number (Optional)</Label>
              <Input
                id="phone_number"
                placeholder="+1 (555) 123-4567"
                {...register('phone_number')}
              />
            </div>

            {role && ['instructor', 'lab_staff', 'lab_manager', 'admin'].includes(role) && (
              <div className="space-y-2">
                <Label htmlFor="employee_id">Employee ID</Label>
                <Input
                  id="employee_id"
                  placeholder="EMP001"
                  {...register('employee_id')}
                />
              </div>
            )}

            {role === 'student' && (
              <div className="space-y-2">
                <Label htmlFor="student_id">Student ID</Label>
                <Input
                  id="student_id"
                  placeholder="STU001"
                  {...register('student_id')}
                />
              </div>
            )}

            <Button type="submit" className="w-full" disabled={isLoading}>
              {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              Complete Profile
            </Button>
          </form>

          <div className="text-center text-sm text-muted-foreground">
            Need help? Contact support for assistance.
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
