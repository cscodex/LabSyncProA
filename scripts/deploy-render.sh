#!/bin/bash

# LabSyncPro Render Deployment Helper Script
# This script helps prepare and deploy LabSyncPro to Render

set -e

echo "🚀 LabSyncPro Render Deployment Helper"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    print_error "package.json not found. Please run this script from the project root."
    exit 1
fi

# Check if git repository exists
if [ ! -d ".git" ]; then
    print_error "Git repository not found. Please initialize git first using ./scripts/setup-git.sh"
    exit 1
fi

print_status "Preparing LabSyncPro for Render deployment..."

# Update package.json with production scripts if needed
if ! grep -q '"start":' package.json; then
    print_status "Adding production start script to package.json..."
    # This would require jq or manual editing
    print_warning "Please ensure your package.json has a 'start' script: \"next start\""
fi

# Generate NEXTAUTH_SECRET if not provided
if [ -z "$NEXTAUTH_SECRET" ]; then
    print_status "Generating NEXTAUTH_SECRET..."
    NEXTAUTH_SECRET=$(openssl rand -base64 32)
    print_success "Generated NEXTAUTH_SECRET: $NEXTAUTH_SECRET"
    echo "Please save this secret and add it to your Render environment variables."
fi

# Check environment variables
print_status "Checking required environment variables..."

required_vars=(
    "NEXT_PUBLIC_SUPABASE_URL"
    "NEXT_PUBLIC_SUPABASE_ANON_KEY"
    "SUPABASE_SERVICE_ROLE_KEY"
)

missing_vars=()

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
    print_warning "The following environment variables are not set locally:"
    for var in "${missing_vars[@]}"; do
        echo "  - $var"
    done
    print_status "Make sure to set these in your Render dashboard."
fi

# Create deployment checklist
print_status "Creating deployment checklist..."

cat > DEPLOYMENT_CHECKLIST.md << 'EOF'
# LabSyncPro Render Deployment Checklist

## Pre-Deployment
- [ ] Code pushed to GitHub repository
- [ ] Supabase project configured
- [ ] Database schema deployed
- [ ] Environment variables prepared

## Render Configuration
- [ ] Web service created on Render
- [ ] GitHub repository connected
- [ ] Build command set: `npm install && npm run build`
- [ ] Start command set: `npm start`
- [ ] Environment variables configured:
  - [ ] NODE_ENV=production
  - [ ] NEXT_PUBLIC_SUPABASE_URL
  - [ ] NEXT_PUBLIC_SUPABASE_ANON_KEY
  - [ ] SUPABASE_SERVICE_ROLE_KEY
  - [ ] NEXT_PUBLIC_SITE_URL
  - [ ] NEXTAUTH_SECRET
  - [ ] NEXTAUTH_URL

## Post-Deployment
- [ ] App loads successfully
- [ ] Authentication works
- [ ] Database connections successful
- [ ] OAuth configured (if using)
- [ ] Email verification working
- [ ] Dark/light mode toggle working

## Environment Variables for Render

```
NODE_ENV=production
NEXT_PUBLIC_SUPABASE_URL=https://jpdkzugjxinxzpdxbiss.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpwZGt6dWdqeGlueHpwZHhiaXNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYyODA2OTIsImV4cCI6MjA3MTg1NjY5Mn0.rsuAsStMVw0lcFWJo6xrXFeWmKMKLZektJRTnmyy0p0
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpwZGt6dWdqeGlueHpwZHhiaXNzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NjI4MDY5MiwiZXhwIjoyMDcxODU2NjkyfQ.sL01pdTHvg6kOMWkVXJMaczwhvYhge2SOqD2dwhMA54
NEXT_PUBLIC_SITE_URL=https://your-app-name.onrender.com
NEXTAUTH_SECRET=your-generated-secret-here
NEXTAUTH_URL=https://your-app-name.onrender.com
```

Replace `your-app-name` with your actual Render app name.
EOF

print_success "Deployment checklist created: DEPLOYMENT_CHECKLIST.md"

# Check if build works locally
print_status "Testing local build..."
if npm run build; then
    print_success "Local build successful!"
else
    print_error "Local build failed. Please fix build errors before deploying."
    exit 1
fi

# Final instructions
echo ""
print_success "🎉 LabSyncPro is ready for Render deployment!"
echo ""
print_status "Next steps:"
echo "1. Push your code to GitHub (if not already done)"
echo "2. Go to https://dashboard.render.com/"
echo "3. Create a new Web Service"
echo "4. Connect your GitHub repository"
echo "5. Configure build settings:"
echo "   - Build Command: npm install && npm run build"
echo "   - Start Command: npm start"
echo "6. Add environment variables from DEPLOYMENT_CHECKLIST.md"
echo "7. Deploy!"
echo ""
print_status "Generated NEXTAUTH_SECRET: $NEXTAUTH_SECRET"
print_warning "Save this secret - you'll need it for Render environment variables!"
echo ""
print_status "For detailed instructions, see DEPLOYMENT.md"
echo ""
