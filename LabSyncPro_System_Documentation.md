# LabSyncPro - Laboratory Management System
## System Functional Design & Capabilities Documentation

### Overview
LabSyncPro is a comprehensive laboratory management system designed for educational institutions to manage laboratory resources, practical sessions, student activities, and inventory. The system is built on Supabase (PostgreSQL) with advanced features including role-based access control, automated alerts, and comprehensive audit trails.

### Core System Architecture

#### Database Foundation
- **Platform**: Supabase (PostgreSQL)
- **Security**: Row Level Security (RLS) enabled on all tables
- **Extensions**: UUID generation, JSONB support
- **Audit Trail**: Comprehensive activity logging
- **Data Integrity**: Foreign key constraints, triggers, and validation

#### User Management & Authentication

**User Roles & Hierarchy:**
- **Super Admin**: Full system access and control
- **Admin**: Administrative functions across the system
- **Lab Manager**: Manages specific laboratories and their resources
- **Instructor**: Manages courses, practical sessions, and student grading
- **Lab Staff**: Assists with lab operations and equipment management
- **Student**: Participates in practical sessions and submits work

**User Features:**
- Extended user profiles with archival support
- Employee/Student ID management
- Department-based organization
- Profile image support
- Last login tracking
- Soft delete with archival functionality

### Laboratory Management

#### Physical Lab Spaces
- **Lab Registration**: Name, code, location, floor, capacity
- **Lab Manager Assignment**: Primary manager with delegation support
- **Staff Assignments**: Multi-role staff assignments (manager, assistant, technician)
- **Archival Support**: Soft delete with audit trail

#### Lab Scheduling System
- **Booking Management**: Prevent double-booking with conflict detection
- **Schedule Types**: One-time and recurring schedules
- **Status Tracking**: Scheduled, confirmed, in-progress, completed, cancelled
- **Integration**: Links with practical sessions
- **Conflict Prevention**: Automated overlap detection

### Inventory Management

#### Durable Equipment Management
- **Asset Tracking**: Unique asset tags and serial numbers
- **Categorization**: Hierarchical category system
- **Status Management**: Available, in-use, maintenance, damaged, retired
- **Condition Tracking**: Excellent, good, fair, poor, damaged
- **Location Management**: Lab assignment and specific location details
- **QR Code Support**: For mobile scanning and tracking
- **Warranty Management**: Purchase date, warranty expiry tracking
- **Supplier Information**: Vendor management and procurement history

#### Consumable Inventory System
- **Stock Management**: Current stock, reorder levels, maximum stock levels
- **Unit Tracking**: Flexible unit of measurement (pieces, meters, liters, etc.)
- **Cost Management**: Unit cost tracking and total cost calculations
- **Multi-Lab Stock**: Per-lab stock allocation and tracking
- **Transaction Logging**: Stock in/out, adjustments, expired, damaged
- **Automated Alerts**: Low stock, out of stock, reorder notifications

#### Equipment Operations
- **Check-out/Check-in System**: Automated equipment assignment
- **Usage Logging**: Who used what, when, and for how long
- **Condition Monitoring**: Before/after condition tracking
- **Issue Reporting**: Problem reporting and alert generation
- **Transfer Management**: Inter-lab equipment transfers
- **Maintenance Scheduling**: Preventive and corrective maintenance

### Academic Management

#### Course Management
- **Course Registration**: Code, name, department, credits, semester
- **Instructor Assignment**: Primary instructor management
- **Student Enrollment**: Course enrollment tracking
- **Archival Support**: Historical course data preservation

#### Student Organization
- **Student Groups/Batches**: Organized groups for practical sessions
- **Group Memberships**: Student assignment to groups
- **Capacity Management**: Maximum students per group
- **Instructor Assignment**: Group supervision

### Practical Session Management

#### Session Planning
- **Session Scheduling**: Date, time, duration, lab assignment
- **Resource Requirements**: Equipment and consumable requirements
- **Learning Objectives**: JSONB storage for flexible objectives
- **Instructions**: Detailed session instructions
- **Status Tracking**: Scheduled, in-progress, completed, cancelled

#### Attendance Management
- **Real-time Tracking**: Present, absent, late, excused status
- **Check-in/Check-out**: Time-based attendance logging
- **Instructor Notes**: Additional attendance notes
- **Automated Reporting**: Attendance analytics

#### Resource Allocation
- **Equipment Requirements**: Mandatory and optional equipment
- **Consumable Requirements**: Required quantities per session
- **Availability Checking**: Resource conflict detection
- **Automatic Allocation**: Smart resource assignment

### Advanced Grading System

#### Multi-Criteria Grading
- **Grading Rubrics**: Flexible rubric creation per session/course
- **Grading Criteria**: Multiple criteria per rubric
- **Criterion Types**: Numeric, percentage, letter, boolean, text
- **Weight Management**: Percentage-based criterion weighting
- **Automated Calculation**: Overall grade computation

#### Submission Management
- **File Submissions**: JSONB storage for multiple file types
- **Text Submissions**: Rich text submission support
- **Late Submission Tracking**: Automatic late submission detection
- **Status Management**: Pending, submitted, graded, late
- **Feedback System**: Detailed instructor feedback

#### Grade Analytics
- **Individual Grades**: Per-criterion grade tracking
- **Overall Grades**: Weighted grade calculation
- **Grade History**: Complete grading audit trail
- **Performance Analytics**: Student and session performance metrics

### Notification & Alert System

#### Automated Alerts
- **Equipment Alerts**: Maintenance due, warranty expiring, repair needed
- **Consumable Alerts**: Low stock, out of stock, expired items
- **Priority Levels**: Low, medium, high, critical
- **Resolution Tracking**: Alert acknowledgment and resolution

#### User Notifications
- **Personal Notifications**: User-specific notifications
- **System Messages**: Info, warning, error, success types
- **Read Status**: Notification read/unread tracking
- **Entity Linking**: Related entity references

### Security & Access Control

#### Row Level Security (RLS)
- **Table-Level Security**: All tables protected with RLS
- **Role-Based Access**: Permissions based on user roles
- **Data Isolation**: Users see only relevant data
- **Hierarchical Access**: Manager access to subordinate data

#### Audit & Compliance
- **Activity Logging**: Complete audit trail of all actions
- **Change Tracking**: Old/new value comparison
- **User Attribution**: Action attribution to specific users
- **IP Tracking**: Source IP and user agent logging
- **Compliance Ready**: Audit trail for regulatory compliance

### Analytics & Reporting

#### Equipment Analytics
- **Usage Statistics**: Equipment utilization metrics
- **Condition Trends**: Equipment condition over time
- **Issue Tracking**: Problem frequency and resolution
- **Maintenance Analytics**: Maintenance cost and frequency

#### Lab Utilization
- **Booking Analytics**: Lab usage patterns
- **Capacity Analysis**: Utilization vs. capacity metrics
- **Staff Allocation**: Staff assignment effectiveness
- **Resource Optimization**: Equipment and space optimization

#### Academic Analytics
- **Student Performance**: Grade trends and analytics
- **Session Effectiveness**: Practical session success metrics
- **Attendance Patterns**: Attendance trend analysis
- **Resource Usage**: Academic resource utilization

### Advanced Features

#### Automated Workflows
- **Stock Management**: Automatic stock updates from transactions
- **Grade Calculation**: Automated overall grade computation
- **Alert Generation**: Smart alert creation based on thresholds
- **Schedule Validation**: Automatic conflict detection

#### Data Views & Reporting
- **Equipment Details**: Comprehensive equipment information
- **Session Details**: Complete practical session data
- **Student Submissions**: Detailed submission analytics
- **Stock Status**: Real-time inventory status
- **Lab Utilization**: Lab usage and capacity metrics

#### Stored Procedures
- **Equipment Checkout**: Automated checkout with validation
- **Equipment Checkin**: Automated checkin with condition tracking
- **Conflict Detection**: Schedule and resource conflict prevention
- **Stock Updates**: Automated inventory management

### Integration Capabilities

#### External System Integration
- **Authentication**: Supabase Auth integration
- **File Storage**: JSONB support for file references
- **API Ready**: RESTful API through Supabase
- **Real-time Updates**: Subscription-based real-time data

#### Mobile Support
- **QR Code Integration**: Equipment scanning capability
- **Responsive Design**: Mobile-friendly data structure
- **Offline Capability**: Local data caching support

### Scalability & Performance

#### Database Optimization
- **Strategic Indexing**: Performance-optimized indexes
- **Query Optimization**: Efficient data retrieval
- **Archival System**: Historical data management
- **Soft Deletes**: Data preservation with performance

#### Growth Support
- **Hierarchical Categories**: Scalable categorization
- **Multi-Lab Support**: Institution-wide deployment
- **Department Isolation**: Department-based data separation
- **Role Scalability**: Flexible role management

This comprehensive system provides educational institutions with a complete solution for laboratory management, combining inventory control, academic management, and advanced analytics in a secure, scalable platform.

### Detailed System Capabilities

#### Equipment Management Workflows

**Equipment Lifecycle Management:**
1. **Procurement**: Equipment registration with supplier, purchase details, warranty information
2. **Deployment**: Lab assignment, location setup, QR code generation
3. **Operation**: Check-out/check-in cycles, usage tracking, condition monitoring
4. **Maintenance**: Scheduled maintenance, repair tracking, cost management
5. **Transfer**: Inter-lab transfers with approval workflows
6. **Retirement**: End-of-life management with archival

**Smart Equipment Features:**
- **Automated Status Updates**: Status changes based on usage and condition
- **Predictive Maintenance**: Alert generation based on usage patterns
- **Conflict Resolution**: Automatic handling of equipment booking conflicts
- **Usage Analytics**: Detailed utilization reports and optimization suggestions

#### Consumable Management Workflows

**Stock Management Process:**
1. **Procurement**: Supplier management, cost tracking, bulk ordering
2. **Distribution**: Multi-lab stock allocation and tracking
3. **Usage**: Session-based consumption tracking
4. **Monitoring**: Real-time stock level monitoring
5. **Reordering**: Automated reorder alerts and procurement workflows
6. **Waste Management**: Expired and damaged item tracking

**Advanced Stock Features:**
- **Multi-Unit Support**: Flexible measurement units (pieces, meters, liters, kg)
- **Cost Analysis**: Unit cost tracking and budget management
- **Expiry Management**: Date-based expiry tracking and alerts
- **Batch Tracking**: Lot/batch number management for quality control

#### Academic Session Management

**Session Planning Workflow:**
1. **Course Setup**: Course creation with learning objectives
2. **Group Formation**: Student batch creation and enrollment
3. **Resource Planning**: Equipment and consumable requirement definition
4. **Scheduling**: Lab booking with conflict detection
5. **Execution**: Real-time session management and tracking
6. **Assessment**: Multi-criteria grading and feedback

**Session Execution Features:**
- **Real-time Attendance**: Live attendance tracking with mobile support
- **Resource Allocation**: Dynamic equipment assignment during sessions
- **Progress Monitoring**: Session status tracking and notifications
- **Emergency Protocols**: Safety and emergency response integration

#### Advanced Grading Capabilities

**Flexible Assessment Framework:**
- **Custom Rubrics**: Institution-specific grading criteria
- **Multi-Modal Assessment**: Support for practical, theoretical, and project-based evaluation
- **Peer Assessment**: Student peer evaluation capabilities
- **Continuous Assessment**: Ongoing evaluation throughout the session
- **Grade Analytics**: Performance trend analysis and improvement suggestions

**Grade Management Features:**
- **Weighted Calculations**: Complex grade weighting algorithms
- **Grade Curves**: Statistical grade adjustment capabilities
- **Late Penalty Management**: Automated late submission penalties
- **Grade Appeals**: Grade review and appeal workflow
- **Transcript Integration**: Academic record management

#### Security & Compliance Framework

**Data Protection:**
- **Encryption**: Data encryption at rest and in transit
- **Access Logging**: Comprehensive access audit trails
- **Data Retention**: Configurable data retention policies
- **Privacy Controls**: GDPR/FERPA compliance features
- **Backup & Recovery**: Automated backup and disaster recovery

**Role-Based Security:**
- **Granular Permissions**: Fine-grained access control
- **Delegation**: Temporary permission delegation
- **Multi-Factor Authentication**: Enhanced security for sensitive operations
- **Session Management**: Secure session handling and timeout
- **API Security**: Secure API access with rate limiting

#### Integration & Extensibility

**System Integrations:**
- **LMS Integration**: Learning Management System connectivity
- **ERP Integration**: Enterprise Resource Planning system links
- **Financial Systems**: Budget and procurement system integration
- **Identity Providers**: LDAP, Active Directory, SSO integration
- **Mobile Apps**: Native mobile application support

**API Capabilities:**
- **RESTful APIs**: Complete REST API coverage
- **Real-time APIs**: WebSocket support for live updates
- **Webhook Support**: Event-driven external system notifications
- **Bulk Operations**: Efficient bulk data import/export
- **Custom Extensions**: Plugin architecture for custom features

#### Reporting & Analytics Engine

**Operational Reports:**
- **Equipment Utilization**: Usage patterns and optimization opportunities
- **Lab Efficiency**: Space and resource utilization metrics
- **Maintenance Analytics**: Cost analysis and scheduling optimization
- **Inventory Reports**: Stock levels, consumption patterns, procurement needs
- **Safety Reports**: Incident tracking and safety compliance

**Academic Reports:**
- **Student Performance**: Individual and cohort performance analysis
- **Course Effectiveness**: Learning outcome achievement metrics
- **Attendance Analytics**: Attendance patterns and intervention triggers
- **Grade Distribution**: Statistical grade analysis and benchmarking
- **Resource Impact**: Correlation between resources and learning outcomes

**Administrative Reports:**
- **Cost Analysis**: Operational cost breakdown and budget tracking
- **Compliance Reports**: Regulatory compliance and audit reports
- **Usage Trends**: Historical usage patterns and forecasting
- **Staff Performance**: Staff efficiency and workload analysis
- **System Health**: Technical performance and system optimization

#### Mobile & Modern Features

**Mobile Capabilities:**
- **QR Code Scanning**: Equipment and consumable identification
- **Offline Support**: Limited offline functionality for critical operations
- **Push Notifications**: Real-time alerts and updates
- **Mobile Attendance**: Smartphone-based attendance tracking
- **Field Reporting**: Mobile incident and maintenance reporting

**Modern UI/UX Features:**
- **Responsive Design**: Multi-device compatibility
- **Progressive Web App**: App-like experience in browsers
- **Dark Mode**: User preference-based theming
- **Accessibility**: WCAG compliance for inclusive design
- **Internationalization**: Multi-language support

### Implementation Considerations

#### Deployment Architecture
- **Cloud-Native**: Designed for cloud deployment (Supabase)
- **Scalable Infrastructure**: Auto-scaling capabilities
- **High Availability**: Redundancy and failover support
- **Performance Optimization**: Caching and query optimization
- **Monitoring**: Comprehensive system monitoring and alerting

#### Data Migration & Setup
- **Migration Tools**: Automated data import from legacy systems
- **Configuration Management**: Flexible system configuration
- **Training Materials**: Comprehensive user training resources
- **Support Documentation**: Detailed technical documentation
- **Best Practices**: Implementation guidelines and recommendations

This system represents a complete digital transformation solution for laboratory management in educational institutions, providing efficiency, transparency, and data-driven decision-making capabilities.

## Database Schema Improvements & Suggestions

### Critical Schema Enhancements

#### 1. Performance Optimizations
```sql
-- Add composite indexes for common query patterns
CREATE INDEX idx_equipment_lab_status_condition ON public.equipment(lab_id, status, condition) WHERE is_archived = false;
CREATE INDEX idx_practical_sessions_date_lab ON public.practical_sessions(scheduled_date, lab_id) WHERE is_archived = false;
CREATE INDEX idx_consumable_transactions_date_type ON public.consumable_transactions(transaction_date, transaction_type);
CREATE INDEX idx_equipment_usage_active ON public.equipment_usage_log(equipment_id, checked_out_at) WHERE checked_in_at IS NULL;

-- Add partial indexes for better performance
CREATE INDEX idx_users_active_role ON public.users(role, department) WHERE is_archived = false AND is_active = true;
CREATE INDEX idx_equipment_available ON public.equipment(lab_id, category_id) WHERE status = 'available' AND is_archived = false;
```

#### 2. Data Integrity Improvements
```sql
-- Add check constraints for business rules
ALTER TABLE public.equipment ADD CONSTRAINT check_warranty_dates
    CHECK (warranty_end_date IS NULL OR warranty_end_date >= purchase_date);

ALTER TABLE public.practical_sessions ADD CONSTRAINT check_session_duration
    CHECK (duration_minutes > 0 AND duration_minutes <= 480); -- Max 8 hours

ALTER TABLE public.consumables ADD CONSTRAINT check_stock_levels
    CHECK (current_stock >= 0 AND reorder_level >= 0 AND max_stock_level > reorder_level);

-- Add unique constraints for business logic
ALTER TABLE public.equipment ADD CONSTRAINT unique_asset_tag_active
    EXCLUDE (asset_tag WITH =) WHERE (is_archived = false);
```

#### 3. Missing Essential Tables
```sql
-- Equipment Reservations (for advance booking)
CREATE TABLE public.equipment_reservations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    equipment_id UUID REFERENCES public.equipment(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    practical_session_id UUID REFERENCES public.practical_sessions(id),
    reserved_from TIMESTAMPTZ NOT NULL,
    reserved_until TIMESTAMPTZ NOT NULL,
    status TEXT CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')) DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT check_reservation_times CHECK (reserved_from < reserved_until)
);

-- System Configuration
CREATE TABLE public.system_settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    setting_key TEXT UNIQUE NOT NULL,
    setting_value JSONB NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT false,
    updated_by UUID REFERENCES public.users(id),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- File Attachments (for submissions, maintenance records, etc.)
CREATE TABLE public.file_attachments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    filename TEXT NOT NULL,
    original_filename TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type TEXT NOT NULL,
    file_path TEXT NOT NULL,
    entity_type TEXT NOT NULL, -- 'submission', 'maintenance', 'equipment', etc.
    entity_id UUID NOT NULL,
    uploaded_by UUID REFERENCES public.users(id),
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Backup and Restore Logs
CREATE TABLE public.backup_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    backup_type TEXT CHECK (backup_type IN ('manual', 'scheduled', 'emergency')) NOT NULL,
    status TEXT CHECK (status IN ('started', 'completed', 'failed')) NOT NULL,
    file_path TEXT,
    file_size BIGINT,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    error_message TEXT,
    initiated_by UUID REFERENCES public.users(id)
);
```

#### 4. Enhanced Audit and Versioning
```sql
-- Version control for critical entities
CREATE TABLE public.entity_versions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    entity_type TEXT NOT NULL,
    entity_id UUID NOT NULL,
    version_number INTEGER NOT NULL,
    data_snapshot JSONB NOT NULL,
    change_summary TEXT,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(entity_type, entity_id, version_number)
);

-- Enhanced activity logs with more context
ALTER TABLE public.activity_logs ADD COLUMN session_id TEXT;
ALTER TABLE public.activity_logs ADD COLUMN request_id TEXT;
ALTER TABLE public.activity_logs ADD COLUMN duration_ms INTEGER;
ALTER TABLE public.activity_logs ADD COLUMN affected_rows INTEGER;
```

#### 5. Advanced Features Tables
```sql
-- Equipment Calibration Records
CREATE TABLE public.equipment_calibrations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    equipment_id UUID REFERENCES public.equipment(id) ON DELETE CASCADE,
    calibration_date TIMESTAMPTZ NOT NULL,
    next_calibration_date TIMESTAMPTZ,
    calibrated_by UUID REFERENCES public.users(id),
    calibration_standard TEXT,
    results JSONB,
    certificate_number TEXT,
    is_passed BOOLEAN NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Lab Safety Incidents
CREATE TABLE public.safety_incidents (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    lab_id UUID REFERENCES public.labs(id),
    incident_date TIMESTAMPTZ NOT NULL,
    incident_type TEXT CHECK (incident_type IN ('injury', 'equipment_damage', 'chemical_spill', 'fire', 'other')) NOT NULL,
    severity TEXT CHECK (severity IN ('minor', 'moderate', 'major', 'critical')) NOT NULL,
    description TEXT NOT NULL,
    people_involved JSONB, -- Array of user IDs
    equipment_involved JSONB, -- Array of equipment IDs
    immediate_actions TEXT,
    follow_up_required BOOLEAN DEFAULT false,
    reported_by UUID REFERENCES public.users(id),
    investigated_by UUID REFERENCES public.users(id),
    status TEXT CHECK (status IN ('reported', 'investigating', 'resolved', 'closed')) DEFAULT 'reported',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Equipment Depreciation
CREATE TABLE public.equipment_depreciation (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    equipment_id UUID REFERENCES public.equipment(id) ON DELETE CASCADE,
    depreciation_method TEXT CHECK (depreciation_method IN ('straight_line', 'declining_balance', 'units_of_production')) NOT NULL,
    useful_life_years INTEGER NOT NULL,
    salvage_value DECIMAL(10,2) DEFAULT 0,
    annual_depreciation DECIMAL(10,2),
    accumulated_depreciation DECIMAL(10,2) DEFAULT 0,
    book_value DECIMAL(10,2),
    last_calculated TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Schema Optimization Recommendations

#### 1. Partitioning Strategy
```sql
-- Partition activity_logs by date for better performance
CREATE TABLE public.activity_logs_partitioned (
    LIKE public.activity_logs INCLUDING ALL
) PARTITION BY RANGE (created_at);

-- Create monthly partitions
CREATE TABLE activity_logs_2024_01 PARTITION OF public.activity_logs_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

#### 2. Materialized Views for Analytics
```sql
-- Equipment utilization summary
CREATE MATERIALIZED VIEW equipment_utilization_summary AS
SELECT
    e.id,
    e.name,
    e.asset_tag,
    COUNT(eul.id) as usage_count,
    AVG(EXTRACT(EPOCH FROM (eul.checked_in_at - eul.checked_out_at))/3600) as avg_usage_hours,
    MAX(eul.checked_out_at) as last_used,
    COUNT(CASE WHEN eul.issues_reported IS NOT NULL THEN 1 END) as issue_count
FROM public.equipment e
LEFT JOIN public.equipment_usage_log eul ON e.id = eul.equipment_id
WHERE e.is_archived = false
GROUP BY e.id, e.name, e.asset_tag;

-- Refresh schedule
CREATE OR REPLACE FUNCTION refresh_materialized_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW equipment_utilization_summary;
    -- Add other materialized views here
END;
$$ LANGUAGE plpgsql;
```

#### 3. Advanced Triggers and Functions
```sql
-- Auto-archive old records
CREATE OR REPLACE FUNCTION auto_archive_old_records()
RETURNS void AS $$
BEGIN
    -- Archive old activity logs (older than 2 years)
    UPDATE public.activity_logs
    SET archived = true
    WHERE created_at < NOW() - INTERVAL '2 years' AND archived IS NOT true;

    -- Archive completed practical sessions (older than 1 year)
    UPDATE public.practical_sessions
    SET is_archived = true, archived_at = NOW(), archived_by = '00000000-0000-0000-0000-000000000000'::UUID
    WHERE status = 'completed' AND scheduled_date < NOW() - INTERVAL '1 year' AND is_archived = false;
END;
$$ LANGUAGE plpgsql;

-- Schedule auto-archiving
SELECT cron.schedule('auto-archive', '0 2 * * 0', 'SELECT auto_archive_old_records();');
```

## Rapid Development Tech Stack (1-Month Deadline)

### Recommended Technology Stack

#### **Frontend: Next.js 14 + TypeScript**
```json
{
  "framework": "Next.js 14 (App Router)",
  "language": "TypeScript",
  "styling": "Tailwind CSS + shadcn/ui",
  "state_management": "Zustand",
  "forms": "React Hook Form + Zod",
  "charts": "Recharts",
  "icons": "Lucide React",
  "notifications": "Sonner"
}
```

**Why This Stack:**
- **Next.js 14**: Server components, built-in optimization, rapid development
- **shadcn/ui**: Pre-built, customizable components (saves 2-3 weeks)
- **Tailwind CSS**: Rapid styling without custom CSS
- **TypeScript**: Type safety reduces debugging time
- **Zustand**: Lightweight state management (easier than Redux)

#### **Backend: Supabase (Already Chosen)**
```json
{
  "database": "PostgreSQL (Supabase)",
  "auth": "Supabase Auth",
  "storage": "Supabase Storage",
  "realtime": "Supabase Realtime",
  "edge_functions": "Supabase Edge Functions",
  "api": "Auto-generated REST + GraphQL"
}
```

**Why Supabase:**
- **Zero backend setup**: Database, auth, storage, APIs auto-generated
- **Real-time subscriptions**: Live updates for lab management
- **Row Level Security**: Built-in security model
- **File storage**: For equipment images, documents
- **Edge functions**: Custom business logic when needed

#### **Additional Tools & Libraries**

**Essential Libraries:**
```bash
# Core dependencies
npm install @supabase/supabase-js @supabase/auth-helpers-nextjs
npm install @tanstack/react-query @tanstack/react-table
npm install react-hook-form @hookform/resolvers zod
npm install zustand date-fns recharts
npm install @radix-ui/react-* # UI primitives
npm install lucide-react sonner

# Development tools
npm install -D @types/node @types/react eslint prettier
npm install -D tailwindcss postcss autoprefixer
```

**Key Features Implementation:**

1. **QR Code Support:**
```bash
npm install qr-code-generator react-qr-scanner
```

2. **File Upload:**
```bash
npm install react-dropzone
```

3. **PDF Generation:**
```bash
npm install @react-pdf/renderer
```

4. **Excel Export:**
```bash
npm install xlsx
```

### Development Timeline (4 Weeks)

#### **Week 1: Foundation & Core Setup**
```
Days 1-2: Project Setup
- Next.js project initialization
- Supabase project setup and schema deployment
- Authentication system implementation
- Basic routing and layout structure

Days 3-5: User Management
- User registration/login flows
- Role-based access control
- User profile management
- Basic dashboard layouts

Days 6-7: Database Integration
- Supabase client setup
- Type generation from database
- Basic CRUD operations
- Error handling patterns
```

#### **Week 2: Core Laboratory Management**
```
Days 8-10: Lab & Equipment Management
- Lab creation and management
- Equipment CRUD operations
- Equipment categorization
- Basic equipment listing and search

Days 11-12: Inventory System
- Consumable management
- Stock tracking
- Transaction logging
- Basic reporting

Days 13-14: Equipment Operations
- Check-out/check-in system
- Equipment status management
- Usage logging
- QR code integration
```

#### **Week 3: Academic Features**
```
Days 15-17: Course & Session Management
- Course creation and management
- Student group management
- Practical session scheduling
- Attendance tracking

Days 18-19: Grading System
- Rubric creation
- Grade entry and calculation
- Student submissions
- Basic reporting

Days 20-21: Advanced Features
- Notification system
- Alert management
- File upload/storage
- Basic analytics
```

#### **Week 4: Polish & Deployment**
```
Days 22-24: UI/UX Polish
- Responsive design refinement
- Loading states and error handling
- Form validation and user feedback
- Performance optimization

Days 25-26: Testing & Bug Fixes
- Component testing
- Integration testing
- Bug fixes and refinements
- Security review

Days 27-28: Deployment & Documentation
- Production deployment setup
- User documentation
- Admin documentation
- Training materials
```

### Rapid Development Strategies

#### **1. Use Pre-built Components**
```typescript
// Example: Using shadcn/ui components
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { DataTable } from "@/components/ui/data-table"

// Saves weeks of custom component development
```

#### **2. Leverage Supabase Auto-generated APIs**
```typescript
// No need to write backend APIs
const { data: equipment, error } = await supabase
  .from('equipment')
  .select(`
    *,
    equipment_categories(name),
    labs(name, location),
    suppliers(name)
  `)
  .eq('is_archived', false)
```

#### **3. Use React Query for Data Management**
```typescript
// Automatic caching, background updates, error handling
const useEquipment = () => {
  return useQuery({
    queryKey: ['equipment'],
    queryFn: () => fetchEquipment(),
    staleTime: 5 * 60 * 1000, // 5 minutes
  })
}
```

#### **4. Implement Progressive Features**
```
MVP Features (Week 1-2):
- Basic CRUD operations
- Simple authentication
- Core equipment management

Enhanced Features (Week 3):
- Advanced search and filtering
- Reporting and analytics
- File uploads

Polish Features (Week 4):
- Real-time updates
- Advanced notifications
- Mobile optimization
```

### Deployment Strategy

#### **Production Setup:**
```yaml
# Vercel deployment (recommended)
- Platform: Vercel (seamless Next.js integration)
- Database: Supabase (managed PostgreSQL)
- Storage: Supabase Storage
- CDN: Vercel Edge Network
- Monitoring: Vercel Analytics + Supabase Logs
```

#### **Environment Configuration:**
```bash
# .env.local
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### Risk Mitigation

#### **Technical Risks:**
1. **Complex Queries**: Use Supabase views for complex data
2. **Performance**: Implement pagination and caching early
3. **File Storage**: Use Supabase storage with CDN
4. **Real-time Updates**: Leverage Supabase subscriptions

#### **Timeline Risks:**
1. **Scope Creep**: Stick to MVP features first
2. **Integration Issues**: Test Supabase integration early
3. **UI Complexity**: Use pre-built components
4. **Testing Time**: Implement testing throughout development

### Additional Recommendations

#### **Code Generation Tools**
```bash
# Supabase type generation
npx supabase gen types typescript --project-id your-project-id > types/database.types.ts

# Prisma for additional type safety (optional)
npm install prisma @prisma/client
npx prisma init
npx prisma db pull --url "postgresql://..."
```

#### **Development Tools**
```bash
# Essential VS Code extensions
- ES7+ React/Redux/React-Native snippets
- Tailwind CSS IntelliSense
- TypeScript Importer
- Prettier - Code formatter
- ESLint
```

#### **Performance Optimization**
```typescript
// Image optimization
import Image from 'next/image'

// Dynamic imports for code splitting
const HeavyComponent = dynamic(() => import('./HeavyComponent'), {
  loading: () => <Skeleton />,
})

// Memoization for expensive calculations
const expensiveValue = useMemo(() => {
  return heavyCalculation(data)
}, [data])
```

#### **Testing Strategy**
```bash
# Testing libraries
npm install -D @testing-library/react @testing-library/jest-dom
npm install -D jest jest-environment-jsdom

# Component testing example
test('renders equipment list', () => {
  render(<EquipmentList />)
  expect(screen.getByText('Equipment')).toBeInTheDocument()
})
```

This comprehensive tech stack and development plan provides a realistic roadmap to deliver LabSyncPro within the 1-month deadline while maintaining quality and scalability. The key is leveraging pre-built solutions and focusing on core functionality first.
