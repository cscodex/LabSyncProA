'use client';

import { useMemo } from 'react';
import { Progress } from '@/components/ui/progress';
import { calculatePasswordStrength } from '@/lib/validations/auth';
import { cn } from '@/lib/utils';

interface PasswordStrengthProps {
  password: string;
  className?: string;
}

export function PasswordStrength({ password, className }: PasswordStrengthProps) {
  const strength = useMemo(() => calculatePasswordStrength(password), [password]);

  const getStrengthText = (score: number) => {
    switch (score) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Strong';
      default:
        return 'Very Weak';
    }
  };

  const getStrengthColor = (score: number) => {
    switch (score) {
      case 0:
      case 1:
        return 'text-red-600 dark:text-red-400';
      case 2:
        return 'text-orange-600 dark:text-orange-400';
      case 3:
        return 'text-yellow-600 dark:text-yellow-400';
      case 4:
        return 'text-blue-600 dark:text-blue-400';
      case 5:
        return 'text-green-600 dark:text-green-400';
      default:
        return 'text-gray-400';
    }
  };

  const getProgressColor = (score: number) => {
    switch (score) {
      case 0:
      case 1:
        return 'password-strength-very-weak';
      case 2:
        return 'password-strength-weak';
      case 3:
        return 'password-strength-fair';
      case 4:
        return 'password-strength-good';
      case 5:
        return 'password-strength-strong';
      default:
        return 'bg-gray-300';
    }
  };

  if (!password) return null;

  return (
    <div className={cn("space-y-2", className)}>
      <div className="flex justify-between text-sm">
        <span className="text-muted-foreground">Password Strength</span>
        <span className={cn("font-medium", getStrengthColor(strength.score))}>
          {getStrengthText(strength.score)}
        </span>
      </div>
      
      <div className="relative">
        <Progress 
          value={(strength.score / 5) * 100} 
          className="h-2"
        />
        <div 
          className={cn(
            "absolute top-0 left-0 h-2 rounded-full transition-all duration-300",
            getProgressColor(strength.score)
          )}
          style={{ width: `${(strength.score / 5) * 100}%` }}
        />
      </div>
      
      {strength.feedback.length > 0 && (
        <div className="text-xs text-muted-foreground space-y-1">
          <div className="font-medium">Requirements:</div>
          <div className="grid grid-cols-1 gap-1">
            <span className={password.length >= 8 ? 'text-green-600 dark:text-green-400' : 'text-muted-foreground'}>
              ✓ At least 8 characters
            </span>
            <span className={/[A-Z]/.test(password) ? 'text-green-600 dark:text-green-400' : 'text-muted-foreground'}>
              ✓ One uppercase letter
            </span>
            <span className={/[a-z]/.test(password) ? 'text-green-600 dark:text-green-400' : 'text-muted-foreground'}>
              ✓ One lowercase letter
            </span>
            <span className={/[0-9]/.test(password) ? 'text-green-600 dark:text-green-400' : 'text-muted-foreground'}>
              ✓ One number
            </span>
            <span className={/[^A-Za-z0-9]/.test(password) ? 'text-green-600 dark:text-green-400' : 'text-muted-foreground'}>
              ✓ One special character
            </span>
          </div>
        </div>
      )}
    </div>
  );
}
