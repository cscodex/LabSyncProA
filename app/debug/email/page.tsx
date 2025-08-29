import { EmailDebugPanel } from '@/components/debug/email-debug-panel';

export default function EmailDebugPage() {
  return (
    <div className="min-h-screen bg-background">
      <div className="container mx-auto py-8">
        <EmailDebugPanel />
      </div>
    </div>
  );
}
