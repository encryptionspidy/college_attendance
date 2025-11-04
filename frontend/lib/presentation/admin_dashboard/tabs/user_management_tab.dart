import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/api_service.dart';
import '../widgets/admin_glass_widgets.dart';
import '../modals/user_form_modal.dart';

/// Tab 1: User Management - Full CRUD for all users
///
/// Features:
/// - List all users (Students, Advisors, Incharges, Admins)
/// - Add new users with role-specific forms
/// - Edit existing users with role-specific forms
/// - Delete users with confirmation
/// - Search and filter capabilities
/// - Perfect backend integration
class UserManagementTab extends StatefulWidget {
  const UserManagementTab({super.key});

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedRoleFilter = 'All';

  final List<String> _roleFilters = ['All', 'student', 'advisor', 'attendance_incharge', 'admin'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final users = await ApiService().getAllUsers(limit: 500);
      if (mounted) {
        setState(() {
          _users = users.map((u) => u as Map<String, dynamic>).toList();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load users', isError: true);
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesRole = _selectedRoleFilter == 'All' ||
                           user['role'] == _selectedRoleFilter;
        final searchTerm = _searchController.text.toLowerCase();
        final matchesSearch = searchTerm.isEmpty ||
                             (user['name']?.toString().toLowerCase().contains(searchTerm) ?? false) ||
                             (user['username']?.toString().toLowerCase().contains(searchTerm) ?? false) ||
                             (user['roll_no']?.toString().toLowerCase().contains(searchTerm) ?? false);
        return matchesRole && matchesSearch;
      }).toList();
    });
  }

  Future<void> _showAddUserModal() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UserFormModal(mode: UserFormMode.create),
    );

    if (result == true) {
      _loadUsers();
    }
  }

  Future<void> _showEditUserModal(Map<String, dynamic> user) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserFormModal(
        mode: UserFormMode.edit,
        userData: user,
      ),
    );

    if (result == true) {
      _loadUsers();
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete User', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${user['name'] ?? user['username']}? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350).withOpacity(0.2),
            ),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF5350))),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await ApiService().deleteUser(user['id'].toString());
      if (mounted) {
        if (result['success'] == true) {
          _showSnackBar('User deleted successfully');
          _loadUsers();
        } else {
          _showSnackBar(result['error'] ?? 'Failed to delete user', isError: true);
        }
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF5350) : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return const Color(0xFF00D9FF);
      case 'advisor':
        return const Color(0xFF8B5CF6);
      case 'attendance_incharge':
        return const Color(0xFFFFA726);
      case 'admin':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFF42A5F5);
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return Icons.school_rounded;
      case 'advisor':
        return Icons.person_search_rounded;
      case 'attendance_incharge':
        return Icons.fact_check_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(6.w, 4.h, 6.w, 2.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Management',
                        style: TextStyle(
                          fontSize: 24.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_filteredUsers.length} users',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 2.w),
                AdminGlassButton(
                  label: 'Add User',
                  icon: Icons.person_add_rounded,
                  onTap: _showAddUserModal,
                  color: const Color(0xFF00D9FF),
                  width: 35.w,
                ),
              ],
            ),
          ),
        ),

        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1E33).withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search users...',
                  hintStyle: TextStyle(color: Colors.white60, fontSize: 13.sp),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF00D9FF)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white60),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                ),
                onChanged: (value) => _applyFilters(),
              ),
            ),
          ),
        ),

        // Role Filter Chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 6.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              itemCount: _roleFilters.length,
              itemBuilder: (context, index) {
                final role = _roleFilters[index];
                final isSelected = _selectedRoleFilter == role;

                return Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedRoleFilter = role);
                      _applyFilters();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00D9FF).withOpacity(0.3)
                            : const Color(0xFF1D1E33).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00D9FF)
                              : Colors.white.withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          role == 'All' ? role : role.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF00D9FF) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: 2.h)),

        // Users List
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
            ),
          )
        else if (_filteredUsers.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_off_rounded,
                    size: 20.w,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'No Users Found',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = _filteredUsers[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: _buildUserCard(user),
                  );
                },
                childCount: _filteredUsers.length,
              ),
            ),
          ),

        SliverToBoxAdapter(child: SizedBox(height: 10.h)),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role']?.toString() ?? 'student';
    final roleColor = _getRoleColor(role);

    return AdminGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [roleColor, roleColor.withOpacity(0.6)],
                  ),
                ),
                child: Icon(
                  _getRoleIcon(role),
                  color: Colors.white,
                  size: 6.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? user['username'] ?? 'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (user['roll_no'] != null)
                      Text(
                        'Roll: ${user['roll_no']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: roleColor),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Flexible(
                flex: 1,
                child: AdminGlassButton(
                  label: 'Edit',
                  icon: Icons.edit_rounded,
                  onTap: () => _showEditUserModal(user),
                  color: const Color(0xFF00D9FF),
                ),
              ),
              SizedBox(width: 2.w),
              Flexible(
                flex: 1,
                child: AdminGlassButton(
                  label: 'Delete',
                  icon: Icons.delete_rounded,
                  onTap: () => _deleteUser(user),
                  color: const Color(0xFFEF5350),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

