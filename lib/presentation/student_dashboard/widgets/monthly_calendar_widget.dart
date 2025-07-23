import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class MonthlyCalendarWidget extends StatefulWidget {
  final Map<DateTime, String> attendanceData;

  const MonthlyCalendarWidget({
    super.key,
    required this.attendanceData,
  });

  @override
  State<MonthlyCalendarWidget> createState() => _MonthlyCalendarWidgetState();
}

class _MonthlyCalendarWidgetState extends State<MonthlyCalendarWidget> {
  DateTime _currentMonth = DateTime.now();

  List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  List<String> _weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AppTheme.presentStatus;
      case 'absent':
        return AppTheme.absentStatus;
      case 'on_duty':
      case 'onduty':
        return AppTheme.onDutyStatus;
      default:
        return Colors.transparent;
    }
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startDate = firstDay.subtract(Duration(days: firstDay.weekday % 7));

    List<DateTime> days = [];
    for (int i = 0; i < 42; i++) {
      days.add(startDate.add(Duration(days: i)));
    }
    return days;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = _getDaysInMonth(_currentMonth);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.glassOverlay.withValues(alpha: 0.1)
                  : AppTheme.glassOverlay.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Calendar Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _previousMonth,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppTheme.primaryDark
                                  : AppTheme.primaryLight)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomIconWidget(
                          iconName: 'chevron_left',
                          color: isDark
                              ? AppTheme.primaryDark
                              : AppTheme.primaryLight,
                          size: 5.w,
                        ),
                      ),
                    ),
                    Text(
                      '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                          ),
                    ),
                    GestureDetector(
                      onTap: _nextMonth,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppTheme.primaryDark
                                  : AppTheme.primaryLight)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomIconWidget(
                          iconName: 'chevron_right',
                          color: isDark
                              ? AppTheme.primaryDark
                              : AppTheme.primaryLight,
                          size: 5.w,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                // Week Days Header
                Row(
                  children: _weekDays
                      .map((day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: isDark
                                          ? AppTheme.textSecondaryDark
                                          : AppTheme.textSecondaryLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                SizedBox(height: 1.h),

                // Calendar Grid
                ...List.generate(6, (weekIndex) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 1.h),
                    child: Row(
                      children: List.generate(7, (dayIndex) {
                        final dayDate = days[weekIndex * 7 + dayIndex];
                        final isCurrentMonth =
                            dayDate.month == _currentMonth.month;
                        final isToday = dayDate.day == DateTime.now().day &&
                            dayDate.month == DateTime.now().month &&
                            dayDate.year == DateTime.now().year;

                        final attendanceStatus = widget.attendanceData[
                            DateTime(dayDate.year, dayDate.month, dayDate.day)];

                        return Expanded(
                          child: Container(
                            height: 8.w,
                            margin: EdgeInsets.all(0.5.w),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? (isDark
                                          ? AppTheme.primaryDark
                                          : AppTheme.primaryLight)
                                      .withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: isToday
                                  ? Border.all(
                                      color: isDark
                                          ? AppTheme.primaryDark
                                          : AppTheme.primaryLight,
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    '${dayDate.day}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isCurrentMonth
                                              ? (isDark
                                                  ? AppTheme.textPrimaryDark
                                                  : AppTheme.textPrimaryLight)
                                              : (isDark
                                                  ? AppTheme.textDisabledDark
                                                  : AppTheme.textDisabledLight),
                                          fontWeight: isToday
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                  ),
                                ),
                                if (attendanceStatus != null)
                                  Positioned(
                                    bottom: 0.5.w,
                                    right: 0.5.w,
                                    child: Container(
                                      width: 2.w,
                                      height: 2.w,
                                      decoration: BoxDecoration(
                                        color:
                                            _getStatusColor(attendanceStatus),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),

                SizedBox(height: 1.h),

                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem('Present', AppTheme.presentStatus, isDark),
                    _buildLegendItem('Absent', AppTheme.absentStatus, isDark),
                    _buildLegendItem('On Duty', AppTheme.onDutyStatus, isDark),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 2.w,
          height: 2.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
        ),
      ],
    );
  }
}
