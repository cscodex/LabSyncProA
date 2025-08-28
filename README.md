# LabSyncPro - Laboratory Management System

A comprehensive laboratory management system built with Next.js 14, TypeScript, Supabase, and Tailwind CSS.

## Features

### 🔐 Authentication System
- **Email/Password Authentication** with strong password requirements
- **Social Authentication** (Google & Apple OAuth)
- **Email Verification** for new registrations
- **Password Reset** functionality
- **Role-based Access Control** (Super Admin, Admin, Lab Manager, Instructor, Lab Staff, Student)
- **Profile Completion** flow for social auth users
- **Dark/Light Mode** toggle

### 🏢 Laboratory Management
- Equipment tracking and management
- Inventory management (consumables & durable items)
- Lab scheduling and booking system
- Student and staff management
- Course and practical session management

### 📊 Advanced Features
- Multi-criteria grading system
- Real-time notifications and alerts
- Comprehensive reporting and analytics
- Audit trails and activity logging
- File upload and storage
- QR code integration for equipment

## Tech Stack

- **Frontend**: Next.js 14 (App Router), TypeScript, Tailwind CSS
- **UI Components**: shadcn/ui, Radix UI
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Real-time)
- **State Management**: Zustand
- **Form Handling**: React Hook Form + Zod validation
- **Styling**: Tailwind CSS with custom design system
- **Icons**: Lucide React
- **Notifications**: Sonner

## Quick Start

### Prerequisites

- Node.js 18+ and npm/yarn
- Supabase account
- Google OAuth credentials (optional)
- Apple OAuth credentials (optional)

### 1. Clone and Install

```bash
git clone <repository-url>
cd labsyncpro
npm install
```

### 2. Environment Setup

Copy the environment template:

```bash
cp .env.example .env.local
```

Update `.env.local` with your Supabase credentials:

```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

### 3. Database Setup

1. Create a new Supabase project
2. Run the database schema from `labsyncpro_schema` file
3. Enable Row Level Security (RLS) on all tables
4. Configure authentication providers in Supabase dashboard

### 4. OAuth Setup (Optional)

#### Google OAuth:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create OAuth 2.0 credentials
3. Add authorized redirect URI: `https://your-project.supabase.co/auth/v1/callback`
4. Add credentials to Supabase Auth settings

#### Apple OAuth:
1. Go to [Apple Developer Console](https://developer.apple.com/)
2. Create a Sign in with Apple service
3. Configure redirect URI: `https://your-project.supabase.co/auth/v1/callback`
4. Add credentials to Supabase Auth settings

### 5. Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Project Structure

```
labsyncpro/
├── app/                          # Next.js 14 App Router
│   ├── (auth)/                   # Authentication pages
│   │   ├── login/
│   │   ├── register/
│   │   ├── reset-password/
│   │   ├── update-password/
│   │   ├── callback/
│   │   └── complete-profile/
│   ├── dashboard/                # Main application
│   ├── globals.css              # Global styles
│   ├── layout.tsx               # Root layout
│   └── page.tsx                 # Landing page
├── components/                   # Reusable components
│   ├── ui/                      # UI components (shadcn/ui)
│   ├── auth/                    # Authentication components
│   ├── theme-provider.tsx       # Theme provider
│   └── theme-toggle.tsx         # Dark/light mode toggle
├── contexts/                     # React contexts
│   └── auth-context.tsx         # Authentication context
├── lib/                         # Utility libraries
│   ├── supabase.ts             # Supabase client configuration
│   ├── utils.ts                # Utility functions
│   └── validations/            # Form validation schemas
├── types/                       # TypeScript type definitions
│   ├── auth.types.ts           # Authentication types
│   └── database.types.ts       # Database types
└── public/                      # Static assets
```

## Authentication Flow

### Registration Process
1. User fills registration form with role selection
2. Email verification sent automatically
3. User profile created in database
4. Role-specific fields validated (Employee ID for staff, Student ID for students)
5. Email confirmation required before account activation

### Social Authentication
1. OAuth flow with Google/Apple
2. User profile created automatically
3. Profile completion flow for missing information
4. Seamless integration with existing accounts

### Security Features
- Password strength validation (8+ chars, uppercase, lowercase, numbers, special chars)
- Rate limiting on authentication attempts
- Secure session management
- Row Level Security (RLS) on all database tables
- Role-based access control throughout the application

## Database Schema

The system uses a comprehensive PostgreSQL schema with:

- **Users table** with extended profiles and role management
- **Labs table** for physical laboratory spaces
- **Equipment tables** for durable and consumable inventory
- **Academic tables** for courses, sessions, and grading
- **Activity logs** for comprehensive audit trails
- **Notification system** for alerts and messages

See `labsyncpro_schema` file for complete database structure.

## Development Guidelines

### Code Style
- Use TypeScript for all new code
- Follow ESLint and Prettier configurations
- Use functional components with hooks
- Implement proper error handling and loading states

### Component Structure
- Keep components small and focused
- Use composition over inheritance
- Implement proper TypeScript interfaces
- Follow accessibility guidelines (WCAG)

### State Management
- Use React Context for global state (auth, theme)
- Use local state for component-specific data
- Implement proper loading and error states
- Use React Query for server state management

## Deployment

### Vercel (Recommended)
1. Connect your GitHub repository to Vercel
2. Add environment variables in Vercel dashboard
3. Deploy automatically on push to main branch

### Other Platforms
The application can be deployed on any platform that supports Next.js:
- Netlify
- Railway
- DigitalOcean App Platform
- AWS Amplify

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the GitHub repository
- Check the documentation
- Contact the development team

---

Built with ❤️ for educational institutions worldwide.
