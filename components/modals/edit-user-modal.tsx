'use client';

import { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import { z } from 'zod';

import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';

import { createSupabaseClient } from '@/lib/supabase';
import { DEPARTMENTS } from '@/lib/validations/auth';
import type { UserRole } from '@/types/database.types';

// Edit user form validation schema
const editUserSchema = z.object({
  first_name: z.string().min(2, 'First name must be at least 2 characters'),
  last_name: z.string().min(2, 'Last name must be at least 2 characters'),
  email: z.string().email('Invalid email address'),
  role: z.enum(['super_admin', 'admin', 'lab_manager', 'instructor', 'lab_staff', 'student']),
  department: z.string().optional(),
  employee_id: z.string().optional(),
  student_id: z.string().optional(),
  phone_number: z.string().optional(),
  is_active: z.boolean(),
});

type EditUserFormData = z.infer<typeof editUserSchema>;

interface User {
  id: string;
  email: string;
  first_name: string;
  last_name: string;
  role: UserRole;
  department: string | null;
  is_active: boolean;
  employee_id: string | null;
  student_id: string | null;
  phone_number: string | null;
}

interface EditUserModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  user: User | null;
  onUserUpdated: () => void;
}

export function EditUserModal({ open, onOpenChange, user, onUserUpdated }: EditUserModalProps) {
  const [isLoading, setIsLoading] = useState(false);
  const supabase = createSupabaseClient();

  const {
    register,
    handleSubmit,
    formState: { errors },
    setValue,
    watch,
    reset,
  } = useForm<EditUserFormData>({
    resolver: zodResolver(editUserSchema),
  });

  const role = watch('role');

  // Initialize form with user data when user changes
  useEffect(() => {
    if (user) {
      reset({
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        role: user.role,
        department: user.department || '',
        employee_id: user.employee_id || '',
        student_id: user.student_id || '',
        phone_number: user.phone_number || '',
        is_active: user.is_active,
      });
    }
  }, [user, reset]);

  const onSubmit = async (data: EditUserFormData) => {
    if (!user) return;
    
    setIsLoading(true);
    try {
      // Update user profile in database
      const { error: profileError } = await supabase
        .from('users')
        .update({
          first_name: data.first_name,
          last_name: data.last_name,
          role: data.role,
          department: data.department || null,
          employee_id: data.employee_id || null,
          student_id: data.student_id || null,
          phone_number: data.phone_number || null,
          is_active: data.is_active,
          updated_at: new Date().toISOString(),
        })
        .eq('id', user.id);

      if (profileError) throw profileError;

      // Update email in Supabase Auth if changed
      if (data.email !== user.email) {
        const { error: emailError } = await supabase.auth.admin.updateUserById(
          user.id,
          { email: data.email }
        );

        if (emailError) throw emailError;

        // Also update email in users table
        const { error: emailUpdateError } = await supabase
          .from('users')
          .update({ email: data.email })
          .eq('id', user.id);

        if (emailUpdateError) throw emailUpdateError;
      }

      toast.success('User updated successfully!');
      onUserUpdated();
      onOpenChange(false);
    } catch (error) {
      console.error('Error updating user:', error);
      toast.error('Failed to update user. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleCancel = () => {
    if (user) {
      reset({
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        role: user.role,
        department: user.department || '',
        employee_id: user.employee_id || '',
        student_id: user.student_id || '',
        phone_number: user.phone_number || '',
        is_active: user.is_active,
      });
    }
    onOpenChange(false);
  };

  if (!user) return null;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Edit User</DialogTitle>
          <DialogDescription>
            Update user information and settings.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* First Name */}
            <div className="space-y-2">
              <Label htmlFor="first_name">First Name</Label>
              <Input
                id="first_name"
                {...register('first_name')}
                className={errors.first_name ? 'border-destructive' : ''}
              />
              {errors.first_name && (
                <p className="text-sm text-destructive">{errors.first_name.message}</p>
              )}
            </div>

            {/* Last Name */}
            <div className="space-y-2">
              <Label htmlFor="last_name">Last Name</Label>
              <Input
                id="last_name"
                {...register('last_name')}
                className={errors.last_name ? 'border-destructive' : ''}
              />
              {errors.last_name && (
                <p className="text-sm text-destructive">{errors.last_name.message}</p>
              )}
            </div>

            {/* Email */}
            <div className="space-y-2">
              <Label htmlFor="email">Email Address</Label>
              <Input
                id="email"
                type="email"
                {...register('email')}
                className={errors.email ? 'border-destructive' : ''}
              />
              {errors.email && (
                <p className="text-sm text-destructive">{errors.email.message}</p>
              )}
              <p className="text-xs text-muted-foreground">
                Changing email will require user to verify the new address.
              </p>
            </div>

            {/* Phone Number */}
            <div className="space-y-2">
              <Label htmlFor="phone_number">Phone Number</Label>
              <Input
                id="phone_number"
                type="tel"
                {...register('phone_number')}
                placeholder="Optional"
              />
            </div>

            {/* Role */}
            <div className="space-y-2">
              <Label htmlFor="role">Role</Label>
              <Select value={role} onValueChange={(value) => setValue('role', value as UserRole)}>
                <SelectTrigger>
                  <SelectValue placeholder="Select role" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="student">Student</SelectItem>
                  <SelectItem value="lab_staff">Lab Staff</SelectItem>
                  <SelectItem value="instructor">Instructor</SelectItem>
                  <SelectItem value="lab_manager">Lab Manager</SelectItem>
                  <SelectItem value="admin">Admin</SelectItem>
                  <SelectItem value="super_admin">Super Admin</SelectItem>
                </SelectContent>
              </Select>
              {errors.role && (
                <p className="text-sm text-destructive">{errors.role.message}</p>
              )}
            </div>

            {/* Department */}
            <div className="space-y-2">
              <Label htmlFor="department">Department</Label>
              <Select value={watch('department')} onValueChange={(value) => setValue('department', value)}>
                <SelectTrigger>
                  <SelectValue placeholder="Select department" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="">No department</SelectItem>
                  {DEPARTMENTS.map((dept) => (
                    <SelectItem key={dept} value={dept}>
                      {dept}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* Employee ID */}
            {role && role !== 'student' && (
              <div className="space-y-2">
                <Label htmlFor="employee_id">Employee ID</Label>
                <Input
                  id="employee_id"
                  {...register('employee_id')}
                  placeholder="Optional"
                />
              </div>
            )}

            {/* Student ID */}
            {role === 'student' && (
              <div className="space-y-2">
                <Label htmlFor="student_id">Student ID</Label>
                <Input
                  id="student_id"
                  {...register('student_id')}
                  placeholder="Optional"
                />
              </div>
            )}

            {/* Account Status */}
            <div className="space-y-2">
              <Label htmlFor="is_active">Account Status</Label>
              <Select 
                value={watch('is_active') ? 'active' : 'inactive'} 
                onValueChange={(value) => setValue('is_active', value === 'active')}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="active">Active</SelectItem>
                  <SelectItem value="inactive">Inactive</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={handleCancel}
              disabled={isLoading}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={isLoading}>
              {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              Update User
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
