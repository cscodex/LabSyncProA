@echo off
setlocal enabledelayedexpansion

REM LabSyncPro Git Repository Setup Script for Windows
REM This script initializes a git repository, adds all files, and pushes to remote

echo.
echo 🚀 LabSyncPro Git Repository Setup
echo ==================================
echo.

REM Check if git is installed
git --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git is not installed. Please install Git first.
    pause
    exit /b 1
)

REM Get repository URL from user
if "%~1"=="" (
    set /p REPO_URL="Enter your GitHub repository URL (e.g., https://github.com/username/labsyncpro.git): "
) else (
    set REPO_URL=%~1
)

if "!REPO_URL!"=="" (
    echo [ERROR] Repository URL is required
    pause
    exit /b 1
)

echo [INFO] Repository URL: !REPO_URL!

REM Check if we're already in a git repository
if exist ".git" (
    echo [WARNING] Git repository already exists
    set /p response="Do you want to continue? This will add and push changes. (y/N): "
    if /i not "!response!"=="y" (
        echo [INFO] Aborted by user
        pause
        exit /b 0
    )
) else (
    REM Initialize git repository
    echo [INFO] Initializing git repository...
    git init
    echo [SUCCESS] Git repository initialized
)

REM Create .gitignore if it doesn't exist
if not exist ".gitignore" (
    echo [INFO] Creating .gitignore file...
    (
        echo # Dependencies
        echo node_modules/
        echo npm-debug.log*
        echo yarn-debug.log*
        echo yarn-error.log*
        echo.
        echo # Environment variables
        echo .env
        echo .env.local
        echo .env.development.local
        echo .env.test.local
        echo .env.production.local
        echo.
        echo # Next.js
        echo .next/
        echo out/
        echo build/
        echo.
        echo # Production builds
        echo dist/
        echo.
        echo # Runtime data
        echo pids
        echo *.pid
        echo *.seed
        echo *.pid.lock
        echo.
        echo # Coverage directory used by tools like istanbul
        echo coverage/
        echo *.lcov
        echo.
        echo # Dependency directories
        echo jspm_packages/
        echo.
        echo # Optional npm cache directory
        echo .npm
        echo.
        echo # Optional eslint cache
        echo .eslintcache
        echo.
        echo # Next.js build output
        echo .next
        echo.
        echo # Temporary folders
        echo tmp/
        echo temp/
        echo.
        echo # Editor directories and files
        echo .vscode/
        echo .idea/
        echo *.swp
        echo *.swo
        echo.
        echo # OS generated files
        echo .DS_Store
        echo .DS_Store?
        echo ._*
        echo .Spotlight-V100
        echo .Trashes
        echo ehthumbs.db
        echo Thumbs.db
        echo.
        echo # Logs
        echo logs
        echo *.log
        echo.
        echo # Database
        echo *.sqlite
        echo *.db
        echo.
        echo # Supabase
        echo .supabase/
        echo.
        echo # Vercel
        echo .vercel
        echo.
        echo # TypeScript
        echo *.tsbuildinfo
        echo next-env.d.ts
    ) > .gitignore
    echo [SUCCESS] .gitignore file created
)

REM Add remote origin if not exists
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo [INFO] Adding remote origin...
    git remote add origin "!REPO_URL!"
    echo [SUCCESS] Remote origin added
) else (
    echo [WARNING] Remote origin already exists
    for /f "delims=" %%i in ('git remote get-url origin') do set current_url=%%i
    if not "!current_url!"=="!REPO_URL!" (
        echo [INFO] Updating remote origin URL...
        git remote set-url origin "!REPO_URL!"
        echo [SUCCESS] Remote origin URL updated
    )
)

REM Check git user configuration
for /f "delims=" %%i in ('git config user.name 2^>nul') do set GIT_USER_NAME=%%i
for /f "delims=" %%i in ('git config user.email 2^>nul') do set GIT_USER_EMAIL=%%i

if "!GIT_USER_NAME!"=="" (
    echo [WARNING] Git user configuration not found
    set /p GIT_NAME="Enter your name: "
    set /p GIT_EMAIL="Enter your email: "
    
    git config user.name "!GIT_NAME!"
    git config user.email "!GIT_EMAIL!"
    echo [SUCCESS] Git user configuration set
)

REM Add all files
echo [INFO] Adding files to git...
git add .
echo [SUCCESS] Files added to staging area

REM Check if there are any changes to commit
git diff --staged --quiet
if errorlevel 1 (
    REM Commit changes
    echo [INFO] Committing changes...
    git commit -m "Initial commit: LabSyncPro Authentication System - Complete authentication system with email/password and OAuth - Role-based access control (6 user roles) - Email verification and password reset - Dark/light mode toggle - Responsive design with modern UI - TypeScript implementation with Supabase integration - Production-ready authentication flows"
    echo [SUCCESS] Changes committed
) else (
    echo [WARNING] No changes to commit
)

REM Push to remote repository
echo [INFO] Pushing to remote repository...
git push -u origin main >nul 2>&1
if errorlevel 1 (
    git push -u origin master >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Failed to push. Trying to set upstream...
        git push --set-upstream origin main >nul 2>&1
        if errorlevel 1 (
            git push --set-upstream origin master >nul 2>&1
            if errorlevel 1 (
                echo [ERROR] Failed to push to remote repository
                echo [INFO] Please check your repository URL and permissions
                pause
                exit /b 1
            ) else (
                echo [SUCCESS] Successfully pushed and set upstream to master
            )
        ) else (
            echo [SUCCESS] Successfully pushed and set upstream to main
        )
    ) else (
        echo [SUCCESS] Successfully pushed to master branch
    )
) else (
    echo [SUCCESS] Successfully pushed to main branch
)

echo.
echo [SUCCESS] 🎉 Git repository setup completed successfully!
echo.
echo [INFO] Repository URL: !REPO_URL!
echo [INFO] You can now view your code on GitHub/GitLab
echo.
echo [INFO] Next steps:
echo   1. Set up deployment on Render/Vercel
echo   2. Configure environment variables
echo   3. Set up database schema in Supabase
echo.
pause
