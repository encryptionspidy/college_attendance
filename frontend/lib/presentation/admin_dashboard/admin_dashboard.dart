import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'tabs/user_management_tab.dart';
import 'tabs/leave_requests_tab.dart';
import 'tabs/attendance_records_tab.dart';
import 'tabs/admin_profile_tab.dart';

/// The New Admin Dashboard - Liquid Glass Dark Theme Architecture
///
/// This is the main container for the admin experience, featuring:
/// - A modern floating glassmorphic navigation bar
/// - Four distinct, fully functional screens
/// - Perfect backend integration with live data
/// - SafeArea compliance
/// - Consistent with Student and Advisor dashboard themes
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  late final PageController _pageController;

  // The four core admin screens
  final List<Widget> _screens = const [
    UserManagementTab(),
    LeaveRequestsTab(),
    AttendanceRecordsTab(),
    AdminProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Liquid Glass Dark Theme Colors (Consistent with other dashboards)
    const darkBackground = Color(0xFF0A0E21);
    const glassBackground = Color(0xFF1D1E33);
    const accentColor = Color(0xFF00D9FF); // Cyan
    const accentSecondary = Color(0xFFEF5350); // Red for admin power

    return Scaffold(
      backgroundColor: darkBackground,
      // SafeArea fixes the status bar issue
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: _screens,
        ),
      ),

      // Floating Glassmorphic Navigation Bar
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: glassBackground.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.5,
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: accentColor,
                unselectedItemColor: Colors.white.withOpacity(0.4),
                selectedFontSize: 11.sp,
                unselectedFontSize: 10.sp,
                showUnselectedLabels: true,
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people_rounded, size: 6.w),
                    activeIcon: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.people_rounded, size: 6.w),
                    ),
                    label: 'Users',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.assignment_rounded, size: 6.w),
                    activeIcon: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.assignment_rounded, size: 6.w),
                    ),
                    label: 'Requests',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.event_note_rounded, size: 6.w),
                    activeIcon: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.event_note_rounded, size: 6.w),
                    ),
                    label: 'Attendance',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.admin_panel_settings_rounded, size: 6.w),
                    activeIcon: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: accentSecondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.admin_panel_settings_rounded, size: 6.w),
                    ),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

