export type UserRole = 'super_admin' | 'admin' | 'lab_manager' | 'instructor' | 'student' | 'lab_staff';

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string;
          email: string;
          first_name: string;
          last_name: string;
          role: UserRole;
          phone_number: string | null;
          employee_id: string | null;
          student_id: string | null;
          department: string | null;
          is_active: boolean;
          is_archived: boolean;
          profile_image_url: string | null;
          last_login: string | null;
          archived_at: string | null;
          archived_by: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          email: string;
          first_name: string;
          last_name: string;
          role?: UserRole;
          phone_number?: string | null;
          employee_id?: string | null;
          student_id?: string | null;
          department?: string | null;
          is_active?: boolean;
          is_archived?: boolean;
          profile_image_url?: string | null;
        };
        Update: {
          first_name?: string;
          last_name?: string;
          role?: UserRole;
          phone_number?: string | null;
          employee_id?: string | null;
          student_id?: string | null;
          department?: string | null;
          profile_image_url?: string | null;
          last_login?: string | null;
        };
      };
      labs: {
        Row: {
          id: string;
          name: string;
          code: string;
          description: string | null;
          location: string;
          floor_number: number | null;
          capacity: number;
          lab_manager_id: string | null;
          is_active: boolean;
          is_archived: boolean;
          archived_at: string | null;
          archived_by: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          name: string;
          code: string;
          description?: string | null;
          location: string;
          floor_number?: number | null;
          capacity?: number;
          lab_manager_id?: string | null;
          is_active?: boolean;
          is_archived?: boolean;
        };
        Update: {
          name?: string;
          code?: string;
          description?: string | null;
          location?: string;
          floor_number?: number | null;
          capacity?: number;
          lab_manager_id?: string | null;
          is_active?: boolean;
        };
      };
      equipment_categories: {
        Row: {
          id: string;
          name: string;
          code: string;
          description: string | null;
          parent_category_id: string | null;
          is_consumable: boolean;
          created_at: string;
        };
        Insert: {
          name: string;
          code: string;
          description?: string | null;
          parent_category_id?: string | null;
          is_consumable?: boolean;
        };
        Update: {
          name?: string;
          code?: string;
          description?: string | null;
          parent_category_id?: string | null;
          is_consumable?: boolean;
        };
      };
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      [_ in never]: never;
    };
    Enums: {
      user_role: UserRole;
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
}
