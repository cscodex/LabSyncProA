'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Loader2, Mail, Database, Settings, CheckCircle, XCircle, Clock } from 'lucide-react';

interface DebugInfo {
  timestamp: string;
  environment: any;
  database: any;
  emailStatus: any;
}

export function EmailDebugPanel() {
  const [debugInfo, setDebugInfo] = useState<DebugInfo | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [testEmail, setTestEmail] = useState('');
  const [testResult, setTestResult] = useState<any>(null);

  const fetchDebugInfo = async () => {
    setIsLoading(true);
    try {
      const response = await fetch('/api/debug/email');
      const data = await response.json();
      setDebugInfo(data);
    } catch (error) {
      console.error('Failed to fetch debug info:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const testEmailFunction = async (action: string) => {
    if (!testEmail) return;
    
    setIsLoading(true);
    try {
      const response = await fetch('/api/debug/email', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: testEmail, action }),
      });
      const data = await response.json();
      setTestResult({ action, ...data });
    } catch (error) {
      console.error('Test failed:', error);
      setTestResult({ action, error: 'Test failed' });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold">Email Debug Panel</h2>
        <Button onClick={fetchDebugInfo} disabled={isLoading}>
          {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
          Refresh Debug Info
        </Button>
      </div>

      {/* Environment Info */}
      {debugInfo && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Settings className="h-5 w-5" />
              Environment Configuration
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="font-medium">NODE_ENV</p>
                <Badge variant={debugInfo.environment.NODE_ENV === 'production' ? 'default' : 'secondary'}>
                  {debugInfo.environment.NODE_ENV}
                </Badge>
              </div>
              <div>
                <p className="font-medium">Site URL</p>
                <Badge variant={debugInfo.environment.NEXT_PUBLIC_SITE_URL ? 'default' : 'destructive'}>
                  {debugInfo.environment.NEXT_PUBLIC_SITE_URL || 'Missing'}
                </Badge>
              </div>
              <div>
                <p className="font-medium">Supabase URL</p>
                <Badge variant={debugInfo.environment.NEXT_PUBLIC_SUPABASE_URL ? 'default' : 'destructive'}>
                  {debugInfo.environment.NEXT_PUBLIC_SUPABASE_URL ? 'Set' : 'Missing'}
                </Badge>
              </div>
              <div>
                <p className="font-medium">Anon Key</p>
                <Badge variant={debugInfo.environment.NEXT_PUBLIC_SUPABASE_ANON_KEY === 'Set' ? 'default' : 'destructive'}>
                  {debugInfo.environment.NEXT_PUBLIC_SUPABASE_ANON_KEY}
                </Badge>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Email Status */}
      {debugInfo && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Mail className="h-5 w-5" />
              Email Status
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-4 gap-4">
              <div className="text-center">
                <p className="text-2xl font-bold">{debugInfo.emailStatus.totalUsers}</p>
                <p className="text-sm text-muted-foreground">Total Users</p>
              </div>
              <div className="text-center">
                <p className="text-2xl font-bold text-green-600">{debugInfo.emailStatus.confirmedUsers}</p>
                <p className="text-sm text-muted-foreground">Confirmed</p>
              </div>
              <div className="text-center">
                <p className="text-2xl font-bold text-yellow-600">{debugInfo.emailStatus.pendingUsers}</p>
                <p className="text-sm text-muted-foreground">Pending</p>
              </div>
              <div className="text-center">
                <p className="text-2xl font-bold text-blue-600">{debugInfo.emailStatus.recentRecovery}</p>
                <p className="text-sm text-muted-foreground">Recent Recovery</p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Recent Users */}
      {debugInfo && debugInfo.database.authUsers && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Database className="h-5 w-5" />
              Recent Users
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {debugInfo.database.authUsers.map((user: any, index: number) => (
                <div key={index} className="flex items-center justify-between p-2 border rounded">
                  <div>
                    <p className="font-medium">{user.email}</p>
                    <p className="text-sm text-muted-foreground">
                      Created: {new Date(user.created_at).toLocaleString()}
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    {user.email_confirmed_at ? (
                      <Badge variant="default" className="flex items-center gap-1">
                        <CheckCircle className="h-3 w-3" />
                        Confirmed
                      </Badge>
                    ) : (
                      <Badge variant="secondary" className="flex items-center gap-1">
                        <Clock className="h-3 w-3" />
                        Pending
                      </Badge>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Test Email Functions */}
      <Card>
        <CardHeader>
          <CardTitle>Test Email Functions</CardTitle>
          <CardDescription>
            Test email verification and password reset with a specific email
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex gap-2">
            <Input
              placeholder="Enter email to test"
              value={testEmail}
              onChange={(e) => setTestEmail(e.target.value)}
            />
            <Button onClick={() => testEmailFunction('check_user')} disabled={isLoading || !testEmail}>
              Check User
            </Button>
          </div>
          
          <div className="flex gap-2">
            <Button 
              onClick={() => testEmailFunction('test_registration')} 
              disabled={isLoading || !testEmail}
              variant="outline"
            >
              Test Registration
            </Button>
            <Button 
              onClick={() => testEmailFunction('test_password_reset')} 
              disabled={isLoading || !testEmail}
              variant="outline"
            >
              Test Password Reset
            </Button>
          </div>

          {testResult && (
            <Alert>
              <AlertDescription>
                <strong>{testResult.action}:</strong> {JSON.stringify(testResult, null, 2)}
              </AlertDescription>
            </Alert>
          )}
        </CardContent>
      </Card>

      {/* Instructions */}
      <Card>
        <CardHeader>
          <CardTitle>Debug Instructions</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2 text-sm">
            <p><strong>1. Check Render Logs:</strong> Go to Render Dashboard → Your Service → Logs</p>
            <p><strong>2. Look for:</strong> Lines starting with "🔍 EMAIL_DEBUG:" or "📧 EMAIL_DEBUG:"</p>
            <p><strong>3. Test Registration:</strong> Try registering with a new email and watch logs</p>
            <p><strong>4. Test Password Reset:</strong> Try password reset and watch logs</p>
            <p><strong>5. Check Gmail:</strong> Verify emails are being sent to your Gmail inbox</p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
