import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import '../../../services/api_service.dart';
import '../../../services/app_state.dart';
import '../../student_dashboard/widgets/glass_card.dart';

/// Tab 1: Mark Attendance Tab
///
/// The primary screen for attendance incharge to mark daily attendance
/// Features:
/// - Date picker
/// - Student list with attendance marking
/// - Read-only vs Edit mode
/// - Holiday/Weekend marking
/// - Backend integration with POST /attendance/mark
class MarkAttendanceTab extends StatefulWidget {
  const MarkAttendanceTab({super.key});

  @override
  State<MarkAttendanceTab> createState() => _MarkAttendanceTabState();
}

class _MarkAttendanceTabState extends State<MarkAttendanceTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ApiService _apiService = ApiService();
  
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  bool _isReadOnly = false;
  bool _isSaving = false;
  String _searchQuery = '';
  bool _isHoliday = false;
  
  // Liquid Glass Theme Colors
  static const darkBackground = Color(0xFF0A0E21);
  static const glassBackground = Color(0xFF1D1E33);
  static const accentColor = Color(0xFF00D9FF);
  static const accentSecondary = Color(0xFF8B5CF6);
  static const presentGreen = Color(0xFF4CAF50);
  static const absentRed = Color(0xFFF44336);
  static const onDutyOrange = Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() => _isLoading = true);
    
    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final data = await _apiService.getStudentsForAttendance(date: dateStr);
      
      setState(() {
        _students = data.map((student) {
          // Check if attendance is already marked
          final hasAttendance = student['attendance'] != null && student['attendance'] != 'Not Marked';
          
          return {
            'id': student['id'],
            'name': student['name'] ?? 'Unknown',
            'roll_no': student['roll_no'] ?? 'N/A',
            'course': student['course'] ?? 'N/A',
            'attendance': student['attendance'] ?? 'Present', // Default to Present
            'hasExistingRecord': hasAttendance,
          };
        }).toList();
        
        // If any student has existing attendance, set to read-only mode
        _isReadOnly = _students.any((s) => s['hasExistingRecord'] == true);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load students: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _saveAttendance() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final records = _students.map((student) => {
        'student_id': student['id'],
        'date': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        'status': student['attendance'],
      }).toList();

      final result = await _apiService.markAttendance(records: records);

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _isReadOnly = true;
          // Mark all students as having existing records
          for (var student in _students) {
            student['hasExistingRecord'] = true;
          }
        });
        // Global attendance refresh
        if (mounted) {
          context.read<AppState>().notifyAttendanceChanged();
          await _loadAttendanceData();
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text('Attendance saved successfully'),
                ),
              ],
            ),
            backgroundColor: presentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception(result['error'] ?? 'Failed to save attendance');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: absentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _markHoliday() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: glassBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Mark Holiday',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to mark ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} as a holiday?',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: onDutyOrange,
            ),
            child: Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final result = await _apiService.markHoliday(date: dateStr, description: 'Holiday');

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() => _isHoliday = true);
        // Global attendance refresh
        if (mounted) {
          context.read<AppState>().notifyAttendanceChanged();
          await _loadAttendanceData();
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Holiday marked successfully'),
            backgroundColor: onDutyOrange,
          ),
        );
        _loadAttendanceData(); // Reload
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: absentRed,
          ),
        );
      }
    }
  }

  void _updateAttendance(int index, String status) {
    if (_isReadOnly) return;
    
    setState(() {
      _students[index]['attendance'] = status;
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isReadOnly = !_isReadOnly;
    });
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    
    return _students.where((student) {
      final name = (student['name'] as String).toLowerCase();
      final rollNo = (student['roll_no'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) || rollNo.contains(query);
    }).toList();
  }

  int get _presentCount => _students.where((s) => s['attendance'] == 'Present').length;
  int get _absentCount => _students.where((s) => s['attendance'] == 'Absent').length;
  int get _onDutyCount => _students.where((s) => s['attendance'] == 'On-Duty').length;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section (scrollable if needed)
            SizedBox(
              height: 48.h, // Fixed height for header section
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(5.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 2.h),

                      // Title Row
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [accentColor, accentSecondary],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.how_to_reg_rounded,
                              color: Colors.white,
                              size: 7.w,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mark Attendance',
                                  style: TextStyle(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _isReadOnly ? 'Read-only mode' : 'Marking mode',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: _isReadOnly
                                        ? onDutyOrange
                                        : presentGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isReadOnly)
                            ElevatedButton.icon(
                              onPressed: _toggleEditMode,
                              icon: Icon(Icons.edit_rounded, size: 4.w),
                              label: Text('Edit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 1.5.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 3.h),

                      // Date Picker Card
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(Duration(days: 7)),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: accentColor,
                                    onPrimary: Colors.white,
                                    surface: glassBackground,
                                    onSurface: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (date != null && date != _selectedDate) {
                            setState(() => _selectedDate = date);
                            _loadAttendanceData();
                          }
                        },
                        child: GlassCard(
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(3.w),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.calendar_today_rounded,
                                  color: accentColor,
                                  size: 6.w,
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Selected Date',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: accentColor,
                                size: 5.w,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 2.h),

                      // Statistics Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Present',
                              _presentCount.toString(),
                              presentGreen,
                              Icons.check_circle_rounded,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: _buildStatCard(
                              'Absent',
                              _absentCount.toString(),
                              absentRed,
                              Icons.cancel_rounded,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: _buildStatCard(
                              'On-Duty',
                              _onDutyCount.toString(),
                              onDutyOrange,
                              Icons.work_rounded,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 2.h),

                      // Search Bar
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                        decoration: BoxDecoration(
                          color: glassBackground.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, color: accentColor, size: 5.w),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: TextField(
                                onChanged: (value) => setState(() => _searchQuery = value),
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Search students...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Student List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(accentColor),
                      ),
                    )
                  : _filteredStudents.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadAttendanceData,
                          color: accentColor,
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            itemCount: _filteredStudents.length,
                            itemBuilder: (context, index) {
                              return _buildStudentCard(index);
                            },
                          ),
                        ),
            ),

            // Bottom Action Bar
            if (!_isReadOnly)
              Container(
                padding: EdgeInsets.all(5.w),
                decoration: BoxDecoration(
                  color: glassBackground.withOpacity(0.95),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _markHoliday,
                          icon: Icon(Icons.event_busy_rounded, size: 5.w),
                          label: Text(
                            'Mark Holiday',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: onDutyOrange,
                            side: BorderSide(
                              color: onDutyOrange.withOpacity(0.5),
                              width: 1.5,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveAttendance,
                          icon: _isSaving
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Icon(Icons.save_rounded, size: 5.w),
                          label: Text(
                            _isSaving ? 'Saving...' : 'Save Attendance',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: presentGreen,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 6.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(int index) {
    final student = _filteredStudents[index];
    final attendance = student['attendance'] as String;
    
    Color statusColor;
    IconData statusIcon;
    
    switch (attendance) {
      case 'Present':
        statusColor = presentGreen;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'Absent':
        statusColor = absentRed;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'On-Duty':
        statusColor = onDutyOrange;
        statusIcon = Icons.work_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_rounded;
    }

    return GlassCard(
      margin: EdgeInsets.only(bottom: 2.5.h),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Info Row
          Row(
            children: [
              Container(
                width: 14.w,
                height: 14.w,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    (student['name'] as String)
                        .split(' ')
                        .map((e) => e[0])
                        .take(2)
                        .join()
                        .toUpperCase(),
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['name'],
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${student['roll_no']} • ${student['course']}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 2.5.h),
          Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
          SizedBox(height: 2.h),

          // Attendance Status Row
          if (_isReadOnly)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(statusIcon, color: statusColor, size: 6.w),
                  SizedBox(width: 3.w),
                  Text(
                    attendance,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildAttendanceButton(
                    index,
                    'Present',
                    presentGreen,
                    Icons.check_circle_rounded,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildAttendanceButton(
                    index,
                    'Absent',
                    absentRed,
                    Icons.cancel_rounded,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildAttendanceButton(
                    index,
                    'On-Duty',
                    onDutyOrange,
                    Icons.work_rounded,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceButton(int index, String status, Color color, IconData icon) {
    final student = _filteredStudents[index];
    final isSelected = student['attendance'] == status;

    return InkWell(
      onTap: () => _updateAttendance(index, status),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.2),
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.white.withOpacity(0.4),
              size: 5.w,
            ),
            SizedBox(height: 0.5.h),
            Text(
              status,
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: glassBackground.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_search_rounded,
              color: accentColor,
              size: 20.w,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'No Students Found',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Try adjusting your search',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
