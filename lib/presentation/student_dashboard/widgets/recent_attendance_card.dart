import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class RecentAttendanceCard extends StatelessWidget {
  final Map<String, dynamic> attendanceRecord;

  const RecentAttendanceCard({
    super.key,
    required this.attendanceRecord,
  });

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
        return AppTheme.presentStatus;
    }
  }

  String _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return 'check_circle';
      case 'absent':
        return 'cancel';
      case 'on_duty':
      case 'onduty':
        return 'work';
      default:
        return 'check_circle';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = attendanceRecord['status'] as String;
    final subject = attendanceRecord['subject'] as String;
    final date = attendanceRecord['date'] as DateTime;
    final time = attendanceRecord['time'] as String;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.glassOverlay.withValues(alpha: 0.1)
                  : AppTheme.glassOverlay.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: _getStatusIcon(status),
                      color: _getStatusColor(status),
                      size: 6.w,
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppTheme.textPrimaryDark
                                      : AppTheme.textPrimaryLight,
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '${date.day}/${date.month}/${date.year} • $time',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getStatusColor(status).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w600,
                          fontSize: 10.sp,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
