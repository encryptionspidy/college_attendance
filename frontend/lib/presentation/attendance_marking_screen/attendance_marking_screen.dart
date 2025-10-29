import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/attendance_summary_widget.dart';
import './widgets/date_picker_widget.dart';
import './widgets/floating_action_menu_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/student_card_widget.dart';

class AttendanceMarkingScreen extends StatefulWidget {
  const AttendanceMarkingScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceMarkingScreen> createState() =>
      _AttendanceMarkingScreenState();
}

class _AttendanceMarkingScreenState extends State<AttendanceMarkingScreen>
    with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  bool _isSaving = false;
  bool _isLoading = true;

  // Mock data for students
  final List<Map<String, dynamic>> _allStudents = [
    {
      "id": 1,
      "name": "Alex Johnson",
      "rollNumber": "CS001",
      "department": "Computer Science",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "attendance": "Present"
    },
    {
      "id": 2,
      "name": "Sarah Williams",
      "rollNumber": "CS002",
      "department": "Computer Science",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "attendance": "Present"
    },
    {
      "id": 3,
      "name": "Michael Brown",
      "rollNumber": "CS003",
      "department": "Computer Science",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "attendance": "Absent"
    },
    {
      "id": 4,
      "name": "Emily Davis",
      "rollNumber": "CS004",
      "department": "Computer Science",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "attendance": "Present"
    },
    {
      "id": 5,
      "name": "James Wilson",
      "rollNumber": "CS005",
      "department": "Computer Science",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "attendance": "On-Duty"
    },
    {
      "id": 6,
      "name": "Jessica Miller",
      "rollNumber": "CS006",
      "department": "Computer Science",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "attendance": "Present"
    },
    {
      "id": 7,
      "name": "David Garcia",
      "rollNumber": "CS007",
      "department": "Computer Science",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "attendance": "Absent"
    },
    {
      "id": 8,
      "name": "Ashley Martinez",
      "rollNumber": "CS008",
      "department": "Computer Science",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "attendance": "Present"
    },
    {
      "id": 9,
      "name": "Christopher Lee",
      "rollNumber": "CS009",
      "department": "Computer Science",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "attendance": "On-Duty"
    },
    {
      "id": 10,
      "name": "Amanda Taylor",
      "rollNumber": "CS010",
      "department": "Computer Science",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "attendance": "Present"
    },
  ];

  List<Map<String, dynamic>> _filteredStudents = [];
  Map<int, String> _attendanceStatus = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Initialize attendance status from mock data
    for (var student in _allStudents) {
      _attendanceStatus[student['id'] as int] = student['attendance'] as String;
    }
    _filteredStudents = List.from(_allStudents);

    // Simulate loading
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStudents = List.from(_allStudents);
      } else {
        _filteredStudents = _allStudents.where((student) {
          final name = (student['name'] as String).toLowerCase();
          final rollNumber = (student['rollNumber'] as String).toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || rollNumber.contains(searchLower);
        }).toList();
      }
    });
  }

  void _updateAttendanceStatus(int studentId, String status) {
    HapticFeedback.lightImpact();
    setState(() {
      _attendanceStatus[studentId] = status;
    });
  }

  void _markAllPresent() {
    HapticFeedback.mediumImpact();
    setState(() {
      for (var student in _filteredStudents) {
        _attendanceStatus[student['id'] as int] = 'Present';
      }
    });
    _showSnackBar('All students marked as Present', AppTheme.presentStatus);
  }

  void _markAllAbsent() {
    HapticFeedback.mediumImpact();
    setState(() {
      for (var student in _filteredStudents) {
        _attendanceStatus[student['id'] as int] = 'Absent';
      }
    });
    _showSnackBar('All students marked as Absent', AppTheme.absentStatus);
  }

  void _showAttendanceSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AttendanceSummaryWidget(
        totalStudents: _filteredStudents.length,
        presentCount: _getPresentCount(),
        absentCount: _getAbsentCount(),
        onDutyCount: _getOnDutyCount(),
        onSaveChanges: _saveAttendance,
        isSaving: _isSaving,
      ),
    );
  }

  Future<void> _saveAttendance() async {
    setState(() {
      _isSaving = true;
    });

    // Simulate saving to database
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      Navigator.pop(context);
      _showSnackBar('Attendance saved successfully!', AppTheme.presentStatus);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  void _showStudentContextMenu(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildContextMenu(student),
    );
  }

  Widget _buildContextMenu(Map<String, dynamic> student) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: AppTheme.glassmorphismDecoration(
                isLight: !isDark, borderRadius: 16),
            padding: EdgeInsets.all(4.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  student['name'] as String,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Roll No: ${student['rollNumber']}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildContextButton(
                        'Present',
                        AppTheme.presentStatus,
                        () {
                          _updateAttendanceStatus(
                              student['id'] as int, 'Present');
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: _buildContextButton(
                        'Absent',
                        AppTheme.absentStatus,
                        () {
                          _updateAttendanceStatus(
                              student['id'] as int, 'Absent');
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: _buildContextButton(
                        'On-Duty',
                        AppTheme.onDutyStatus,
                        () {
                          _updateAttendanceStatus(
                              student['id'] as int, 'On-Duty');
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContextButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }

  int _getPresentCount() {
    return _attendanceStatus.values
        .where((status) => status == 'Present')
        .length;
  }

  int _getAbsentCount() {
    return _attendanceStatus.values
        .where((status) => status == 'Absent')
        .length;
  }

  int _getOnDutyCount() {
    return _attendanceStatus.values
        .where((status) => status == 'On-Duty')
        .length;
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate refresh
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Data refreshed successfully!', AppTheme.presentStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Attendance Marking',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight,
              ),
        ),
        backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight,
            size: 6.w,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight,
              size: 6.w,
            ),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
              child: Column(
                children: [
                  // Date Picker
                  DatePickerWidget(
                    selectedDate: _selectedDate,
                    onDateChanged: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),

                  // Search Bar
                  SearchBarWidget(
                    searchQuery: _searchQuery,
                    onSearchChanged: _filterStudents,
                    onClear: () => _filterStudents(''),
                  ),

                  // Student List
                  Expanded(
                    child: _filteredStudents.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = _filteredStudents[index];
                              final studentId = student['id'] as int;

                              return StudentCardWidget(
                                student: student,
                                attendanceStatus:
                                    _attendanceStatus[studentId] ?? 'Present',
                                onStatusChanged: (status) =>
                                    _updateAttendanceStatus(studentId, status),
                                onLongPress: () =>
                                    _showStudentContextMenu(student),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionMenuWidget(
              onMarkAllPresent: _markAllPresent,
              onMarkAllAbsent: _markAllAbsent,
              onShowSummary: _showAttendanceSummary,
            ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          height: 20.h,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.cardDark.withValues(alpha: 0.3)
                : AppTheme.cardLight.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'search_off',
            color:
                isDark ? AppTheme.textDisabledDark : AppTheme.textDisabledLight,
            size: 15.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'No students found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Try adjusting your search criteria',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppTheme.textDisabledDark
                      : AppTheme.textDisabledLight,
                ),
          ),
        ],
      ),
    );
  }
}
