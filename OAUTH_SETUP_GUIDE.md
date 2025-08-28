# OAuth Configuration Guide for LabSyncPro

This guide will help you set up Google and Apple OAuth authentication for your LabSyncPro application.

## Prerequisites

- ✅ Supabase project created
- ✅ LabSyncPro deployed (or running locally)
- ✅ Domain/URL for your application

## Step 1: Configure Google OAuth

### 1.1 Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the Google+ API:
   - Go to "APIs & Services" → "Library"
   - Search for "Google+ API" and enable it

### 1.2 Create OAuth 2.0 Credentials

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth 2.0 Client IDs"
3. Configure the consent screen first if prompted:
   - Choose "External" user type
   - Fill in app name: "LabSyncPro"
   - Add your email as developer contact
   - Add scopes: `email`, `profile`, `openid`

4. Create OAuth 2.0 Client ID:
   - Application type: "Web application"
   - Name: "LabSyncPro Web Client"
   - Authorized JavaScript origins:
     ```
     http://localhost:3000
     http://localhost:3001
     https://your-domain.com
     https://jpdkzugjxinxzpdxbiss.supabase.co
     ```
   - Authorized redirect URIs:
     ```
     http://localhost:3000/auth/callback
     http://localhost:3001/auth/callback
     https://your-domain.com/auth/callback
     https://jpdkzugjxinxzpdxbiss.supabase.co/auth/v1/callback
     ```

5. Save the Client ID and Client Secret

### 1.3 Configure in Supabase

1. Go to your Supabase dashboard
2. Navigate to "Authentication" → "Providers"
3. Find "Google" and toggle it ON
4. Enter your credentials:
   - **Client ID**: Your Google Client ID
   - **Client Secret**: Your Google Client Secret
5. Click "Save"

### 1.4 Update Environment Variables

Add to your `.env.local`:
```env
NEXT_PUBLIC_GOOGLE_CLIENT_ID=your_google_client_id_here
GOOGLE_CLIENT_SECRET=your_google_client_secret_here
```

## Step 2: Configure Apple OAuth

### 2.1 Apple Developer Account Setup

1. Go to [Apple Developer Console](https://developer.apple.com/)
2. Sign in with your Apple Developer account
3. Navigate to "Certificates, Identifiers & Profiles"

### 2.2 Create App ID

1. Go to "Identifiers" → "App IDs"
2. Click "+" to create new App ID
3. Select "App" and continue
4. Configure:
   - Description: "LabSyncPro"
   - Bundle ID: `com.yourcompany.labsyncpro`
   - Capabilities: Enable "Sign In with Apple"
5. Register the App ID

### 2.3 Create Service ID

1. Go to "Identifiers" → "Services IDs"
2. Click "+" to create new Service ID
3. Configure:
   - Description: "LabSyncPro Web"
   - Identifier: `com.yourcompany.labsyncpro.web`
4. Enable "Sign In with Apple"
5. Configure domains and URLs:
   - Primary App ID: Select your App ID from step 2.2
   - Domains: `jpdkzugjxinxzpdxbiss.supabase.co`
   - Return URLs: `https://jpdkzugjxinxzpdxbiss.supabase.co/auth/v1/callback`

### 2.4 Create Private Key

1. Go to "Keys"
2. Click "+" to create new key
3. Configure:
   - Key Name: "LabSyncPro Sign In with Apple"
   - Enable "Sign In with Apple"
   - Configure: Select your App ID
4. Download the private key (.p8 file)
5. Note the Key ID

### 2.5 Configure in Supabase

1. Go to your Supabase dashboard
2. Navigate to "Authentication" → "Providers"
3. Find "Apple" and toggle it ON
4. Enter your credentials:
   - **Client ID**: Your Service ID (e.g., `com.yourcompany.labsyncpro.web`)
   - **Client Secret**: Generate using the private key (see below)

### 2.6 Generate Apple Client Secret

Apple requires a JWT token as the client secret. Use this Node.js script:

```javascript
// generate-apple-secret.js
const jwt = require('jsonwebtoken');
const fs = require('fs');

const privateKey = fs.readFileSync('path/to/your/AuthKey_XXXXXXXXXX.p8', 'utf8');

const clientSecret = jwt.sign(
  {
    iss: 'YOUR_TEAM_ID', // 10-character Team ID
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (6 * 30 * 24 * 60 * 60), // 6 months
    aud: 'https://appleid.apple.com',
    sub: 'com.yourcompany.labsyncpro.web', // Your Service ID
  },
  privateKey,
  {
    algorithm: 'ES256',
    header: {
      kid: 'YOUR_KEY_ID', // 10-character Key ID
      alg: 'ES256',
    },
  }
);

console.log('Apple Client Secret:', clientSecret);
```

Run: `node generate-apple-secret.js`

### 2.7 Update Environment Variables

Add to your `.env.local`:
```env
NEXT_PUBLIC_APPLE_CLIENT_ID=com.yourcompany.labsyncpro.web
APPLE_CLIENT_SECRET=your_generated_jwt_token_here
```

## Step 3: Configure Email Verification

### 3.1 Supabase Email Settings

1. Go to Supabase Dashboard → "Authentication" → "Settings"
2. Configure Email settings:
   - **Enable email confirmations**: ON
   - **Confirm email change**: ON
   - **Secure email change**: ON

### 3.2 Custom SMTP (Recommended)

1. In Supabase Dashboard → "Settings" → "Auth"
2. Scroll to "SMTP Settings"
3. Configure custom SMTP:
   ```
   Host: smtp.gmail.com
   Port: 587
   Username: noreply@yourdomain.com
   Password: your_app_password
   Sender email: noreply@yourdomain.com
   Sender name: LabSyncPro
   ```

### 3.3 Gmail App Password Setup

1. Enable 2-factor authentication on your Gmail account
2. Go to Google Account settings
3. Security → 2-Step Verification → App passwords
4. Generate app password for "Mail"
5. Use this password in SMTP settings

### 3.4 Email Templates

Customize email templates in Supabase:
1. Go to "Authentication" → "Email Templates"
2. Customize:
   - **Confirm signup**: Welcome email with verification link
   - **Reset password**: Password reset instructions
   - **Change email**: Email change confirmation

## Step 4: Update Supabase Auth Configuration

### 4.1 Site URL Configuration

1. Go to Supabase Dashboard → "Authentication" → "URL Configuration"
2. Set Site URL: `https://your-domain.com` (or `http://localhost:3001` for development)
3. Add Redirect URLs:
   ```
   http://localhost:3000/auth/callback
   http://localhost:3001/auth/callback
   https://your-domain.com/auth/callback
   ```

### 4.2 Security Settings

1. Enable email confirmations
2. Set session timeout (optional)
3. Configure rate limiting
4. Enable CAPTCHA (optional)

## Step 5: Test Configuration

### 5.1 Test Google OAuth

1. Go to your app's login page
2. Click "Continue with Google"
3. Complete OAuth flow
4. Verify user is created in Supabase

### 5.2 Test Apple OAuth

1. Go to your app's login page
2. Click "Continue with Apple"
3. Complete OAuth flow
4. Verify user is created in Supabase

### 5.3 Test Email Verification

1. Register with email/password
2. Check email for verification link
3. Click verification link
4. Verify account is activated

## Troubleshooting

### Common Issues

1. **"Provider not enabled"**
   - Check provider is enabled in Supabase dashboard
   - Verify credentials are correctly entered

2. **"Invalid redirect URI"**
   - Check redirect URIs match exactly in OAuth provider settings
   - Include both development and production URLs

3. **"Email not sent"**
   - Check SMTP configuration
   - Verify sender email is authorized
   - Check spam folder

4. **Apple OAuth not working**
   - Verify Service ID configuration
   - Check JWT token is valid and not expired
   - Ensure domains are correctly configured

### Debug Steps

1. Check Supabase logs in dashboard
2. Check browser network tab for errors
3. Verify environment variables are loaded
4. Test with different browsers/incognito mode

## Security Considerations

1. **Never commit secrets to version control**
2. **Use environment variables for all credentials**
3. **Regularly rotate client secrets**
4. **Monitor OAuth usage in provider dashboards**
5. **Set up proper CORS policies**

---

After completing this setup, your LabSyncPro application will have:
- ✅ Google OAuth authentication
- ✅ Apple OAuth authentication  
- ✅ Required email verification
- ✅ Professional no-reply email setup
- ✅ Secure authentication flows
