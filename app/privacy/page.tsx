import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { ThemeToggle } from '@/components/theme-toggle';

export default function PrivacyPage() {
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
            <Link href="/">
              <Button variant="outline">
                <ArrowLeft className="mr-2 h-4 w-4" />
                Back to Home
              </Button>
            </Link>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8 max-w-4xl">
        <Card>
          <CardHeader>
            <CardTitle className="text-3xl">Privacy Policy</CardTitle>
            <p className="text-muted-foreground">Last updated: December 2024</p>
          </CardHeader>
          <CardContent className="prose prose-gray dark:prose-invert max-w-none">
            <h2>1. Introduction</h2>
            <p>
              LabSyncPro ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our laboratory management system.
            </p>

            <h2>2. Information We Collect</h2>
            
            <h3>Personal Information</h3>
            <p>We may collect the following personal information:</p>
            <ul>
              <li>Name, email address, and contact information</li>
              <li>Student ID or Employee ID</li>
              <li>Department and role information</li>
              <li>Profile pictures (optional)</li>
              <li>Academic records and grades</li>
              <li>Laboratory activity and usage data</li>
            </ul>

            <h3>Technical Information</h3>
            <ul>
              <li>IP address and device information</li>
              <li>Browser type and version</li>
              <li>Usage patterns and preferences</li>
              <li>Log files and system activity</li>
            </ul>

            <h2>3. How We Use Your Information</h2>
            <p>We use the collected information for:</p>
            <ul>
              <li>Providing and maintaining the Service</li>
              <li>Managing user accounts and authentication</li>
              <li>Facilitating laboratory operations and scheduling</li>
              <li>Tracking academic progress and generating reports</li>
              <li>Communicating with users about the Service</li>
              <li>Improving our services and user experience</li>
              <li>Ensuring security and preventing fraud</li>
            </ul>

            <h2>4. Information Sharing and Disclosure</h2>
            <p>We may share your information in the following circumstances:</p>
            
            <h3>Within Your Institution</h3>
            <ul>
              <li>With instructors and staff for educational purposes</li>
              <li>With administrators for institutional reporting</li>
              <li>With IT support for technical assistance</li>
            </ul>

            <h3>Legal Requirements</h3>
            <ul>
              <li>To comply with legal obligations</li>
              <li>To protect our rights and safety</li>
              <li>In response to lawful requests by public authorities</li>
            </ul>

            <h3>Service Providers</h3>
            <ul>
              <li>Third-party services that help us operate the platform</li>
              <li>Cloud hosting and storage providers</li>
              <li>Analytics and monitoring services</li>
            </ul>

            <h2>5. Data Security</h2>
            <p>We implement appropriate security measures to protect your information:</p>
            <ul>
              <li>Encryption of data in transit and at rest</li>
              <li>Regular security assessments and updates</li>
              <li>Access controls and authentication mechanisms</li>
              <li>Employee training on data protection</li>
              <li>Incident response procedures</li>
            </ul>

            <h2>6. Data Retention</h2>
            <p>
              We retain your information for as long as necessary to provide the Service and fulfill the purposes outlined in this policy. Academic records may be retained according to institutional policies and legal requirements.
            </p>

            <h2>7. Your Rights and Choices</h2>
            <p>You have the right to:</p>
            <ul>
              <li>Access and review your personal information</li>
              <li>Request corrections to inaccurate data</li>
              <li>Request deletion of your account and data</li>
              <li>Opt-out of non-essential communications</li>
              <li>Export your data in a portable format</li>
            </ul>

            <h2>8. Cookies and Tracking</h2>
            <p>
              We use cookies and similar technologies to enhance your experience, analyze usage patterns, and provide personalized content. You can control cookie settings through your browser preferences.
            </p>

            <h2>9. Third-Party Services</h2>
            <p>Our Service may integrate with third-party services:</p>
            <ul>
              <li>Google OAuth for authentication</li>
              <li>Apple Sign-In for authentication</li>
              <li>Supabase for data storage and management</li>
              <li>Analytics services for usage monitoring</li>
            </ul>
            <p>
              These services have their own privacy policies, and we encourage you to review them.
            </p>

            <h2>10. Children's Privacy</h2>
            <p>
              Our Service is designed for educational institutions and may be used by students under 18. We comply with applicable laws regarding children's privacy, including COPPA and FERPA requirements.
            </p>

            <h2>11. International Data Transfers</h2>
            <p>
              Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your data during such transfers.
            </p>

            <h2>12. Changes to This Privacy Policy</h2>
            <p>
              We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last updated" date.
            </p>

            <h2>13. Contact Us</h2>
            <p>
              If you have any questions about this Privacy Policy or our data practices, please contact us:
            </p>
            <ul>
              <li>Email: privacy@labsyncpro.com</li>
              <li>Address: [Your Institution Address]</li>
              <li>Phone: [Your Contact Number]</li>
            </ul>

            <h2>14. Compliance</h2>
            <p>
              We are committed to compliance with applicable privacy laws and regulations, including:
            </p>
            <ul>
              <li>General Data Protection Regulation (GDPR)</li>
              <li>Family Educational Rights and Privacy Act (FERPA)</li>
              <li>Children's Online Privacy Protection Act (COPPA)</li>
              <li>California Consumer Privacy Act (CCPA)</li>
            </ul>
          </CardContent>
        </Card>
      </main>
    </div>
  );
}
