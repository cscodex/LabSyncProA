'use client';

import Link from 'next/link';
import { ThemeToggle } from '@/components/theme-toggle';
import { ProfileDropdown } from './profile-dropdown';

interface DashboardHeaderProps {
  title?: string;
}

export function DashboardHeader({ title }: DashboardHeaderProps) {
  return (
    <header className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container mx-auto px-4 py-4 flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <Link href="/dashboard" className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
              <span className="text-primary-foreground font-bold text-lg">L</span>
            </div>
            <span className="text-2xl font-bold text-primary">LabSyncPro</span>
          </Link>
          {title && (
            <>
              <span className="text-muted-foreground">/</span>
              <span className="text-lg font-medium">{title}</span>
            </>
          )}
        </div>
        
        <div className="flex items-center space-x-4">
          <ThemeToggle />
          <ProfileDropdown />
        </div>
      </div>
    </header>
  );
}
