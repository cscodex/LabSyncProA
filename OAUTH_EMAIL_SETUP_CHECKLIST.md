# OAuth & Email Verification Setup Checklist

## 🔐 OAuth Configuration Status

### Google OAuth Setup
- [ ] **Google Cloud Console Project Created**
- [ ] **OAuth 2.0 Client ID Created**
  - [ ] Authorized JavaScript origins added
  - [ ] Authorized redirect URIs added
- [ ] **Google Provider Enabled in Supabase**
  - [ ] Client ID configured
  - [ ] Client Secret configured
- [ ] **Environment Variables Updated**
  ```env
  NEXT_PUBLIC_GOOGLE_CLIENT_ID=your_google_client_id_here
  GOOGLE_CLIENT_SECRET=your_google_client_secret_here
  ```

### Apple OAuth Setup
- [ ] **Apple Developer Account Access**
- [ ] **App ID Created**
  - [ ] Sign In with Apple capability enabled
- [ ] **Service ID Created**
  - [ ] Domains and return URLs configured
- [ ] **Private Key Generated**
  - [ ] .p8 file downloaded
  - [ ] Key ID noted
- [ ] **Apple Provider Enabled in Supabase**
  - [ ] Client ID configured (Service ID)
  - [ ] Client Secret configured (JWT token)
- [ ] **Environment Variables Updated**
  ```env
  NEXT_PUBLIC_APPLE_CLIENT_ID=com.yourcompany.labsyncpro.web
  APPLE_CLIENT_SECRET=your_generated_jwt_token_here
  ```

## 📧 Email Verification Configuration

### Supabase Email Settings
- [ ] **Email Confirmations Enabled**
  - [ ] Enable email confirmations: ON
  - [ ] Confirm email change: ON
  - [ ] Secure email change: ON
- [ ] **Custom SMTP Configured**
  - [ ] SMTP host, port, credentials set
  - [ ] Sender email configured
  - [ ] Test email sent successfully
- [ ] **Email Templates Customized**
  - [ ] Confirm signup template
  - [ ] Reset password template
  - [ ] Change email template

### No-Reply Email Setup
- [ ] **Email Provider Chosen**
  - [ ] Gmail (development)
  - [ ] SendGrid (production)
  - [ ] Amazon SES (cost-effective)
  - [ ] Other: _______________
- [ ] **Domain Authentication** (Production)
  - [ ] SPF record added
  - [ ] DKIM record added
  - [ ] DMARC record added
- [ ] **Environment Variables Updated**
  ```env
  SUPABASE_SMTP_HOST=smtp.gmail.com
  SUPABASE_SMTP_PORT=587
  SUPABASE_SMTP_USER=noreply@yourdomain.com
  SUPABASE_SMTP_PASS=your_app_password_here
  ```

## 🔧 Supabase Configuration

### Authentication Settings
- [ ] **Site URL Configured**
  - Development: `http://localhost:3001`
  - Production: `https://your-domain.com`
- [ ] **Redirect URLs Added**
  - [ ] `http://localhost:3000/auth/callback`
  - [ ] `http://localhost:3001/auth/callback`
  - [ ] `https://your-domain.com/auth/callback`
- [ ] **Database Policies Updated**
  - [ ] Email verification SQL script executed
  - [ ] RLS policies configured
  - [ ] User creation triggers set up

## 🧪 Testing Checklist

### Google OAuth Testing
- [ ] **Login Flow**
  - [ ] Click "Continue with Google"
  - [ ] Google OAuth popup appears
  - [ ] User can select Google account
  - [ ] Redirected back to app successfully
  - [ ] User profile created in database
- [ ] **Error Handling**
  - [ ] Cancelled OAuth flow handled gracefully
  - [ ] Network errors handled properly

### Apple OAuth Testing
- [ ] **Login Flow**
  - [ ] Click "Continue with Apple"
  - [ ] Apple OAuth popup appears
  - [ ] User can sign in with Apple ID
  - [ ] Redirected back to app successfully
  - [ ] User profile created in database
- [ ] **Error Handling**
  - [ ] Cancelled OAuth flow handled gracefully
  - [ ] Network errors handled properly

### Email Verification Testing
- [ ] **Registration Flow**
  - [ ] Register with email/password
  - [ ] Verification email received
  - [ ] Email has correct branding
  - [ ] Verification link works
  - [ ] User can sign in after verification
- [ ] **Password Reset Flow**
  - [ ] Request password reset
  - [ ] Reset email received
  - [ ] Reset link works
  - [ ] Can set new password
  - [ ] Can sign in with new password
- [ ] **Email Change Flow**
  - [ ] Change email in profile
  - [ ] Confirmation emails sent to both addresses
  - [ ] Email change confirmed successfully

## 🚨 Common Issues & Solutions

### "Provider not enabled" Error
- ✅ **Solution**: Enable provider in Supabase dashboard
- ✅ **Check**: Provider toggle is ON
- ✅ **Verify**: Credentials are correctly entered

### "Invalid redirect URI" Error
- ✅ **Solution**: Check redirect URIs match exactly
- ✅ **Check**: Include both development and production URLs
- ✅ **Verify**: No trailing slashes or typos

### "Email not sent" Error
- ✅ **Solution**: Check SMTP configuration
- ✅ **Check**: Sender email is verified
- ✅ **Verify**: SMTP credentials are correct
- ✅ **Test**: Send test email from provider

### Apple OAuth "Invalid client" Error
- ✅ **Solution**: Regenerate JWT client secret
- ✅ **Check**: Service ID configuration
- ✅ **Verify**: Private key is correct
- ✅ **Ensure**: JWT token hasn't expired

## 📋 Quick Commands

### Generate Apple Client Secret
```bash
# Install jsonwebtoken if not already installed
npm install jsonwebtoken

# Run the generator script
node scripts/generate-apple-secret.js \
  --key-file ./AuthKey_ABC123DEF4.p8 \
  --team-id ABC123DEF4 \
  --key-id ABC123DEF4 \
  --client-id com.yourcompany.labsyncpro.web
```

### Test SMTP Connection
```bash
# Test Gmail SMTP
telnet smtp.gmail.com 587
```

### Configure Supabase Database
```sql
-- Run in Supabase SQL Editor
\i scripts/configure-supabase-auth.sql
```

## 🎯 Final Verification

### Production Readiness
- [ ] **All OAuth providers working**
- [ ] **Email verification required and working**
- [ ] **Professional email setup (no-reply)**
- [ ] **Error handling implemented**
- [ ] **Security policies configured**
- [ ] **Domain authentication set up**
- [ ] **Rate limiting configured**
- [ ] **Monitoring and logging enabled**

### Documentation Updated
- [ ] **Environment variables documented**
- [ ] **Setup instructions provided**
- [ ] **Troubleshooting guide available**
- [ ] **Team members trained**

---

## 🚀 Next Steps After Completion

1. **Deploy to production** with updated environment variables
2. **Monitor authentication flows** for any issues
3. **Set up monitoring** for email deliverability
4. **Configure backup authentication** methods if needed
5. **Document user onboarding** process
6. **Train support team** on common auth issues

**Status**: ⏳ In Progress | ✅ Complete | ❌ Blocked

**Last Updated**: [Date]
**Completed By**: [Name]
