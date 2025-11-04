import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'screens/home_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/profile_screen.dart';

/// The New Student Dashboard - Liquid Glass Dark Theme Architecture
///
/// This is the main container for the student experience, featuring:
/// - A modern floating glassmorphic navigation bar
/// - Four distinct, fully functional screens
/// - Perfect backend integration with live data
/// - SafeArea compliance (fixing status bar issues)
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;
  late final PageController _pageController;

  // The three core screens (Requests removed - accessed via Home)
  final List<Widget> _screens = const [
    HomeScreen(),
    AttendanceScreen(),
    ProfileScreen(),
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
                    icon: Icon(Icons.home_rounded, size: 6.w),
                    activeIcon: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.home_rounded, size: 6.w),
                    ),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today_rounded, size: 6.w),
                    activeIcon: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.calendar_today_rounded, size: 6.w),
                    ),
                    label: 'Attendance',
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

