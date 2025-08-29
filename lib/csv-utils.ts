import type { UserRole } from '@/types/database.types';

export interface ImportUser {
  email: string;
  first_name: string;
  last_name: string;
  role: UserRole;
  department?: string;
  employee_id?: string;
  student_id?: string;
  phone_number?: string;
}

export interface ExportUser {
  email: string;
  first_name: string;
  last_name: string;
  role: string;
  department: string;
  employee_id: string;
  student_id: string;
  phone_number: string;
  is_active: string;
  created_at: string;
  last_login: string;
}

// CSV parsing utility
export const parseCSV = (csvText: string): string[][] => {
  const lines = csvText.split('\n');
  const result: string[][] = [];
  
  for (const line of lines) {
    if (line.trim() === '') continue;
    
    const row: string[] = [];
    let current = '';
    let inQuotes = false;
    
    for (let i = 0; i < line.length; i++) {
      const char = line[i];
      
      if (char === '"') {
        inQuotes = !inQuotes;
      } else if (char === ',' && !inQuotes) {
        row.push(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    
    row.push(current.trim());
    result.push(row);
  }
  
  return result;
};

// Convert CSV data to user objects
export const csvToUsers = (csvData: string[][]): ImportUser[] => {
  if (csvData.length < 2) {
    throw new Error('CSV must contain at least a header row and one data row');
  }
  
  const headers = csvData[0].map(h => h.toLowerCase().trim());
  const users: ImportUser[] = [];
  
  // Required headers
  const requiredHeaders = ['email', 'first_name', 'last_name', 'role'];
  const missingHeaders = requiredHeaders.filter(h => !headers.includes(h));
  
  if (missingHeaders.length > 0) {
    throw new Error(`Missing required headers: ${missingHeaders.join(', ')}`);
  }
  
  for (let i = 1; i < csvData.length; i++) {
    const row = csvData[i];
    if (row.length === 0 || row.every(cell => cell.trim() === '')) continue;
    
    const user: Partial<ImportUser> = {};
    
    headers.forEach((header, index) => {
      const value = row[index]?.trim() || '';
      
      switch (header) {
        case 'email':
          user.email = value;
          break;
        case 'first_name':
          user.first_name = value;
          break;
        case 'last_name':
          user.last_name = value;
          break;
        case 'role':
          if (!['super_admin', 'admin', 'lab_manager', 'instructor', 'lab_staff', 'student'].includes(value)) {
            throw new Error(`Invalid role "${value}" in row ${i + 1}. Valid roles: super_admin, admin, lab_manager, instructor, lab_staff, student`);
          }
          user.role = value as UserRole;
          break;
        case 'department':
          user.department = value || undefined;
          break;
        case 'employee_id':
          user.employee_id = value || undefined;
          break;
        case 'student_id':
          user.student_id = value || undefined;
          break;
        case 'phone_number':
          user.phone_number = value || undefined;
          break;
      }
    });
    
    // Validate required fields
    if (!user.email || !user.first_name || !user.last_name || !user.role) {
      throw new Error(`Missing required fields in row ${i + 1}`);
    }
    
    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(user.email)) {
      throw new Error(`Invalid email format "${user.email}" in row ${i + 1}`);
    }
    
    users.push(user as ImportUser);
  }
  
  return users;
};

// Convert users to CSV format
export const usersToCSV = (users: ExportUser[]): string => {
  if (users.length === 0) return '';
  
  const headers = [
    'email',
    'first_name', 
    'last_name',
    'role',
    'department',
    'employee_id',
    'student_id',
    'phone_number',
    'is_active',
    'created_at',
    'last_login'
  ];
  
  const csvRows = [headers.join(',')];
  
  users.forEach(user => {
    const row = headers.map(header => {
      const value = user[header as keyof ExportUser] || '';
      // Escape commas and quotes
      if (value.includes(',') || value.includes('"') || value.includes('\n')) {
        return `"${value.replace(/"/g, '""')}"`;
      }
      return value;
    });
    csvRows.push(row.join(','));
  });
  
  return csvRows.join('\n');
};

// Generate CSV template
export const generateUserTemplate = (): string => {
  const headers = [
    'email',
    'first_name',
    'last_name', 
    'role',
    'department',
    'employee_id',
    'student_id',
    'phone_number'
  ];
  
  const sampleData = [
    'john.doe@university.edu',
    'John',
    'Doe',
    'student',
    'Computer Science',
    '',
    'CS2024001',
    '+1234567890'
  ];
  
  return [headers.join(','), sampleData.join(',')].join('\n');
};

// Download file utility
export const downloadFile = (content: string, filename: string, mimeType: string = 'text/csv') => {
  const blob = new Blob([content], { type: mimeType });
  const url = window.URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  window.URL.revokeObjectURL(url);
};

// Read file utility
export const readFile = (file: File): Promise<string> => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      const result = e.target?.result;
      if (typeof result === 'string') {
        resolve(result);
      } else {
        reject(new Error('Failed to read file'));
      }
    };
    reader.onerror = () => reject(new Error('Failed to read file'));
    reader.readAsText(file);
  });
};
