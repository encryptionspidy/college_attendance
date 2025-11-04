import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/api_service.dart';
import '../../../services/app_state.dart';
import '../../../core/app_export.dart';
import '../widgets/glass_card.dart';
import '../../edit_profile_screen/edit_profile_screen.dart';

/// Tab 4: Profile Screen - The User View
///
/// Features:
/// - Display all student personal details from backend
/// - Edit Profile and Change Password buttons
/// - Logout functionality
/// - Fix for the "completely collapsed" profile issue
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
      print('Error loading user data: $e');
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
      // Clear token and navigate to login
      ApiService().clearToken();
      AppState().clearUser();

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.loginScreen,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00D9FF);
    const accentSecondary = Color(0xFF8B5CF6);

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
                'Profile',
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
                  ? GlassCard(
                      child: SizedBox(
                        height: 20.h,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00D9FF),
                          ),
                        ),
                      ),
                    )
                  : GlassCard(
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [accentColor, accentSecondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(_userData['name'] ?? _userData['username'] ?? 'U'),
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),

                          // Name
                          Text(
                            _userData['name'] ?? _userData['username'] ?? 'User',
                            style: TextStyle(
                              fontSize: 18.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 0.5.h),

                          // Role
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _userData['role']?.toString().toUpperCase() ?? 'STUDENT',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // Personal Details Card
          if (!_isLoading) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Details',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      _buildInfoRow(
                        Icons.badge_rounded,
                        'Roll Number',
                        _userData['roll_no'] ?? 'N/A',
                      ),
                      _buildInfoRow(
                        Icons.phone_rounded,
                        'Phone',
                        _userData['phone'] ?? 'N/A',
                      ),
                      _buildInfoRow(
                        Icons.email_rounded,
                        'Email',
                        _userData['email'] ?? 'N/A',
                      ),
                      _buildInfoRow(
                        Icons.school_rounded,
                        'Course',
                        _userData['course'] ?? 'N/A',
                      ),
                      _buildInfoRow(
                        Icons.calendar_today_rounded,
                        'Semester',
                        _userData['semester']?.toString() ?? 'N/A',
                      ),
                      _buildInfoRow(
                        Icons.location_city_rounded,
                        'Section',
                        _userData['section'] ?? 'N/A',
                      ),
                      if (_userData['cgpa'] != null)
                        _buildInfoRow(
                          Icons.star_rounded,
                          'CGPA',
                          _userData['cgpa'].toString(),
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
                    // Edit Profile Button
                    GlassCard(
                      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                        // Refresh data after returning
                        _loadUserData();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            color: accentColor,
                            size: 5.w,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Change Password Button
                    GlassCard(
                      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
                      onTap: () {
                        // TODO: Navigate to change password screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Change password feature coming soon!'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF1D1E33),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_reset_rounded,
                            color: accentSecondary,
                            size: 5.w,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Logout Button
                    GlassCard(
                      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
                      glassColor: const Color(0xFFEF5350).withOpacity(0.3),
                      onTap: _handleLogout,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: const Color(0xFFEF5350),
                            size: 5.w,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFFEF5350),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }
}

