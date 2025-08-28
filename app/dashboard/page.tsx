'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Loader2, LogOut, User } from 'lucide-react';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { ThemeToggle } from '@/components/theme-toggle';
import { useAuth } from '@/contexts/auth-context';
import { formatUserName, formatRole } from '@/lib/utils';

export default function DashboardPage() {
  const { user, loading, signOut } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading && !user) {
      router.push('/auth/login');
    }
  }, [user, loading, router]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center space-y-4">
          <Loader2 className="h-8 w-8 animate-spin mx-auto" />
          <p className="text-muted-foreground">Loading...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return null;
  }

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
              <span className="text-primary-foreground font-bold text-lg">L</span>
            </div>
            <span className="text-2xl font-bold text-primary">LabSyncPro</span>
          </div>
          
          <div className="flex items-center space-x-4">
            <ThemeToggle />
            <Button variant="outline" onClick={signOut}>
              <LogOut className="h-4 w-4 mr-2" />
              Sign Out
            </Button>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        <div className="space-y-6">
          <div>
            <h1 className="text-3xl font-bold">
              Welcome back, {formatUserName(user.first_name, user.last_name)}!
            </h1>
            <p className="text-muted-foreground">
              {formatRole(user.role)} • {user.department || 'No department assigned'}
            </p>
          </div>

          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Profile Information</CardTitle>
                <User className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  <div>
                    <p className="text-sm font-medium">Email</p>
                    <p className="text-sm text-muted-foreground">{user.email}</p>
                  </div>
                  <div>
                    <p className="text-sm font-medium">Role</p>
                    <p className="text-sm text-muted-foreground">{formatRole(user.role)}</p>
                  </div>
                  {user.employee_id && (
                    <div>
                      <p className="text-sm font-medium">Employee ID</p>
                      <p className="text-sm text-muted-foreground">{user.employee_id}</p>
                    </div>
                  )}
                  {user.student_id && (
                    <div>
                      <p className="text-sm font-medium">Student ID</p>
                      <p className="text-sm text-muted-foreground">{user.student_id}</p>
                    </div>
                  )}
                  {user.phone_number && (
                    <div>
                      <p className="text-sm font-medium">Phone</p>
                      <p className="text-sm text-muted-foreground">{user.phone_number}</p>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Quick Actions</CardTitle>
                <CardDescription>
                  Common tasks based on your role
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-2">
                {user.role === 'student' && (
                  <>
                    <Button variant="outline" className="w-full justify-start">
                      View My Sessions
                    </Button>
                    <Button variant="outline" className="w-full justify-start">
                      Submit Assignment
                    </Button>
                    <Button variant="outline" className="w-full justify-start">
                      Check Grades
                    </Button>
                  </>
                )}
                
                {['instructor', 'lab_manager', 'admin'].includes(user.role) && (
                  <>
                    <Button variant="outline" className="w-full justify-start">
                      Manage Equipment
                    </Button>
                    <Button variant="outline" className="w-full justify-start">
                      Schedule Sessions
                    </Button>
                    <Button variant="outline" className="w-full justify-start">
                      View Reports
                    </Button>
                  </>
                )}
                
                {user.role === 'lab_staff' && (
                  <>
                    <Button variant="outline" className="w-full justify-start">
                      Equipment Check-in/out
                    </Button>
                    <Button variant="outline" className="w-full justify-start">
                      Maintenance Log
                    </Button>
                    <Button variant="outline" className="w-full justify-start">
                      Inventory Status
                    </Button>
                  </>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>System Status</CardTitle>
                <CardDescription>
                  Current system information
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-2">
                <div className="flex justify-between">
                  <span className="text-sm">Authentication</span>
                  <span className="text-sm text-green-600">✓ Active</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm">Database</span>
                  <span className="text-sm text-green-600">✓ Connected</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm">Profile</span>
                  <span className="text-sm text-green-600">✓ Complete</span>
                </div>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>Getting Started</CardTitle>
              <CardDescription>
                Welcome to LabSyncPro! Here's what you can do next:
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <h4 className="font-medium">For Students:</h4>
                  <ul className="text-sm text-muted-foreground space-y-1">
                    <li>• View your scheduled practical sessions</li>
                    <li>• Submit assignments and lab reports</li>
                    <li>• Check your grades and feedback</li>
                    <li>• Access lab resources and materials</li>
                  </ul>
                </div>
                <div className="space-y-2">
                  <h4 className="font-medium">For Staff:</h4>
                  <ul className="text-sm text-muted-foreground space-y-1">
                    <li>• Manage laboratory equipment and inventory</li>
                    <li>• Schedule and conduct practical sessions</li>
                    <li>• Track student attendance and progress</li>
                    <li>• Generate reports and analytics</li>
                  </ul>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  );
}
