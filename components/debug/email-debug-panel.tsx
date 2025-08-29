'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';

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
          {isLoading && <span className="mr-2">⏳</span>}
          Refresh Debug Info
        </Button>
      </div>

      {/* Environment Info */}
      {debugInfo && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              ⚙️ Environment Configuration
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="font-medium">NODE_ENV</p>
                <span className={`px-2 py-1 rounded text-xs ${debugInfo.environment.NODE_ENV === 'production' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'}`}>
                  {debugInfo.environment.NODE_ENV}
                </span>
              </div>
              <div>
                <p className="font-medium">Site URL</p>
                <span className={`px-2 py-1 rounded text-xs ${debugInfo.environment.NEXT_PUBLIC_SITE_URL ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                  {debugInfo.environment.NEXT_PUBLIC_SITE_URL || 'Missing'}
                </span>
              </div>
              <div>
                <p className="font-medium">Supabase URL</p>
                <span className={`px-2 py-1 rounded text-xs ${debugInfo.environment.NEXT_PUBLIC_SUPABASE_URL ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                  {debugInfo.environment.NEXT_PUBLIC_SUPABASE_URL ? 'Set' : 'Missing'}
                </span>
              </div>
              <div>
                <p className="font-medium">Anon Key</p>
                <span className={`px-2 py-1 rounded text-xs ${debugInfo.environment.NEXT_PUBLIC_SUPABASE_ANON_KEY === 'Set' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                  {debugInfo.environment.NEXT_PUBLIC_SUPABASE_ANON_KEY}
                </span>
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
              📧 Email Status
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
              🗄️ Recent Users
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
                      <span className="px-2 py-1 rounded text-xs bg-green-100 text-green-800 flex items-center gap-1">
                        ✓ Confirmed
                      </span>
                    ) : (
                      <span className="px-2 py-1 rounded text-xs bg-yellow-100 text-yellow-800 flex items-center gap-1">
                        ⏳ Pending
                      </span>
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
