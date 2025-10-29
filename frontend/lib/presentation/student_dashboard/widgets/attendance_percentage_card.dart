import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:ui';

import '../../../../core/app_export.dart';

class AttendancePercentageCard extends StatelessWidget {
  final double attendancePercentage;
  final String studentName;
  final String semester;

  const AttendancePercentageCard({
    super.key,
    required this.attendancePercentage,
    required this.studentName,
    required this.semester,
  });

  Color _getStatusColor() {
    if (attendancePercentage >= 75) {
      return AppTheme.presentStatus;
    } else if (attendancePercentage >= 65) {
      return AppTheme.onDutyStatus;
    } else {
      return AppTheme.absentStatus;
    }
  }

  String _getStatusText() {
    if (attendancePercentage >= 75) {
      return 'Excellent';
    } else if (attendancePercentage >= 65) {
      return 'Good';
    } else {
      return 'Needs Improvement';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.glassOverlay.withValues(alpha: 0.15)
                  : AppTheme.glassOverlay.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? AppTheme.shadowDark : AppTheme.shadowLight,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            studentName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppTheme.textPrimaryDark
                                      : AppTheme.textPrimaryLight,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            semester,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? AppTheme.textSecondaryDark
                                          : AppTheme.textSecondaryLight,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    CustomIconWidget(
                      iconName: 'notifications_outlined',
                      color:
                          isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                      size: 6.w,
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Current Attendance',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: isDark
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        '${attendancePercentage.toStringAsFixed(1)}%',
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _getStatusColor(),
                                  fontSize: 48.sp,
                                ),
                      ),
                      SizedBox(height: 1.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor().withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getStatusText(),
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: _getStatusColor(),
                                    fontWeight: FontWeight.w500,
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
    );
  }
}
