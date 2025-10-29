import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AttendanceSummaryWidget extends StatelessWidget {
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int onDutyCount;
  final VoidCallback onSaveChanges;
  final bool isSaving;

  const AttendanceSummaryWidget({
    Key? key,
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.onDutyCount,
    required this.onSaveChanges,
    this.isSaving = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppTheme.shadowDark : AppTheme.shadowLight,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: AppTheme.glassmorphismDecoration(
                isLight: !isDark, borderRadius: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 12.w,
                  height: 0.5.h,
                  margin: EdgeInsets.only(bottom: 2.h),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Text(
                  'Attendance Summary',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 2.h),

                // Statistics Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total',
                        totalStudents.toString(),
                        isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Present',
                        presentCount.toString(),
                        AppTheme.presentStatus,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Absent',
                        absentCount.toString(),
                        AppTheme.absentStatus,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'On-Duty',
                        onDutyCount.toString(),
                        AppTheme.onDutyStatus,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),

                // Attendance Percentage
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color:
                        (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'analytics',
                        color: isDark
                            ? AppTheme.primaryDark
                            : AppTheme.primaryLight,
                        size: 6.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Attendance Rate: ${_calculateAttendanceRate()}%',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppTheme.primaryDark
                                      : AppTheme.primaryLight,
                                ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3.h),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : onSaveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppTheme.secondaryDark
                          : AppTheme.secondaryLight,
                      foregroundColor: isDark
                          ? AppTheme.onSecondaryDark
                          : AppTheme.onSecondaryLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: isSaving
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 5.w,
                                height: 5.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDark
                                        ? AppTheme.onSecondaryDark
                                        : AppTheme.onSecondaryLight,
                                  ),
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                'Saving Changes...',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconWidget(
                                iconName: 'save',
                                color: isDark
                                    ? AppTheme.onSecondaryDark
                                    : AppTheme.onSecondaryLight,
                                size: 5.w,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'Save Changes',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
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

  Widget _buildStatCard(
      BuildContext context, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  String _calculateAttendanceRate() {
    if (totalStudents == 0) return '0';
    final attendanceRate = ((presentCount + onDutyCount) / totalStudents * 100);
    return attendanceRate.toStringAsFixed(1);
  }
}
