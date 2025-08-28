# Email Verification Setup Guide for LabSyncPro

This guide will help you configure required email verification with a professional no-reply email setup.

## Step 1: Configure Supabase Email Settings

### 1.1 Enable Email Confirmations

1. Go to your Supabase Dashboard
2. Navigate to **Authentication** → **Settings**
3. In the **User Management** section:
   - ✅ **Enable email confirmations**: Turn ON
   - ✅ **Confirm email change**: Turn ON  
   - ✅ **Secure email change**: Turn ON
   - ✅ **Double confirm email changes**: Turn ON (recommended)

### 1.2 Configure Email Templates

1. Go to **Authentication** → **Email Templates**
2. Customize the following templates:

#### Confirm Signup Template
```html
<h2>Welcome to LabSyncPro!</h2>
<p>Thank you for signing up. Please click the link below to verify your email address:</p>
<p><a href="{{ .ConfirmationURL }}">Verify Email Address</a></p>
<p>If you didn't create an account with us, please ignore this email.</p>
<p>Best regards,<br>The LabSyncPro Team</p>
```

#### Reset Password Template
```html
<h2>Reset Your LabSyncPro Password</h2>
<p>You requested to reset your password. Click the link below to create a new password:</p>
<p><a href="{{ .ConfirmationURL }}">Reset Password</a></p>
<p>This link will expire in 1 hour for security reasons.</p>
<p>If you didn't request this, please ignore this email.</p>
<p>Best regards,<br>The LabSyncPro Team</p>
```

## Step 2: Set Up Custom SMTP (No-Reply Email)

### 2.1 Choose Email Provider

**Recommended Options:**
- **Gmail** (easiest for development)
- **SendGrid** (best for production)
- **Amazon SES** (cost-effective)
- **Mailgun** (developer-friendly)

### 2.2 Gmail Setup (Development)

1. **Create a dedicated Gmail account:**
   - Email: `noreply.labsyncpro@gmail.com`
   - Use a strong password

2. **Enable 2-Factor Authentication:**
   - Go to Google Account settings
   - Security → 2-Step Verification
   - Enable 2FA

3. **Generate App Password:**
   - Go to Security → 2-Step Verification → App passwords
   - Select "Mail" and generate password
   - Save this password securely

4. **Configure in Supabase:**
   - Go to **Settings** → **Auth** → **SMTP Settings**
   - Enable custom SMTP
   - Configure:
     ```
     Host: smtp.gmail.com
     Port: 587
     Username: noreply.labsyncpro@gmail.com
     Password: [your-app-password]
     Sender email: noreply.labsyncpro@gmail.com
     Sender name: LabSyncPro
     ```

### 2.3 SendGrid Setup (Production)

1. **Create SendGrid Account:**
   - Go to [SendGrid](https://sendgrid.com/)
   - Sign up for free account

2. **Verify Domain:**
   - Go to Settings → Sender Authentication
   - Verify your domain (e.g., `yourdomain.com`)
   - Add DNS records as instructed

3. **Create API Key:**
   - Go to Settings → API Keys
   - Create new API key with "Mail Send" permissions
   - Save the API key securely

4. **Configure in Supabase:**
   ```
   Host: smtp.sendgrid.net
   Port: 587
   Username: apikey
   Password: [your-sendgrid-api-key]
   Sender email: noreply@yourdomain.com
   Sender name: LabSyncPro
   ```

### 2.4 Amazon SES Setup (Cost-Effective)

1. **Set up AWS SES:**
   - Go to AWS Console → Simple Email Service
   - Verify your domain
   - Request production access (removes sending limits)

2. **Create SMTP Credentials:**
   - Go to SES → SMTP Settings
   - Create SMTP credentials
   - Save username and password

3. **Configure in Supabase:**
   ```
   Host: email-smtp.us-east-1.amazonaws.com
   Port: 587
   Username: [your-ses-smtp-username]
   Password: [your-ses-smtp-password]
   Sender email: noreply@yourdomain.com
   Sender name: LabSyncPro
   ```

## Step 3: Update Environment Variables

Add to your `.env.local`:

```env
# Email Configuration
SUPABASE_SMTP_HOST=smtp.gmail.com
SUPABASE_SMTP_PORT=587
SUPABASE_SMTP_USER=noreply.labsyncpro@gmail.com
SUPABASE_SMTP_PASS=your_app_password_here
SUPABASE_SMTP_FROM=noreply.labsyncpro@gmail.com
SUPABASE_SMTP_NAME=LabSyncPro
```

## Step 4: Configure URL Settings

### 4.1 Site URL Configuration

1. Go to **Authentication** → **URL Configuration**
2. Set **Site URL**:
   - Development: `http://localhost:3001`
   - Production: `https://your-domain.com`

3. Add **Redirect URLs**:
   ```
   http://localhost:3000/auth/callback
   http://localhost:3001/auth/callback
   https://your-domain.com/auth/callback
   ```

### 4.2 Email Link Configuration

Ensure email links redirect to the correct pages:
- **Email confirmation**: `/auth/callback`
- **Password reset**: `/auth/update-password`
- **Email change**: `/auth/callback`

## Step 5: Test Email Verification

### 5.1 Test Registration Flow

1. Go to your app's registration page
2. Fill out the form with a real email address
3. Submit the form
4. Check your email for verification message
5. Click the verification link
6. Verify you're redirected to the app and logged in

### 5.2 Test Password Reset

1. Go to login page
2. Click "Forgot Password"
3. Enter your email address
4. Check email for reset link
5. Click link and set new password
6. Verify you can log in with new password

## Step 6: Production Considerations

### 6.1 Domain Authentication

For production, set up proper domain authentication:

1. **SPF Record:**
   ```
   v=spf1 include:_spf.google.com ~all
   ```

2. **DKIM Record:**
   - Configure through your email provider
   - Add DKIM DNS records

3. **DMARC Record:**
   ```
   v=DMARC1; p=quarantine; rua=mailto:dmarc@yourdomain.com
   ```

### 6.2 Email Deliverability

1. **Use a dedicated IP** (for high volume)
2. **Monitor bounce rates** and unsubscribes
3. **Set up feedback loops** with ISPs
4. **Regularly clean email lists**

### 6.3 Security Best Practices

1. **Use strong passwords** for email accounts
2. **Enable 2FA** on all email service accounts
3. **Rotate API keys** regularly
4. **Monitor email logs** for suspicious activity
5. **Set up alerts** for failed deliveries

## Troubleshooting

### Common Issues

1. **Emails not being sent:**
   - Check SMTP credentials
   - Verify sender email is authenticated
   - Check Supabase logs for errors

2. **Emails going to spam:**
   - Set up SPF, DKIM, and DMARC records
   - Use a reputable email service
   - Avoid spam trigger words

3. **Verification links not working:**
   - Check redirect URLs are correct
   - Verify site URL is properly set
   - Ensure HTTPS in production

4. **Rate limiting issues:**
   - Check email provider limits
   - Implement proper rate limiting
   - Consider upgrading email service plan

### Debug Steps

1. **Check Supabase logs:**
   - Go to Dashboard → Logs
   - Filter for authentication events

2. **Test SMTP connection:**
   - Use tools like `telnet` to test SMTP
   - Verify credentials work outside Supabase

3. **Check email headers:**
   - Examine email source for delivery issues
   - Look for authentication failures

## Email Template Customization

### Advanced Template Example

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LabSyncPro Email Verification</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #3b82f6; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .button { display: inline-block; padding: 12px 24px; background: #3b82f6; color: white; text-decoration: none; border-radius: 5px; }
        .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>LabSyncPro</h1>
        </div>
        <div class="content">
            <h2>Welcome to LabSyncPro!</h2>
            <p>Thank you for creating your account. To complete your registration and start using LabSyncPro, please verify your email address by clicking the button below:</p>
            <p style="text-align: center;">
                <a href="{{ .ConfirmationURL }}" class="button">Verify Email Address</a>
            </p>
            <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
            <p style="word-break: break-all;">{{ .ConfirmationURL }}</p>
            <p>This verification link will expire in 24 hours for security reasons.</p>
            <p>If you didn't create an account with LabSyncPro, please ignore this email.</p>
        </div>
        <div class="footer">
            <p>© 2024 LabSyncPro. All rights reserved.</p>
            <p>This is an automated message, please do not reply to this email.</p>
        </div>
    </div>
</body>
</html>
```

---

After completing this setup, your LabSyncPro application will have:
- ✅ Required email verification for all new accounts
- ✅ Professional no-reply email setup
- ✅ Custom email templates with branding
- ✅ Secure SMTP configuration
- ✅ Production-ready email deliverability
