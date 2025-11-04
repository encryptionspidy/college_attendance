import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'tabs/mark_attendance_tab.dart';
import 'tabs/profile_tab.dart';

/// The New Attendance Incharge Dashboard - Liquid Glass Dark Theme Architecture
///
/// This is the main container for the attendance incharge experience, featuring:
/// - A modern floating glassmorphic navigation bar (matching other dashboards)
/// - Two core screens (Mark Attendance, Profile)
/// - Perfect backend integration with live data
/// - SafeArea compliance (no status bar issues)
/// - Clean, professional interface for attendance management
class AttendanceInchargeDashboard extends StatefulWidget {
  const AttendanceInchargeDashboard({super.key});

  @override
  State<AttendanceInchargeDashboard> createState() => _AttendanceInchargeDashboardState();
}

class _AttendanceInchargeDashboardState extends State<AttendanceInchargeDashboard> {
  int _currentIndex = 0;
  late final PageController _pageController;

  // The two core screens
  final List<Widget> _screens = const [
    MarkAttendanceTab(),
    ProfileTab(),
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
    // Liquid Glass Dark Theme Colors
    const darkBackground = Color(0xFF0A0E21);
    const glassBackground = Color(0xFF1D1E33);
    const accentColor = Color(0xFF00D9FF);
    const accentSecondary = Color(0xFF8B5CF6);

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
                    icon: Icon(Icons.how_to_reg_rounded, size: 6.w),
                    activeIcon: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.how_to_reg_rounded, size: 6.w),
                    ),
                    label: 'Mark Attendance',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded, size: 6.w),
                    activeIcon: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.person_rounded, size: 6.w),
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
