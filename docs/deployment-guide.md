# LabSyncPro Deployment Guide

## 🚀 **Render.com Deployment**

### **Prerequisites**
- GitHub repository with your LabSyncPro code
- Supabase project set up and configured
- Google OAuth credentials

### **Step 1: Prepare for Deployment**

1. **Ensure all environment variables are set:**
   ```env
   NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
   ```

2. **Update Supabase Auth Settings:**
   - Go to Supabase Dashboard → Authentication → URL Configuration
   - Add your Render domain to Site URL and Redirect URLs
   - Example: `https://your-app-name.onrender.com`

### **Step 2: Deploy to Render**

1. **Go to [Render.com](https://render.com)** and sign in with GitHub

2. **Create New Web Service:**
   - Click "New +" → "Web Service"
   - Connect your GitHub repository: `LabSyncProA`
   - Choose the repository from the list

3. **Configure Build Settings:**
   ```
   Name: labsyncpro
   Environment: Node
   Region: Choose closest to your users
   Branch: main
   Root Directory: (leave blank)
   Build Command: npm install && npm run build
   Start Command: npm start
   ```

4. **Add Environment Variables:**
   - Click "Environment" tab
   - Add each environment variable:
     ```
     NEXT_PUBLIC_SUPABASE_URL = your_supabase_project_url
     NEXT_PUBLIC_SUPABASE_ANON_KEY = your_supabase_anon_key
     SUPABASE_SERVICE_ROLE_KEY = your_service_role_key
     NODE_ENV = production
     ```

5. **Deploy:**
   - Click "Create Web Service"
   - Wait for deployment to complete (5-10 minutes)

### **Step 3: Configure Google OAuth**

1. **Update Google Cloud Console:**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Navigate to APIs & Services → Credentials
   - Edit your OAuth 2.0 Client ID
   - Add Authorized redirect URIs:
     ```
     https://your-supabase-project.supabase.co/auth/v1/callback
     https://your-app-name.onrender.com/auth/callback
     ```

2. **Update Supabase Auth:**
   - Go to Supabase Dashboard → Authentication → Providers
   - Update Google OAuth settings with your production redirect URLs

### **Step 4: Update Database**

1. **Run Database Scripts:**
   - Go to Supabase Dashboard → SQL Editor
   - Run the complete schema setup script:
     ```sql
     -- Copy and run scripts/clean-schema-reset.sql
     -- Then run scripts/complete-debug-and-fix.sql
     ```

2. **Verify Database:**
   - Check that all tables exist
   - Verify triggers are working
   - Test user creation

### **Step 5: Test Deployment**

1. **Test Basic Functionality:**
   - Visit your Render URL
   - Check that the login page loads
   - Verify theme toggle works

2. **Test Google OAuth:**
   - Click "Continue with Google"
   - Complete OAuth flow
   - Verify user profile is created
   - Check dashboard loads properly

3. **Test User Management:**
   - Create test users with different roles
   - Verify role-based access works
   - Test profile updates

## 🔧 **Troubleshooting**

### **Common Issues:**

1. **Build Fails:**
   ```bash
   # Check build logs in Render dashboard
   # Common fixes:
   - Ensure all dependencies are in package.json
   - Check for TypeScript errors
   - Verify environment variables are set
   ```

2. **OAuth Redirect Issues:**
   ```
   - Verify redirect URLs in Google Cloud Console
   - Check Supabase Auth URL configuration
   - Ensure HTTPS is used in production
   ```

3. **Database Connection Issues:**
   ```
   - Verify Supabase environment variables
   - Check database triggers are installed
   - Test database connection in Supabase dashboard
   ```

4. **Environment Variable Issues:**
   ```
   - Ensure all required env vars are set in Render
   - Check variable names match exactly
   - Verify Supabase keys are correct
   ```

## 📊 **Performance Optimization**

### **Render Configuration:**
```yaml
# render.yaml (optional)
services:
  - type: web
    name: labsyncpro
    env: node
    buildCommand: npm install && npm run build
    startCommand: npm start
    envVars:
      - key: NODE_ENV
        value: production
```

### **Next.js Optimization:**
- Static generation for public pages
- Image optimization enabled
- Bundle analysis for size optimization
- CDN caching for static assets

## 🔐 **Security Checklist**

- [ ] Environment variables properly set
- [ ] Supabase RLS policies enabled
- [ ] Google OAuth properly configured
- [ ] HTTPS enforced in production
- [ ] Database triggers working
- [ ] Error handling implemented
- [ ] Rate limiting configured (if needed)

## 📱 **Mobile Responsiveness**

- [ ] Test on mobile devices
- [ ] Verify touch interactions work
- [ ] Check responsive design breakpoints
- [ ] Test OAuth flow on mobile

## 🔄 **Continuous Deployment**

Render automatically deploys when you push to the main branch:

1. **Make changes locally**
2. **Commit and push to GitHub:**
   ```bash
   git add .
   git commit -m "your changes"
   git push origin main
   ```
3. **Render automatically deploys** the changes

## 📞 **Support Resources**

- **Render Documentation:** https://render.com/docs
- **Supabase Documentation:** https://supabase.com/docs
- **Next.js Deployment:** https://nextjs.org/docs/deployment
- **Google OAuth Setup:** https://developers.google.com/identity/protocols/oauth2

## 🎯 **Post-Deployment Tasks**

1. **Set up monitoring** (optional)
2. **Configure custom domain** (optional)
3. **Set up SSL certificate** (automatic with Render)
4. **Create admin users** via database
5. **Test all functionality** thoroughly
6. **Document any custom configurations**

Your LabSyncPro application should now be live and fully functional! 🚀
