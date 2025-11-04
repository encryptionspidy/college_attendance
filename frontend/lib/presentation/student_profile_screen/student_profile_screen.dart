import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/attendance_history_widget.dart';
import './widgets/attendance_statistics_widget.dart';
import './widgets/leave_request_history_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/quick_actions_widget.dart';
import './widgets/settings_widget.dart';

class StudentProfileScreen extends StatefulWidget {
  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;
  bool _isRefreshing = false;
  bool _isDarkMode = false;

  // Mock data for student profile
  final Map<String, dynamic> _studentData = {
    'name': 'Alex Johnson',
    'studentId': 'STU2024001',
    'department': 'Computer Science',
    'year': 'Final Year',
    'semester': 8,
    'cgpa': 8.7,
    'section': 'A',
    'profileImage':
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
  };

  final Map<String, dynamic> _attendanceData = {
    'overallPercentage': 87.5,
    'subjects': [
      {
        'name': 'Data Structures',
        'percentage': 92.0,
        'present': 46,
        'total': 50
      },
      {
        'name': 'Machine Learning',
        'percentage': 88.0,
        'present': 44,
        'total': 50
      },
      {
        'name': 'Software Engineering',
        'percentage': 85.0,
        'present': 42,
        'total': 49
      },
      {
        'name': 'Database Systems',
        'percentage': 90.0,
        'present': 45,
        'total': 50
      },
      {
        'name': 'Computer Networks',
        'percentage': 82.0,
        'present': 41,
        'total': 50
      },
    ],
    'monthlyTrends': [
      {'month': 'Jan', 'percentage': 85.0},
      {'month': 'Feb', 'percentage': 88.0},
      {'month': 'Mar', 'percentage': 87.0},
      {'month': 'Apr', 'percentage': 90.0},
      {'month': 'May', 'percentage': 89.0},
      {'month': 'Jun', 'percentage': 87.5},
    ],
  };

  final List<Map<String, dynamic>> _attendanceHistory = [
    {
      'subject': 'Data Structures',
      'date': 'July 22, 2025',
      'time': '09:00 AM',
      'status': 'Present',
      'teacher': 'Dr. Smith',
      'notes': 'Regular class attendance',
    },
    {
      'subject': 'Machine Learning',
      'date': 'July 21, 2025',
      'time': '11:00 AM',
      'status': 'Present',
      'teacher': 'Prof. Johnson',
    },
    {
      'subject': 'Software Engineering',
      'date': 'July 20, 2025',
      'time': '02:00 PM',
      'status': 'On-Duty',
      'teacher': 'Dr. Brown',
      'notes': 'Attending college fest organizing committee meeting',
    },
    {
      'subject': 'Database Systems',
      'date': 'July 19, 2025',
      'time': '10:00 AM',
      'status': 'Present',
      'teacher': 'Prof. Davis',
    },
    {
      'subject': 'Computer Networks',
      'date': 'July 18, 2025',
      'time': '01:00 PM',
      'status': 'Absent',
      'teacher': 'Dr. Wilson',
      'notes': 'Medical leave',
    },
    {
      'subject': 'Data Structures',
      'date': 'July 17, 2025',
      'time': '09:00 AM',
      'status': 'Present',
      'teacher': 'Dr. Smith',
    },
    {
      'subject': 'Machine Learning',
      'date': 'July 16, 2025',
      'time': '11:00 AM',
      'status': 'Present',
      'teacher': 'Prof. Johnson',
    },
    {
      'subject': 'Software Engineering',
      'date': 'July 15, 2025',
      'time': '02:00 PM',
      'status': 'Present',
      'teacher': 'Dr. Brown',
    },
  ];

  final List<Map<String, dynamic>> _leaveRequests = [
    {
      'type': 'Medical Leave',
      'startDate': 'July 25, 2025',
      'endDate': 'July 27, 2025',
      'appliedDate': 'July 20, 2025',
      'status': 'Approved',
      'reason': 'Fever and flu symptoms, doctor advised rest',
      'approvedBy': 'Dr. Smith',
      'approvedDate': 'July 21, 2025',
    },
    {
      'type': 'Personal Leave',
      'startDate': 'July 30, 2025',
      'endDate': 'July 30, 2025',
      'appliedDate': 'July 22, 2025',
      'status': 'Pending',
      'reason': 'Family function attendance',
    },
    {
      'type': 'Academic Leave',
      'startDate': 'July 10, 2025',
      'endDate': 'July 12, 2025',
      'appliedDate': 'July 5, 2025',
      'status': 'Rejected',
      'reason': 'Attending technical conference',
      'rejectionReason': 'Conference not approved by department',
    },
    {
      'type': 'Medical Leave',
      'startDate': 'June 15, 2025',
      'endDate': 'June 16, 2025',
      'appliedDate': 'June 14, 2025',
      'status': 'Approved',
      'reason': 'Dental appointment',
      'approvedBy': 'Prof. Johnson',
      'approvedDate': 'June 14, 2025',
    },
  ];

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _refreshAnimation = CurvedAnimation(
      parent: _refreshController,
      curve: Curves.easeInOut,
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

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile data refreshed successfully'),
        backgroundColor: AppTheme.presentStatus,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight)
                    .withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _refreshAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshAnimation.value * 2 * 3.14159,
                child: IconButton(
                  onPressed: _isRefreshing ? null : _handleRefresh,
                  icon: CustomIconWidget(
                    iconName: 'refresh',
                    color: _isRefreshing
                        ? (isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight)
                        : (isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight),
                    size: 24,
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit_profile',
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'edit',
                      color: isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    const Text('Edit Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share_profile',
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'share',
                      color: isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    const Text('Share Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'logout',
                      color: AppTheme.absentStatus,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Logout',
                      style: TextStyle(color: AppTheme.absentStatus),
                    ),
                  ],
                ),
              ),
            ],
            icon: CustomIconWidget(
              iconName: 'more_vert',
              color:
                  isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              size: 24,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              ProfileHeaderWidget(studentData: _studentData),
              AttendanceStatisticsWidget(attendanceData: _attendanceData),
              AttendanceHistoryWidget(historyData: _attendanceHistory),
              LeaveRequestHistoryWidget(leaveRequests: _leaveRequests),
              QuickActionsWidget(
                onSubmitRequest: () => _navigateToLeaveRequest(),
                onDownloadReport: () => _downloadReport(),
              ),
              SettingsWidget(
                isDarkMode: _isDarkMode,
                onDarkModeChanged: (value) => _toggleDarkMode(value),
                onProfilePhotoUpdate: () => _updateProfilePhoto(),
              ),
              SizedBox(height: 10.h), // Bottom padding for better scrolling
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToLeaveRequest(),
        icon: CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 24,
        ),
        label: const Text('New Request'),
        backgroundColor:
            isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit_profile':
        _editProfile();
        break;
      case 'share_profile':
        _shareProfile();
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile editing feature coming soon...'),
        backgroundColor: AppTheme.onDutyStatus,
      ),
    );
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile shared successfully'),
        backgroundColor: AppTheme.presentStatus,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login-screen',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.absentStatus,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _navigateToLeaveRequest() {
    Navigator.pushNamed(context, '/leave-request-form');
  }

  void _downloadReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance report download started...'),
        backgroundColor: AppTheme.presentStatus,
      ),
    );
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${value ? 'Dark' : 'Light'} mode ${value ? 'enabled' : 'disabled'}'),
        backgroundColor: AppTheme.presentStatus,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _updateProfilePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile photo update feature opened'),
        backgroundColor: AppTheme.presentStatus,
      ),
    );
  }
}
