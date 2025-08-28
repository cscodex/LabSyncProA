#!/bin/bash

# LabSyncPro Git Repository Setup Script
# This script initializes a git repository, adds all files, and pushes to remote

set -e  # Exit on any error

echo "🚀 LabSyncPro Git Repository Setup"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if git is installed
if ! command -v git &> /dev/null; then
    print_error "Git is not installed. Please install Git first."
    exit 1
fi

# Get repository URL from user
if [ -z "$1" ]; then
    echo -n "Enter your GitHub repository URL (e.g., https://github.com/username/labsyncpro.git): "
    read REPO_URL
else
    REPO_URL=$1
fi

if [ -z "$REPO_URL" ]; then
    print_error "Repository URL is required"
    exit 1
fi

print_status "Repository URL: $REPO_URL"

# Check if we're already in a git repository
if [ -d ".git" ]; then
    print_warning "Git repository already exists"
    echo -n "Do you want to continue? This will add and push changes. (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_status "Aborted by user"
        exit 0
    fi
else
    # Initialize git repository
    print_status "Initializing git repository..."
    git init
    print_success "Git repository initialized"
fi

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    print_status "Creating .gitignore file..."
    cat > .gitignore << 'EOF'
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Next.js
.next/
out/
build/

# Production builds
dist/

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
*.lcov

# nyc test coverage
.nyc_output

# Dependency directories
jspm_packages/

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Microbundle cache
.rpt2_cache/
.rts2_cache_cjs/
.rts2_cache_es/
.rts2_cache_umd/

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# parcel-bundler cache (https://parceljs.org/)
.cache
.parcel-cache

# Next.js build output
.next

# Nuxt.js build / generate output
.nuxt
dist

# Storybook build outputs
.out
.storybook-out

# Temporary folders
tmp/
temp/

# Editor directories and files
.vscode/
.idea/
*.swp
*.swo
*~

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Logs
logs
*.log

# Database
*.sqlite
*.db

# Supabase
.supabase/

# Vercel
.vercel

# TypeScript
*.tsbuildinfo
next-env.d.ts
EOF
    print_success ".gitignore file created"
fi

# Add remote origin if not exists
if ! git remote get-url origin &> /dev/null; then
    print_status "Adding remote origin..."
    git remote add origin "$REPO_URL"
    print_success "Remote origin added"
else
    print_warning "Remote origin already exists"
    current_url=$(git remote get-url origin)
    if [ "$current_url" != "$REPO_URL" ]; then
        print_status "Updating remote origin URL..."
        git remote set-url origin "$REPO_URL"
        print_success "Remote origin URL updated"
    fi
fi

# Check git user configuration
if [ -z "$(git config user.name)" ] || [ -z "$(git config user.email)" ]; then
    print_warning "Git user configuration not found"
    echo -n "Enter your name: "
    read GIT_NAME
    echo -n "Enter your email: "
    read GIT_EMAIL
    
    git config user.name "$GIT_NAME"
    git config user.email "$GIT_EMAIL"
    print_success "Git user configuration set"
fi

# Add all files
print_status "Adding files to git..."
git add .
print_success "Files added to staging area"

# Check if there are any changes to commit
if git diff --staged --quiet; then
    print_warning "No changes to commit"
else
    # Commit changes
    print_status "Committing changes..."
    COMMIT_MESSAGE="Initial commit: LabSyncPro Authentication System

- Complete authentication system with email/password and OAuth
- Role-based access control (6 user roles)
- Email verification and password reset
- Dark/light mode toggle
- Responsive design with modern UI
- TypeScript implementation with Supabase integration
- Production-ready authentication flows"

    git commit -m "$COMMIT_MESSAGE"
    print_success "Changes committed"
fi

# Push to remote repository
print_status "Pushing to remote repository..."
if git push -u origin main 2>/dev/null; then
    print_success "Successfully pushed to main branch"
elif git push -u origin master 2>/dev/null; then
    print_success "Successfully pushed to master branch"
else
    print_error "Failed to push. Trying to set upstream..."
    # Try to push and set upstream
    if git push --set-upstream origin main 2>/dev/null; then
        print_success "Successfully pushed and set upstream to main"
    elif git push --set-upstream origin master 2>/dev/null; then
        print_success "Successfully pushed and set upstream to master"
    else
        print_error "Failed to push to remote repository"
        print_status "Please check your repository URL and permissions"
        exit 1
    fi
fi

echo ""
print_success "🎉 Git repository setup completed successfully!"
echo ""
print_status "Repository URL: $REPO_URL"
print_status "You can now view your code on GitHub/GitLab"
echo ""
print_status "Next steps:"
echo "  1. Set up deployment on Render/Vercel"
echo "  2. Configure environment variables"
echo "  3. Set up database schema in Supabase"
echo ""
