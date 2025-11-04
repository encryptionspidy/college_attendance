import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/api_service.dart';
import '../../../services/app_state.dart';
import '../../../core/app_export.dart';
import '../widgets/admin_glass_widgets.dart';

/// Tab 4: Admin Profile - Admin's personal settings and logout
class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = await ApiService().getCurrentUser();

      if (mounted && user != null) {
        setState(() {
          _userData = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350).withOpacity(0.2),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFEF5350)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ApiService().clearToken();
      AppState().clearUser();

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.loginScreen,
        (route) => false,
      );
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'A';
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00D9FF);
    const accentSecondary = Color(0xFFEF5350); // Red for admin

    return RefreshIndicator(
      onRefresh: _loadUserData,
      color: accentColor,
      backgroundColor: const Color(0xFF1D1E33),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(6.w, 4.h, 6.w, 2.h),
              child: Text(
                'Admin Profile',
                style: TextStyle(
                  fontSize: 24.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Profile Avatar & Basic Info Card
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              child: _isLoading
                  ? AdminGlassCard(
                      child: SizedBox(
                        height: 20.h,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00D9FF),
                          ),
                        ),
                      ),
                    )
                  : AdminGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar with admin icon - clean circle design
                          Container(
                            width: 22.w,
                            height: 22.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentSecondary.withOpacity(0.15),
                              border: Border.all(
                                color: accentSecondary.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.admin_panel_settings_rounded,
                                color: accentSecondary,
                                size: 11.w,
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),

                          // Name
                          Text(
                            _userData['name'] ?? _userData['username'] ?? 'Admin',
                            style: TextStyle(
                              fontSize: 18.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 0.5.h),

                          // Role Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: accentSecondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: accentSecondary),
                            ),
                            child: Text(
                              'ADMINISTRATOR',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: accentSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // Account Details Card
          if (!_isLoading) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                child: AdminGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Details',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      _buildInfoRow(
                        Icons.person_rounded,
                        'Username',
                        _userData['username'] ?? 'N/A',
                      ),
                      _buildInfoRow(
                        Icons.badge_rounded,
                        'User ID',
                        _userData['id']?.toString() ?? 'N/A',
                      ),
                      _buildInfoRow(
                        Icons.admin_panel_settings_rounded,
                        'Role',
                        (_userData['role'] ?? 'admin').toUpperCase(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // System Statistics Card
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                child: AdminGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.analytics_rounded,
                            color: accentColor,
                            size: 6.w,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'System Overview',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Full administrative access to all features',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        '• User Management',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        '• Request Auditing',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        '• Attendance Auditing',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                child: Column(
                  children: [
                    // Logout Button
                    AdminGlassButton(
                      label: 'Logout',
                      icon: Icons.logout_rounded,
                      onTap: _handleLogout,
                      color: accentSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Bottom padding
          SliverToBoxAdapter(
            child: SizedBox(height: 10.h),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF00D9FF),
              size: 5.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

