import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/attendance_percentage_card.dart';
import './widgets/monthly_calendar_widget.dart';
import './widgets/quick_action_card.dart';
import './widgets/recent_attendance_card.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _refreshController;
  bool _isRefreshing = false;

  // Mock data for student dashboard
  final Map<String, dynamic> studentData = {
    "id": 1,
    "name": "Sarah Johnson",
    "semester": "6th Semester - Computer Science",
    "attendancePercentage": 78.5,
    "totalClasses": 120,
    "attendedClasses": 94,
  };

  final List<Map<String, dynamic>> recentAttendance = [
    {
      "id": 1,
      "subject": "Data Structures & Algorithms",
      "date": DateTime.now().subtract(const Duration(days: 1)),
      "time": "09:00 AM",
      "status": "present",
      "instructor": "Dr. Michael Chen",
    },
    {
      "id": 2,
      "subject": "Database Management Systems",
      "date": DateTime.now().subtract(const Duration(days: 2)),
      "time": "11:00 AM",
      "status": "present",
      "instructor": "Prof. Lisa Anderson",
    },
    {
      "id": 3,
      "subject": "Software Engineering",
      "date": DateTime.now().subtract(const Duration(days: 3)),
      "time": "02:00 PM",
      "status": "absent",
      "instructor": "Dr. Robert Wilson",
    },
    {
      "id": 4,
      "subject": "Computer Networks",
      "date": DateTime.now().subtract(const Duration(days: 4)),
      "time": "10:00 AM",
      "status": "on_duty",
      "instructor": "Prof. Emily Davis",
    },
    {
      "id": 5,
      "subject": "Operating Systems",
      "date": DateTime.now().subtract(const Duration(days: 5)),
      "time": "01:00 PM",
      "status": "present",
      "instructor": "Dr. James Taylor",
    },
  ];

  final Map<DateTime, String> monthlyAttendanceData = {
    DateTime(2025, 1, 15): "present",
    DateTime(2025, 1, 16): "present",
    DateTime(2025, 1, 17): "absent",
    DateTime(2025, 1, 18): "on_duty",
    DateTime(2025, 1, 19): "present",
    DateTime(2025, 1, 20): "present",
    DateTime(2025, 1, 21): "present",
    DateTime(2025, 1, 22): "present",
  };

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    _refreshController.forward();

    // Simulate data refresh
    await Future.delayed(const Duration(seconds: 2));

    _refreshController.reverse();

    setState(() {
      _isRefreshing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Attendance data refreshed'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _navigateToLeaveRequest() {
    Navigator.pushNamed(context, '/leave-request-form');
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/student-profile-screen');
  }

  void _navigateToCalendar() {
    // Show calendar in a modal bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 80.h,
        child: MonthlyCalendarWidget(
          attendanceData: monthlyAttendanceData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Hero Attendance Card
              SliverToBoxAdapter(
                child: AttendancePercentageCard(
                  attendancePercentage:
                      (studentData['attendancePercentage'] as double),
                  studentName: studentData['name'] as String,
                  semester: studentData['semester'] as String,
                ),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  child: Row(
                    children: [
                      QuickActionCard(
                        title: 'Submit Leave',
                        subtitle: 'Request leave or on-duty',
                        iconName: 'assignment',
                        backgroundColor: isDark
                            ? AppTheme.secondaryDark
                            : AppTheme.secondaryLight,
                        onTap: _navigateToLeaveRequest,
                      ),
                      SizedBox(width: 3.w),
                      QuickActionCard(
                        title: 'View Calendar',
                        subtitle: 'Monthly attendance view',
                        iconName: 'calendar_today',
                        backgroundColor: isDark
                            ? AppTheme.primaryDark
                            : AppTheme.primaryLight,
                        onTap: _navigateToCalendar,
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Attendance Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 2.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Attendance',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppTheme.textPrimaryDark
                                      : AppTheme.textPrimaryLight,
                                ),
                      ),
                      if (_isRefreshing)
                        RotationTransition(
                          turns: _refreshController,
                          child: CustomIconWidget(
                            iconName: 'refresh',
                            color: isDark
                                ? AppTheme.primaryDark
                                : AppTheme.primaryLight,
                            size: 6.w,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Recent Attendance List
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final record = recentAttendance[index];
                      return GestureDetector(
                        onLongPress: () {
                          _showAttendanceDetails(record);
                        },
                        child: RecentAttendanceCard(
                          attendanceRecord: record,
                        ),
                      );
                    },
                    childCount: recentAttendance.length,
                  ),
                ),
              ),

              // Monthly Calendar Preview
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
                  child: Text(
                    'This Month Overview',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: MonthlyCalendarWidget(
                  attendanceData: monthlyAttendanceData,
                ),
              ),

              // Bottom spacing for FAB
              SliverToBoxAdapter(
                child: SizedBox(height: 10.h),
              ),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: isDark ? AppTheme.shadowDark : AppTheme.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });

                switch (index) {
                  case 0:
                    // Already on dashboard
                    break;
                  case 1:
                    _navigateToLeaveRequest();
                    break;
                  case 2:
                    _navigateToProfile();
                    break;
                }
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor:
                  (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight)
                      .withValues(alpha: 0.9),
              selectedItemColor:
                  isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
              unselectedItemColor: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
              items: [
                BottomNavigationBarItem(
                  icon: CustomIconWidget(
                    iconName: 'dashboard',
                    color: _currentIndex == 0
                        ? (isDark
                            ? AppTheme.primaryDark
                            : AppTheme.primaryLight)
                        : (isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight),
                    size: 6.w,
                  ),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: CustomIconWidget(
                    iconName: 'assignment',
                    color: _currentIndex == 1
                        ? (isDark
                            ? AppTheme.primaryDark
                            : AppTheme.primaryLight)
                        : (isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight),
                    size: 6.w,
                  ),
                  label: 'Requests',
                ),
                BottomNavigationBarItem(
                  icon: CustomIconWidget(
                    iconName: 'person',
                    color: _currentIndex == 2
                        ? (isDark
                            ? AppTheme.primaryDark
                            : AppTheme.primaryLight)
                        : (isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight),
                    size: 6.w,
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButton: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight)
                  .withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
                width: 1,
              ),
            ),
            child: FloatingActionButton(
              onPressed: _navigateToLeaveRequest,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: CustomIconWidget(
                iconName: 'add',
                color: isDark
                    ? AppTheme.onSecondaryDark
                    : AppTheme.onSecondaryLight,
                size: 7.w,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAttendanceDetails(Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight)
                    .withValues(alpha: 0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                  color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 12.w,
                      height: 0.5.h,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.dividerDark
                            : AppTheme.dividerLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Attendance Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                  ),
                  SizedBox(height: 2.h),
                  _buildDetailRow(
                      'Subject', record['subject'] as String, isDark),
                  _buildDetailRow(
                      'Instructor', record['instructor'] as String, isDark),
                  _buildDetailRow(
                      'Date',
                      '${(record['date'] as DateTime).day}/${(record['date'] as DateTime).month}/${(record['date'] as DateTime).year}',
                      isDark),
                  _buildDetailRow('Time', record['time'] as String, isDark),
                  _buildDetailRow('Status',
                      (record['status'] as String).toUpperCase(), isDark),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Dispute request submitted'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Text('Dispute'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
