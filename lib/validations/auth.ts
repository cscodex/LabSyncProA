import { z } from 'zod';
import { DEPARTMENTS } from '@/types/auth.types';

// Password validation schema
const passwordSchema = z
  .string()
  .min(8, 'Password must be at least 8 characters')
  .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
  .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
  .regex(/[0-9]/, 'Password must contain at least one number')
  .regex(/[^A-Za-z0-9]/, 'Password must contain at least one special character');

// Email validation schema
const emailSchema = z
  .string()
  .email('Please enter a valid email address')
  .min(1, 'Email is required');

// Name validation schema
const nameSchema = z
  .string()
  .min(2, 'Must be at least 2 characters')
  .max(50, 'Must be less than 50 characters')
  .regex(/^[a-zA-Z\s'-]+$/, 'Only letters, spaces, hyphens, and apostrophes are allowed');

// Phone number validation schema
const phoneSchema = z
  .string()
  .regex(/^[\+]?[1-9][\d]{0,15}$/, 'Please enter a valid phone number')
  .optional()
  .or(z.literal(''));

// Employee/Student ID validation schema
const idSchema = z
  .string()
  .min(3, 'ID must be at least 3 characters')
  .max(20, 'ID must be less than 20 characters')
  .regex(/^[A-Za-z0-9-_]+$/, 'ID can only contain letters, numbers, hyphens, and underscores')
  .optional()
  .or(z.literal(''));

// Login form validation
export const loginSchema = z.object({
  email: emailSchema,
  password: z.string().min(1, 'Password is required'),
  rememberMe: z.boolean().optional(),
});

// Registration form validation
export const registerSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
  confirmPassword: z.string(),
  firstName: nameSchema,
  lastName: nameSchema,
  role: z.enum(['super_admin', 'admin', 'lab_manager', 'instructor', 'student', 'lab_staff']),
  department: z.enum([...DEPARTMENTS, '']).optional(),
  employeeId: idSchema,
  studentId: idSchema,
  phoneNumber: phoneSchema,
  acceptTerms: z.boolean().refine(val => val === true, {
    message: 'You must accept the terms and conditions',
  }),
}).refine(data => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ["confirmPassword"],
}).refine(data => {
  // Validate role-specific required fields
  if (['super_admin', 'admin', 'lab_manager', 'instructor', 'lab_staff'].includes(data.role)) {
    return data.employeeId && data.employeeId.length > 0;
  }
  if (data.role === 'student') {
    return data.studentId && data.studentId.length > 0;
  }
  return true;
}, {
  message: 'Employee ID is required for staff roles, Student ID is required for students',
  path: ['employeeId'],
});

// Password reset form validation
export const resetPasswordSchema = z.object({
  email: emailSchema,
});

// Update password form validation
export const updatePasswordSchema = z.object({
  password: passwordSchema,
  confirmPassword: z.string(),
}).refine(data => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ["confirmPassword"],
});

// Profile completion form validation
export const profileCompletionSchema = z.object({
  firstName: nameSchema,
  lastName: nameSchema,
  role: z.enum(['super_admin', 'admin', 'lab_manager', 'instructor', 'student', 'lab_staff']),
  department: z.enum([...DEPARTMENTS, '']).optional(),
  employeeId: idSchema,
  studentId: idSchema,
  phoneNumber: phoneSchema,
}).refine(data => {
  // Validate role-specific required fields
  if (['super_admin', 'admin', 'lab_manager', 'instructor', 'lab_staff'].includes(data.role)) {
    return data.employeeId && data.employeeId.length > 0;
  }
  if (data.role === 'student') {
    return data.studentId && data.studentId.length > 0;
  }
  return true;
}, {
  message: 'Employee ID is required for staff roles, Student ID is required for students',
  path: ['employeeId'],
});

// Profile update form validation
export const profileUpdateSchema = z.object({
  firstName: nameSchema,
  lastName: nameSchema,
  department: z.enum([...DEPARTMENTS, '']).optional(),
  phoneNumber: phoneSchema,
});

// Change email form validation
export const changeEmailSchema = z.object({
  newEmail: emailSchema,
  password: z.string().min(1, 'Current password is required'),
});

// Two-factor authentication setup validation
export const twoFactorSetupSchema = z.object({
  code: z.string().length(6, 'Code must be 6 digits').regex(/^\d+$/, 'Code must contain only numbers'),
});

// Password strength calculation
export const calculatePasswordStrength = (password: string) => {
  let score = 0;
  const feedback: string[] = [];

  // Length check
  if (password.length >= 8) {
    score += 1;
  } else {
    feedback.push('Use at least 8 characters');
  }

  // Uppercase check
  if (/[A-Z]/.test(password)) {
    score += 1;
  } else {
    feedback.push('Add uppercase letters');
  }

  // Lowercase check
  if (/[a-z]/.test(password)) {
    score += 1;
  } else {
    feedback.push('Add lowercase letters');
  }

  // Number check
  if (/[0-9]/.test(password)) {
    score += 1;
  } else {
    feedback.push('Add numbers');
  }

  // Special character check
  if (/[^A-Za-z0-9]/.test(password)) {
    score += 1;
  } else {
    feedback.push('Add special characters');
  }

  return {
    score,
    feedback,
    isValid: score >= 5,
  };
};

// Export DEPARTMENTS for use in components
export { DEPARTMENTS } from '@/types/auth.types';

// Export types for form data
export type LoginFormData = z.infer<typeof loginSchema>;
export type RegisterFormData = z.infer<typeof registerSchema>;
export type ResetPasswordFormData = z.infer<typeof resetPasswordSchema>;
export type UpdatePasswordFormData = z.infer<typeof updatePasswordSchema>;
export type ProfileCompletionFormData = z.infer<typeof profileCompletionSchema>;
export type ProfileUpdateFormData = z.infer<typeof profileUpdateSchema>;
export type ChangeEmailFormData = z.infer<typeof changeEmailSchema>;
export type TwoFactorSetupFormData = z.infer<typeof twoFactorSetupSchema>;
