import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StudentCardWidget extends StatelessWidget {
  final Map<String, dynamic> student;
  final String attendanceStatus;
  final Function(String) onStatusChanged;
  final VoidCallback? onLongPress;

  const StudentCardWidget({
    Key? key,
    required this.student,
    required this.attendanceStatus,
    required this.onStatusChanged,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark ? AppTheme.shadowDark : AppTheme.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: AppTheme.glassmorphismDecoration(isLight: !isDark),
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  // Student Avatar
                  Container(
                    width: 15.w,
                    height: 15.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.getStatusColor(attendanceStatus),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: CustomImageWidget(
                        imageUrl: student['avatar'] as String? ??
                            'https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png',
                        width: 15.w,
                        height: 15.w,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),

                  // Student Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['name'] as String? ?? 'Unknown Student',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Roll No: ${student['rollNumber'] as String? ?? 'N/A'}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppTheme.textSecondaryDark
                                        : AppTheme.textSecondaryLight,
                                  ),
                        ),
                        if (student['department'] != null) ...[
                          SizedBox(height: 0.5.h),
                          Text(
                            student['department'] as String,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? AppTheme.textSecondaryDark
                                          : AppTheme.textSecondaryLight,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Status Toggle Buttons
                  Column(
                    children: [
                      _buildStatusButton(
                        context,
                        'Present',
                        AppTheme.presentStatus,
                        attendanceStatus == 'Present',
                      ),
                      SizedBox(height: 1.h),
                      _buildStatusButton(
                        context,
                        'Absent',
                        AppTheme.absentStatus,
                        attendanceStatus == 'Absent',
                      ),
                      SizedBox(height: 1.h),
                      _buildStatusButton(
                        context,
                        'On-Duty',
                        AppTheme.onDutyStatus,
                        attendanceStatus == 'On-Duty',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton(
      BuildContext context, String status, Color color, bool isSelected) {
    return GestureDetector(
      onTap: () => onStatusChanged(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 20.w,
        height: 5.h,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            status,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected ? Colors.white : color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
