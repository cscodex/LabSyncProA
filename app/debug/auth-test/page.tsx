'use client';

import { useState, useEffect } from 'react';
import { createSupabaseClient } from '@/lib/supabase';
import { useAuth } from '@/contexts/auth-context';

export default function AuthTestPage() {
  const [session, setSession] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const { user, loading: authLoading } = useAuth();
  const supabase = createSupabaseClient();

  useEffect(() => {
    const getSession = async () => {
      const { data: { session }, error } = await supabase.auth.getSession();
      console.log('Session check:', { session, error });
      setSession(session);
      setLoading(false);
    };

    getSession();

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      console.log('Auth state change:', event, session);
      setSession(session);
    });

    return () => subscription.unsubscribe();
  }, [supabase]);

  const testLogin = async () => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email: 'test@example.com',
      password: 'testpassword123'
    });
    console.log('Login test:', { data, error });
  };

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Auth Debug Page</h1>
      
      <div className="space-y-4">
        <div>
          <h2 className="text-lg font-semibold">Session Status</h2>
          <p>Loading: {loading ? 'Yes' : 'No'}</p>
          <p>Session exists: {session ? 'Yes' : 'No'}</p>
          <p>User email: {session?.user?.email || 'None'}</p>
        </div>

        <div>
          <h2 className="text-lg font-semibold">Auth Context Status</h2>
          <p>Auth Loading: {authLoading ? 'Yes' : 'No'}</p>
          <p>Auth User: {user ? user.email : 'None'}</p>
          <p>Auth User Role: {user?.role || 'None'}</p>
        </div>

        <div>
          <h2 className="text-lg font-semibold">Raw Data</h2>
          <pre className="bg-gray-100 p-4 rounded text-sm overflow-auto">
            {JSON.stringify({ session, user }, null, 2)}
          </pre>
        </div>

        <button 
          onClick={testLogin}
          className="bg-blue-500 text-white px-4 py-2 rounded"
        >
          Test Login
        </button>
      </div>
    </div>
  );
}
