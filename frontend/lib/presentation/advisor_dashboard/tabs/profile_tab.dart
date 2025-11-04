import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/api_service.dart';
import '../../student_dashboard/widgets/glass_card.dart';

/// Tab 4: Profile Tab
///
/// Displays advisor profile information and provides logout functionality
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  // Liquid Glass Theme Colors
  static const darkBackground = Color(0xFF0A0E21);
  static const glassBackground = Color(0xFF1D1E33);
  static const accentColor = Color(0xFF00D9FF);
  static const accentSecondary = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final profile = await _apiService.getCurrentUser();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: glassBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red.shade400),
            SizedBox(width: 2.w),
            Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _apiService.clearToken();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login-screen',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: darkBackground,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(accentColor),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(5.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 2.h),
                  
                  // Header
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Advisor Information',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),

                  SizedBox(height: 4.h),

                  // Profile Card
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar - clean icon design
                        Container(
                          width: 25.w,
                          height: 25.w,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentColor.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.school_rounded,
                              color: accentColor,
                              size: 12.w,
                            ),
                          ),
                        ),

                        SizedBox(height: 3.h),

                        // Name
                        Text(
                          _userProfile?['name'] ?? 'Advisor',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(height: 1.h),

                        // Role Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accentColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                color: accentColor,
                                size: 4.w,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                'Advisor',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Information Section
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: accentColor,
                              size: 5.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Information',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3.h),
                        _buildInfoRow(
                          Icons.badge_rounded,
                          'Employee ID',
                          _userProfile?['employee_id'] ?? 'N/A',
                        ),
                        SizedBox(height: 2.h),
                        _buildInfoRow(
                          Icons.email_rounded,
                          'Username',
                          _userProfile?['username'] ?? 'N/A',
                        ),
                        SizedBox(height: 2.h),
                        _buildInfoRow(
                          Icons.school_rounded,
                          'Department',
                          _userProfile?['course'] ?? 'N/A',
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Quick Actions
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.settings_rounded,
                              color: accentColor,
                              size: 5.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        _buildActionTile(
                          Icons.refresh_rounded,
                          'Refresh Profile',
                          'Update your information',
                          () => _loadProfile(),
                        ),
                        Divider(color: Colors.white.withOpacity(0.1)),
                        _buildActionTile(
                          Icons.help_outline_rounded,
                          'Help & Support',
                          'Get assistance',
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Help & Support coming soon'),
                                backgroundColor: accentColor,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: Icon(Icons.logout_rounded, size: 5.w),
                      label: Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  SizedBox(height: 3.h),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: accentColor,
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
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 5.w,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.3),
              size: 4.w,
            ),
          ],
        ),
      ),
    );
  }
}
