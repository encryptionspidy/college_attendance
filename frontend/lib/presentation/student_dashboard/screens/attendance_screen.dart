import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';

import '../../../services/api_service.dart';
import '../../../services/app_state.dart';
import '../widgets/glass_card.dart';

/// Tab 2: Attendance Screen - The Calendar View
///
/// Features:
/// - Fully functional interactive calendar widget
/// - Liquid Glass theme styling
/// - Live attendance data from backend
/// - Colored markers for each day's status
/// - Tap to see details for specific dates
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, String> _attendanceData = {};
  Map<String, dynamic>? _selectedDayData;
  int _lastSeenAttendanceVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final version = Provider.of<AppState>(context).attendanceVersion;
    if (version != _lastSeenAttendanceVersion) {
      _lastSeenAttendanceVersion = version;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAttendanceData());
    }
  }

  Future<void> _loadAttendanceData() async {
    setState(() => _isLoading = true);

    try {
      final attendanceList = await ApiService().getMyAttendance();

      final Map<DateTime, String> data = {};
      for (var record in attendanceList) {
        final date = DateTime.parse(record['date']);
        final normalizedDate = DateTime(date.year, date.month, date.day);
        data[normalizedDate] = record['status'].toString().toLowerCase();
      }

      if (mounted) {
        setState(() {
          _attendanceData = data;
          _isLoading = false;
          _updateSelectedDayData();
        });
      }
    } catch (e) {
      print('Error loading attendance data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateSelectedDayData() {
    final normalizedDate = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );

    final status = _attendanceData[normalizedDate];
    if (status != null) {
      setState(() {
        _selectedDayData = {
          'date': _selectedDay,
          'status': status,
        };
      });
    } else {
      setState(() {
        _selectedDayData = null;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return const Color(0xFF4CAF50);
      case 'on-duty':
      case 'on_duty':
        return const Color(0xFFFFA726);
      case 'leave':
      case 'absent':  // Treat absent as leave
        return const Color(0xFF42A5F5);
      case 'holiday':
        return const Color(0xFF9C27B0);
      default:
        return Colors.white.withOpacity(0.3);
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return 'Present';
      case 'on-duty':
      case 'on_duty':
        return 'On Duty';
      case 'leave':
      case 'absent':  // Treat absent as leave
        return 'Leave';
      case 'holiday':
        return 'Holiday';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00D9FF);

    return RefreshIndicator(
      onRefresh: _loadAttendanceData,
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
                'Attendance Calendar',
                style: TextStyle(
                  fontSize: 24.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Calendar Card
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              child: _isLoading
                  ? GlassCard(
                      child: SizedBox(
                        height: 40.h,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00D9FF),
                          ),
                        ),
                      ),
                    )
                  : GlassCard(
                      padding: EdgeInsets.all(2.w),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                            _updateSelectedDayData();
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          todayDecoration: BoxDecoration(
                            color: accentColor.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                          defaultTextStyle: const TextStyle(color: Colors.white),
                          weekendTextStyle: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                          todayTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          selectedTextStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          titleCentered: true,
                          formatButtonVisible: false,
                          titleTextStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          leftChevronIcon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
                          rightChevronIcon: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                          weekendStyle: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            final normalizedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                            );
                            final status = _attendanceData[normalizedDate];

                            if (status != null) {
                              return Positioned(
                                bottom: 1,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
            ),
          ),

          // Selected Day Details
          if (_selectedDayData != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Selected Date',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 1.h,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_selectedDayData!['status'])
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(_selectedDayData!['status']),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              _getStatusLabel(_selectedDayData!['status']),
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: _getStatusColor(_selectedDayData!['status']),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${_selectedDay.day} ${_getMonthName(_selectedDay.month)} ${_selectedDay.year}',
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Legend
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Legend',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Wrap(
                      spacing: 3.w,
                      runSpacing: 1.h,
                      children: [
                        _buildLegendItem('Present', const Color(0xFF4CAF50)),
                        _buildLegendItem('Leave', const Color(0xFF42A5F5)),
                        _buildLegendItem('On Duty', const Color(0xFFFFA726)),
                        _buildLegendItem('Holiday', const Color(0xFF9C27B0)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom padding
          SliverToBoxAdapter(
            child: SizedBox(height: 10.h),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

