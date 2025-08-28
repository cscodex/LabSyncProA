# Enable Email Verification in Supabase

## Step 1: Configure Supabase Authentication Settings

1. **Go to your Supabase Dashboard**
   - Navigate to: https://supabase.com/dashboard/project/jpdkzugjxinxzpdxbiss

2. **Go to Authentication → Settings**
   - Click on "Authentication" in the left sidebar
   - Click on "Settings" tab

3. **Enable Email Confirmations**
   - Find "User Management" section
   - Toggle ON: **"Enable email confirmations"**
   - Toggle ON: **"Confirm email change"**
   - Toggle ON: **"Secure email change"**

4. **Configure Site URL**
   - In "URL Configuration" section
   - Set **Site URL**: `http://localhost:3001` (for development)
   - For production, use: `https://your-domain.com`

5. **Add Redirect URLs**
   - Add these redirect URLs:
     ```
     http://localhost:3000/auth/callback
     http://localhost:3001/auth/callback
     https://your-domain.com/auth/callback
     ```

## Step 2: Configure Email Templates

1. **Go to Authentication → Email Templates**

2. **Customize "Confirm signup" template:**
   ```html
   <h2>Welcome to LabSyncPro!</h2>
   <p>Thank you for signing up. Please click the link below to verify your email address and activate your account:</p>
   <p><a href="{{ .ConfirmationURL }}" style="display: inline-block; padding: 12px 24px; background-color: #3b82f6; color: white; text-decoration: none; border-radius: 5px;">Verify Email Address</a></p>
   <p>If the button doesn't work, copy and paste this link into your browser:</p>
   <p style="word-break: break-all;">{{ .ConfirmationURL }}</p>
   <p>This verification link will expire in 24 hours for security reasons.</p>
   <p>If you didn't create an account with LabSyncPro, please ignore this email.</p>
   <p>Best regards,<br>The LabSyncPro Team</p>
   ```

3. **Update "Reset password" template:**
   ```html
   <h2>Reset Your LabSyncPro Password</h2>
   <p>You requested to reset your password. Click the link below to create a new password:</p>
   <p><a href="{{ .ConfirmationURL }}" style="display: inline-block; padding: 12px 24px; background-color: #3b82f6; color: white; text-decoration: none; border-radius: 5px;">Reset Password</a></p>
   <p>If the button doesn't work, copy and paste this link into your browser:</p>
   <p style="word-break: break-all;">{{ .ConfirmationURL }}</p>
   <p>This link will expire in 1 hour for security reasons.</p>
   <p>If you didn't request this password reset, please ignore this email.</p>
   <p>Best regards,<br>The LabSyncPro Team</p>
   ```

## Step 3: Set Up Custom SMTP (Recommended)

### Option A: Gmail Setup (Development)

1. **Create Gmail Account**
   - Create: `noreply.labsyncpro@gmail.com`
   - Enable 2-Factor Authentication

2. **Generate App Password**
   - Go to Google Account → Security → 2-Step Verification → App passwords
   - Generate password for "Mail"

3. **Configure in Supabase**
   - Go to Settings → Auth → SMTP Settings
   - Enable custom SMTP:
     ```
     Host: smtp.gmail.com
     Port: 587
     Username: noreply.labsyncpro@gmail.com
     Password: [your-app-password]
     Sender email: noreply.labsyncpro@gmail.com
     Sender name: LabSyncPro
     ```

### Option B: SendGrid Setup (Production)

1. **Create SendGrid Account**
   - Sign up at: https://sendgrid.com/

2. **Verify Domain**
   - Add your domain and verify DNS records

3. **Create API Key**
   - Generate API key with Mail Send permissions

4. **Configure in Supabase**
   ```
   Host: smtp.sendgrid.net
   Port: 587
   Username: apikey
   Password: [your-sendgrid-api-key]
   Sender email: noreply@yourdomain.com
   Sender name: LabSyncPro
   ```

## Step 4: Test Email Verification

1. **Register a new account** with your email
2. **Check your email** for verification message
3. **Click the verification link**
4. **Verify you're redirected** to the app and logged in

## Step 5: Configure Google OAuth Provider

Since you have Google OAuth credentials, let's enable it:

1. **Go to Authentication → Providers**
2. **Find "Google" and toggle it ON**
3. **Enter your credentials:**
   - **Client ID**: `your_google_client_id_here`
   - **Client Secret**: `your_google_client_secret_here`
4. **Click "Save"**

## Step 6: Update Google Cloud Console

1. **Go to Google Cloud Console**
   - Navigate to: https://console.cloud.google.com/

2. **Go to APIs & Services → Credentials**

3. **Edit your OAuth 2.0 Client ID**

4. **Add Authorized redirect URIs:**
   ```
   https://jpdkzugjxinxzpdxbiss.supabase.co/auth/v1/callback
   ```

5. **Add Authorized JavaScript origins:**
   ```
   http://localhost:3001
   https://jpdkzugjxinxzpdxbiss.supabase.co
   ```

## Step 7: Test Complete Flow

### Test Email Registration:
1. Go to: http://localhost:3001/auth/register
2. Register with email/password
3. Check email for verification
4. Click verification link
5. Should redirect to dashboard

### Test Google OAuth:
1. Go to: http://localhost:3001/auth/login
2. Click "Continue with Google"
3. Complete OAuth flow
4. Should create profile and redirect to complete-profile page

## Troubleshooting

### Email Not Received:
- Check spam/junk folder
- Verify SMTP configuration
- Check Supabase logs

### Google OAuth Not Working:
- Verify redirect URIs in Google Console
- Check client ID/secret in Supabase
- Ensure provider is enabled

### Verification Link Not Working:
- Check site URL configuration
- Verify redirect URLs
- Ensure HTTPS in production

## Security Notes

1. **Never commit credentials** to version control
2. **Use environment variables** for all secrets
3. **Enable rate limiting** in production
4. **Monitor authentication logs** regularly
5. **Set up proper CORS** policies

---

After completing these steps:
- ✅ Email verification will be required for all new accounts
- ✅ Google OAuth will work with profile completion flow
- ✅ Professional email templates will be used
- ✅ Users will be guided through proper onboarding
