#!/bin/bash

# Git Deploy Script for LabSyncPro
# Usage: ./git-deploy.sh "Your commit message"

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

# Check if commit message is provided
if [ -z "$1" ]; then
    print_error "Please provide a commit message"
    echo "Usage: ./git-deploy.sh \"Your commit message\""
    exit 1
fi

COMMIT_MESSAGE="$1"

print_status "Starting git deployment process..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    print_error "Not a git repository. Please run this script from the project root."
    exit 1
fi

# Show current status
print_status "Current git status:"
git status --short

# Add all changes
print_status "Adding all changes..."
git add .

if [ $? -eq 0 ]; then
    print_success "Files added successfully"
else
    print_error "Failed to add files"
    exit 1
fi

# Show what will be committed
print_status "Files to be committed:"
git diff --cached --name-only

# Commit changes
print_status "Committing changes with message: '$COMMIT_MESSAGE'"
git commit -m "$COMMIT_MESSAGE"

if [ $? -eq 0 ]; then
    print_success "Commit successful"
else
    print_error "Commit failed"
    exit 1
fi

# Push to remote
print_status "Pushing to remote repository..."
git push origin main

if [ $? -eq 0 ]; then
    print_success "Push successful"
    print_success "Deployment complete!"
    echo ""
    print_status "Your changes have been deployed to:"
    print_status "- GitHub: https://github.com/cscodex/LabSyncProA"
    print_status "- Render will automatically deploy the changes"
    print_status "- Check Render logs: https://dashboard.render.com"
else
    print_error "Push failed"
    print_warning "You may need to pull changes first if there are conflicts"
    echo ""
    print_status "Try running:"
    echo "  git pull origin main"
    echo "  ./git-deploy.sh \"$COMMIT_MESSAGE\""
    exit 1
fi

# Show recent commits
echo ""
print_status "Recent commits:"
git log --oneline -5

print_success "Git deployment completed successfully!"
