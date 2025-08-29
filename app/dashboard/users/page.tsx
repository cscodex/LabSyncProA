'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { Search, Plus, Download, Upload, Filter, MoreHorizontal, UserCheck, UserX, Edit, Trash2, FileText, AlertTriangle } from 'lucide-react';
import { toast } from 'sonner';

import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog';
import { AddUserModal } from '@/components/modals/add-user-modal';
import { EditUserModal } from '@/components/modals/edit-user-modal';
import { DashboardHeader } from '@/components/layout/dashboard-header';

import { useAuth } from '@/contexts/auth-context';
import { createSupabaseClient } from '@/lib/supabase';
import { formatUserName, formatRole } from '@/lib/utils';
import { csvToUsers, usersToCSV, generateUserTemplate, downloadFile, readFile, type ImportUser, type ExportUser } from '@/lib/csv-utils';
import type { UserRole } from '@/types/database.types';

interface User {
  id: string;
  email: string;
  first_name: string;
  last_name: string;
  role: UserRole;
  department: string | null;
  is_active: boolean;
  employee_id: string | null;
  student_id: string | null;
  phone_number: string | null;
  created_at: string;
  last_login: string | null;
  email_verified?: boolean;
  registration_completed?: boolean;
}

export default function UserManagementPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [filteredUsers, setFilteredUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [importing, setImporting] = useState(false);
  const [exporting, setExporting] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [roleFilter, setRoleFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [departmentFilter, setDepartmentFilter] = useState<string>('all');

  // Modal states
  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [modalLoading, setModalLoading] = useState(false);

  const fileInputRef = useRef<HTMLInputElement>(null);
  const { user, loading: authLoading } = useAuth();
  const router = useRouter();
  const supabase = createSupabaseClient();

  // Check permissions
  useEffect(() => {
    if (!authLoading && (!user || !['admin', 'super_admin'].includes(user.role))) {
      router.push('/dashboard');
      toast.error('You do not have permission to access user management.');
    }
  }, [user, authLoading, router]);

  // Fetch users
  const fetchUsers = useCallback(async () => {
    if (!user || !['admin', 'super_admin'].includes(user.role)) return;

    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;

      setUsers(data || []);
      setFilteredUsers(data || []);
    } catch (error) {
      console.error('Error fetching users:', error);
      toast.error('Failed to load users');
    } finally {
      setLoading(false);
    }
  }, [user, supabase]);

  useEffect(() => {
    fetchUsers();
  }, [user, supabase, fetchUsers]);

  // Filter users based on search and filters
  useEffect(() => {
    let filtered = users;

    // Search filter
    if (searchQuery) {
      filtered = filtered.filter(user =>
        user.first_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        user.last_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        user.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (user.employee_id && user.employee_id.toLowerCase().includes(searchQuery.toLowerCase())) ||
        (user.student_id && user.student_id.toLowerCase().includes(searchQuery.toLowerCase()))
      );
    }

    // Role filter
    if (roleFilter !== 'all') {
      filtered = filtered.filter(user => user.role === roleFilter);
    }

    // Status filter
    if (statusFilter !== 'all') {
      filtered = filtered.filter(user => {
        switch (statusFilter) {
          case 'active':
            return user.is_active;
          case 'inactive':
            return !user.is_active && !needsApproval(user);
          case 'pending':
            return needsApproval(user);
          default:
            return true;
        }
      });
    }

    // Department filter
    if (departmentFilter !== 'all') {
      filtered = filtered.filter(user => user.department === departmentFilter);
    }

    setFilteredUsers(filtered);
  }, [users, searchQuery, roleFilter, statusFilter, departmentFilter]);

  const handleToggleUserStatus = async (userId: string, currentStatus: boolean) => {
    try {
      const { error } = await supabase
        .from('users')
        .update({ is_active: !currentStatus })
        .eq('id', userId);

      if (error) throw error;

      setUsers(users.map(user =>
        user.id === userId ? { ...user, is_active: !currentStatus } : user
      ));

      toast.success(`User ${!currentStatus ? 'activated' : 'deactivated'} successfully`);
    } catch (error) {
      console.error('Error updating user status:', error);
      toast.error('Failed to update user status');
    }
  };

  const handleImportUsers = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setImporting(true);
    try {
      const csvContent = await readFile(file);
      const csvData = csvContent.split('\n').map(line => line.split(','));
      const importUsers = csvToUsers(csvData);

      let successCount = 0;
      let errorCount = 0;

      for (const importUser of importUsers) {
        try {
          // Check if user already exists
          const { data: existingUser } = await supabase
            .from('users')
            .select('id')
            .eq('email', importUser.email)
            .single();

          if (existingUser) {
            errorCount++;
            continue;
          }

          // Create user in Supabase Auth
          const { data: authData, error: authError } = await supabase.auth.admin.createUser({
            email: importUser.email,
            password: 'TempPassword123!', // Temporary password
            email_confirm: true,
            user_metadata: {
              first_name: importUser.first_name,
              last_name: importUser.last_name,
              role: importUser.role,
            },
          });

          if (authError) throw authError;

          // Create user profile
          const { error: profileError } = await supabase
            .from('users')
            .insert({
              id: authData.user.id,
              email: importUser.email,
              first_name: importUser.first_name,
              last_name: importUser.last_name,
              role: importUser.role,
              department: importUser.department || null,
              employee_id: importUser.employee_id || null,
              student_id: importUser.student_id || null,
              phone_number: importUser.phone_number || null,
              auth_provider: 'email',
              registration_completed: true,
              profile_completed: true,
              email_verified: true,
              is_active: true,
            });

          if (profileError) throw profileError;
          successCount++;
        } catch (error) {
          console.error('Error importing user:', importUser.email, error);
          errorCount++;
        }
      }

      // Refresh users list
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .order('created_at', { ascending: false });

      if (!error && data) {
        setUsers(data);
        setFilteredUsers(data);
      }

      toast.success(`Import completed: ${successCount} users imported, ${errorCount} errors`);
    } catch (error) {
      console.error('Import error:', error);
      toast.error('Failed to import users. Please check the file format.');
    } finally {
      setImporting(false);
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    }
  };

  const handleExportUsers = async () => {
    setExporting(true);
    try {
      const exportData: ExportUser[] = filteredUsers.map(user => ({
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        role: formatRole(user.role),
        department: user.department || '',
        employee_id: user.employee_id || '',
        student_id: user.student_id || '',
        phone_number: user.phone_number || '',
        is_active: user.is_active ? 'Active' : 'Inactive',
        created_at: new Date(user.created_at).toLocaleDateString(),
        last_login: user.last_login ? new Date(user.last_login).toLocaleDateString() : 'Never',
      }));

      const csvContent = usersToCSV(exportData);
      const timestamp = new Date().toISOString().split('T')[0];
      downloadFile(csvContent, `users-export-${timestamp}.csv`);

      toast.success(`Exported ${exportData.length} users successfully`);
    } catch (error) {
      console.error('Export error:', error);
      toast.error('Failed to export users');
    } finally {
      setExporting(false);
    }
  };

  const handleDownloadTemplate = () => {
    const template = generateUserTemplate();
    downloadFile(template, 'user-import-template.csv');
    toast.success('Template downloaded successfully');
  };

  const handleDeleteUser = async (userId: string) => {
    setModalLoading(true);
    try {
      // Delete user from auth
      const { error: authError } = await supabase.auth.admin.deleteUser(userId);
      if (authError) throw authError;

      // Delete user from database
      const { error: dbError } = await supabase
        .from('users')
        .delete()
        .eq('id', userId);

      if (dbError) throw dbError;

      // Update local state
      setUsers(users.filter(user => user.id !== userId));
      setFilteredUsers(filteredUsers.filter(user => user.id !== userId));

      toast.success('User deleted successfully');
      setShowDeleteDialog(false);
      setSelectedUser(null);
    } catch (error) {
      console.error('Error deleting user:', error);
      toast.error('Failed to delete user');
    } finally {
      setModalLoading(false);
    }
  };

  const handleEditUser = (user: User) => {
    setSelectedUser(user);
    setShowEditModal(true);
  };

  const handleDeleteClick = (user: User) => {
    setSelectedUser(user);
    setShowDeleteDialog(true);
  };

  // Check if user needs approval (non-students who are inactive and recently created)
  const needsApproval = (user: User): boolean => {
    if (user.role === 'student') return false;
    if (user.is_active) return false;

    // Check if user was created recently (within last 30 days) and hasn't been explicitly deactivated
    const createdDate = new Date(user.created_at);
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    return createdDate > thirtyDaysAgo && !user.last_login;
  };

  const handleApproveUser = async (userId: string) => {
    try {
      const { error } = await supabase
        .from('users')
        .update({ is_active: true })
        .eq('id', userId);

      if (error) throw error;

      setUsers(users.map(user =>
        user.id === userId ? { ...user, is_active: true } : user
      ));

      toast.success('User approved successfully');
    } catch (error) {
      console.error('Error approving user:', error);
      toast.error('Failed to approve user');
    }
  };

  const handleRejectUser = async (userId: string) => {
    try {
      // For rejection, we'll delete the user account
      await handleDeleteUser(userId);
      toast.success('User registration rejected');
    } catch (error) {
      console.error('Error rejecting user:', error);
      toast.error('Failed to reject user');
    }
  };

  const getRoleColor = (role: UserRole) => {
    const colors = {
      super_admin: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300',
      admin: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300',
      lab_manager: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
      instructor: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300',
      lab_staff: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300',
      student: 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300',
    };
    return colors[role] || colors.student;
  };

  const getUniqueValues = (key: keyof User) => {
    return Array.from(new Set(users.map(user => user[key]).filter(Boolean)));
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-screen bg-background">
        <DashboardHeader title="User Management" />
        <div className="container mx-auto px-4 py-8">
          <div className="flex items-center justify-center">
            <div className="text-center space-y-4">
              <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent mx-auto" />
              <p className="text-muted-foreground">Loading users...</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!user || !['admin', 'super_admin'].includes(user.role)) {
    return null;
  }

  return (
    <div className="min-h-screen bg-background">
      <DashboardHeader title="User Management" />
      
      <div className="container mx-auto px-4 py-8">
        <div className="space-y-6">
          {/* Header Actions */}
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
            <div>
              <h1 className="text-3xl font-bold">User Management</h1>
              <p className="text-muted-foreground">
                Manage user accounts, roles, and permissions
              </p>
            </div>
            <div className="flex gap-2">
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="outline" size="sm" disabled={importing}>
                    <Upload className="h-4 w-4 mr-2" />
                    Import
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent>
                  <DropdownMenuItem onClick={handleDownloadTemplate}>
                    <FileText className="mr-2 h-4 w-4" />
                    Download Template
                  </DropdownMenuItem>
                  <DropdownMenuItem onClick={() => fileInputRef.current?.click()}>
                    <Upload className="mr-2 h-4 w-4" />
                    Import Users
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>

              <Button
                variant="outline"
                size="sm"
                onClick={handleExportUsers}
                disabled={exporting || filteredUsers.length === 0}
              >
                <Download className="h-4 w-4 mr-2" />
                {exporting ? 'Exporting...' : 'Export'}
              </Button>

              <Button size="sm" onClick={() => setShowAddModal(true)}>
                <Plus className="h-4 w-4 mr-2" />
                Add User
              </Button>

              {/* Hidden file input for import */}
              <input
                ref={fileInputRef}
                type="file"
                accept=".csv"
                onChange={handleImportUsers}
                className="hidden"
              />
            </div>
          </div>

          {/* Filters and Search */}
          <Card>
            <CardHeader>
              <CardTitle>Filters</CardTitle>
              <CardDescription>
                Search and filter users by various criteria
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
                {/* Search */}
                <div className="lg:col-span-2">
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      placeholder="Search users..."
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      className="pl-10"
                    />
                  </div>
                </div>

                {/* Role Filter */}
                <Select value={roleFilter} onValueChange={setRoleFilter}>
                  <SelectTrigger>
                    <SelectValue placeholder="All Roles" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Roles</SelectItem>
                    <SelectItem value="super_admin">Super Admin</SelectItem>
                    <SelectItem value="admin">Admin</SelectItem>
                    <SelectItem value="lab_manager">Lab Manager</SelectItem>
                    <SelectItem value="instructor">Instructor</SelectItem>
                    <SelectItem value="lab_staff">Lab Staff</SelectItem>
                    <SelectItem value="student">Student</SelectItem>
                  </SelectContent>
                </Select>

                {/* Status Filter */}
                <Select value={statusFilter} onValueChange={setStatusFilter}>
                  <SelectTrigger>
                    <SelectValue placeholder="All Status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Status</SelectItem>
                    <SelectItem value="active">Active</SelectItem>
                    <SelectItem value="inactive">Inactive</SelectItem>
                    <SelectItem value="pending">Pending Approval</SelectItem>
                  </SelectContent>
                </Select>

                {/* Department Filter */}
                <Select value={departmentFilter} onValueChange={setDepartmentFilter}>
                  <SelectTrigger>
                    <SelectValue placeholder="All Departments" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Departments</SelectItem>
                    {getUniqueValues('department').map((dept) => (
                      <SelectItem key={dept} value={dept as string}>
                        {dept as string}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </CardContent>
          </Card>

          {/* Users Table */}
          <Card>
            <CardHeader>
              <CardTitle>Users ({filteredUsers.length})</CardTitle>
              <CardDescription>
                {filteredUsers.length === users.length 
                  ? `Showing all ${users.length} users`
                  : `Showing ${filteredUsers.length} of ${users.length} users`
                }
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>User</TableHead>
                      <TableHead>Role</TableHead>
                      <TableHead>Department</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Last Login</TableHead>
                      <TableHead className="text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredUsers.map((user) => (
                      <TableRow key={user.id}>
                        <TableCell>
                          <div className="flex items-center space-x-3">
                            <Avatar className="h-8 w-8">
                              <AvatarFallback>
                                {`${user.first_name.charAt(0)}${user.last_name.charAt(0)}`.toUpperCase()}
                              </AvatarFallback>
                            </Avatar>
                            <div>
                              <div className="font-medium">
                                {formatUserName(user.first_name, user.last_name)}
                              </div>
                              <div className="text-sm text-muted-foreground">
                                {user.email}
                              </div>
                              {(user.employee_id || user.student_id) && (
                                <div className="text-xs text-muted-foreground">
                                  ID: {user.employee_id || user.student_id}
                                </div>
                              )}
                            </div>
                          </div>
                        </TableCell>
                        <TableCell>
                          <Badge className={getRoleColor(user.role)}>
                            {formatRole(user.role)}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          {user.department || 'Not assigned'}
                        </TableCell>
                        <TableCell>
                          {needsApproval(user) ? (
                            <Badge variant="outline" className="border-yellow-500 text-yellow-700 bg-yellow-50 dark:bg-yellow-950 dark:text-yellow-300">
                              Pending Approval
                            </Badge>
                          ) : (
                            <Badge variant={user.is_active ? 'default' : 'secondary'}>
                              {user.is_active ? 'Active' : 'Inactive'}
                            </Badge>
                          )}
                        </TableCell>
                        <TableCell>
                          {user.last_login 
                            ? new Date(user.last_login).toLocaleDateString()
                            : 'Never'
                          }
                        </TableCell>
                        <TableCell className="text-right">
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" className="h-8 w-8 p-0">
                                <MoreHorizontal className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuLabel>Actions</DropdownMenuLabel>

                              {needsApproval(user) ? (
                                <>
                                  <DropdownMenuItem
                                    onClick={() => handleApproveUser(user.id)}
                                    className="text-green-600"
                                  >
                                    <UserCheck className="mr-2 h-4 w-4" />
                                    Approve User
                                  </DropdownMenuItem>
                                  <DropdownMenuItem
                                    onClick={() => handleRejectUser(user.id)}
                                    className="text-destructive"
                                  >
                                    <UserX className="mr-2 h-4 w-4" />
                                    Reject User
                                  </DropdownMenuItem>
                                </>
                              ) : (
                                <>
                                  <DropdownMenuItem onClick={() => handleEditUser(user)}>
                                    <Edit className="mr-2 h-4 w-4" />
                                    Edit User
                                  </DropdownMenuItem>
                                  <DropdownMenuItem
                                    onClick={() => handleToggleUserStatus(user.id, user.is_active)}
                                  >
                                    {user.is_active ? (
                                      <>
                                        <UserX className="mr-2 h-4 w-4" />
                                        Deactivate
                                      </>
                                    ) : (
                                      <>
                                        <UserCheck className="mr-2 h-4 w-4" />
                                        Activate
                                      </>
                                    )}
                                  </DropdownMenuItem>
                                  <DropdownMenuSeparator />
                                  <DropdownMenuItem
                                    className="text-destructive"
                                    onClick={() => handleDeleteClick(user)}
                                  >
                                    <Trash2 className="mr-2 h-4 w-4" />
                                    Delete User
                                  </DropdownMenuItem>
                                </>
                              )}
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle className="flex items-center">
              <AlertTriangle className="mr-2 h-5 w-5 text-destructive" />
              Delete User
            </AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete{' '}
              <span className="font-medium">
                {selectedUser ? formatUserName(selectedUser.first_name, selectedUser.last_name) : ''}
              </span>
              ? This action cannot be undone and will permanently remove the user account and all associated data.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={modalLoading}>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => selectedUser && handleDeleteUser(selectedUser.id)}
              disabled={modalLoading}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {modalLoading ? 'Deleting...' : 'Delete User'}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Add User Modal */}
      <AddUserModal
        open={showAddModal}
        onOpenChange={setShowAddModal}
        onUserAdded={fetchUsers}
      />

      {/* Edit User Modal */}
      <EditUserModal
        open={showEditModal}
        onOpenChange={setShowEditModal}
        user={selectedUser}
        onUserUpdated={fetchUsers}
      />
    </div>
  );
}
