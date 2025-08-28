# LabSyncPro Deployment Guide

## Render Deployment

### Prerequisites
1. GitHub repository with your LabSyncPro code
2. Supabase project set up
3. Render account (free tier available)

### Step 1: Prepare Your Repository

Run the git setup script to push your code to GitHub:

```bash
# For macOS/Linux
./scripts/setup-git.sh

# For Windows
scripts\setup-git.bat
```

Or manually:
```bash
git init
git add .
git commit -m "Initial commit: LabSyncPro Authentication System"
git remote add origin https://github.com/yourusername/labsyncpro.git
git push -u origin main
```

### Step 2: Deploy to Render

1. **Go to [Render Dashboard](https://dashboard.render.com/)**

2. **Create New Web Service**
   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - Select your LabSyncPro repository

3. **Configure Build Settings**
   ```
   Name: labsyncpro
   Environment: Node
   Region: Choose closest to your users
   Branch: main
   Build Command: npm install && npm run build
   Start Command: npm start
   ```

4. **Set Environment Variables**

   Add these environment variables in Render dashboard:

   ```env
   NODE_ENV=production
   NEXT_PUBLIC_SUPABASE_URL=https://jpdkzugjxinxzpdxbiss.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpwZGt6dWdqeGlueHpwZHhiaXNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYyODA2OTIsImV4cCI6MjA3MTg1NjY5Mn0.rsuAsStMVw0lcFWJo6xrXFeWmKMKLZektJRTnmyy0p0
   SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpwZGt6dWdqeGlueHpwZHhiaXNzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NjI4MDY5MiwiZXhwIjoyMDcxODU2NjkyfQ.sL01pdTHvg6kOMWkVXJMaczwhvYhge2SOqD2dwhMA54
   NEXT_PUBLIC_SITE_URL=https://your-app-name.onrender.com
   NEXTAUTH_SECRET=your-random-secret-key-here
   NEXTAUTH_URL=https://your-app-name.onrender.com
   ```

   **Generate NEXTAUTH_SECRET:**
   ```bash
   openssl rand -base64 32
   ```

5. **Deploy**
   - Click "Create Web Service"
   - Render will automatically build and deploy your app
   - Wait for deployment to complete (usually 5-10 minutes)

### Step 3: Configure Supabase for Production

1. **Update Supabase Auth Settings**
   - Go to your Supabase dashboard
   - Navigate to Authentication → Settings
   - Add your Render URL to "Site URL": `https://your-app-name.onrender.com`
   - Add redirect URLs for OAuth:
     ```
     https://your-app-name.onrender.com/auth/callback
     ```

2. **Configure OAuth Providers (Optional)**
   
   **Google OAuth:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Add authorized redirect URI: `https://jpdkzugjxinxzpdxbiss.supabase.co/auth/v1/callback`
   - Add your domain to authorized origins: `https://your-app-name.onrender.com`

   **Apple OAuth:**
   - Go to [Apple Developer Console](https://developer.apple.com/)
   - Add redirect URI: `https://jpdkzugjxinxzpdxbiss.supabase.co/auth/v1/callback`

### Step 4: Set Up Database Schema

Run the database schema in your Supabase SQL editor:

1. Go to Supabase Dashboard → SQL Editor
2. Copy and paste the content from `labsyncpro_schema` file
3. Execute the SQL to create all tables and functions

### Alternative Deployment Options

#### Vercel Deployment

1. **Install Vercel CLI**
   ```bash
   npm install -g vercel
   ```

2. **Deploy**
   ```bash
   vercel
   ```

3. **Set Environment Variables**
   ```bash
   vercel env add NEXT_PUBLIC_SUPABASE_URL
   vercel env add NEXT_PUBLIC_SUPABASE_ANON_KEY
   vercel env add SUPABASE_SERVICE_ROLE_KEY
   vercel env add NEXT_PUBLIC_SITE_URL
   vercel env add NEXTAUTH_SECRET
   vercel env add NEXTAUTH_URL
   ```

#### Netlify Deployment

1. **Build Command:** `npm run build`
2. **Publish Directory:** `.next`
3. **Environment Variables:** Same as above

### Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `NODE_ENV` | Node environment | `production` |
| `NEXT_PUBLIC_SUPABASE_URL` | Your Supabase project URL | `https://xxx.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anonymous key | `eyJhbGciOiJIUzI1NiIs...` |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key | `eyJhbGciOiJIUzI1NiIs...` |
| `NEXT_PUBLIC_SITE_URL` | Your deployed app URL | `https://your-app.onrender.com` |
| `NEXTAUTH_SECRET` | Random secret for auth | Generate with `openssl rand -base64 32` |
| `NEXTAUTH_URL` | Your deployed app URL | `https://your-app.onrender.com` |

### Post-Deployment Checklist

- [ ] App loads successfully at your Render URL
- [ ] Authentication pages are accessible
- [ ] Email/password registration works
- [ ] Email verification emails are sent
- [ ] Password reset functionality works
- [ ] Dark/light mode toggle works
- [ ] OAuth providers work (if configured)
- [ ] Database connections are successful
- [ ] All environment variables are set correctly

### Troubleshooting

**Common Issues:**

1. **Build Fails**
   - Check Node.js version compatibility
   - Ensure all dependencies are in package.json
   - Check build logs for specific errors

2. **Environment Variables Not Working**
   - Verify all required variables are set
   - Check for typos in variable names
   - Restart the service after adding variables

3. **Database Connection Issues**
   - Verify Supabase URL and keys
   - Check if database schema is deployed
   - Ensure RLS policies are configured

4. **OAuth Not Working**
   - Check redirect URLs in OAuth provider settings
   - Verify Supabase auth configuration
   - Ensure site URL is correctly set

### Monitoring and Logs

- **Render Logs**: Available in Render dashboard under "Logs" tab
- **Supabase Logs**: Available in Supabase dashboard under "Logs" section
- **Error Tracking**: Consider adding Sentry or similar service for production

### Scaling Considerations

- **Free Tier Limitations**: Render free tier has limitations (sleeps after 15 minutes of inactivity)
- **Upgrade Options**: Consider upgrading to paid plans for production use
- **Database Scaling**: Monitor Supabase usage and upgrade plan as needed
- **CDN**: Consider adding Cloudflare for better performance

---

Your LabSyncPro application is now ready for production deployment! 🚀
