import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';

class RequestTypeDialog extends StatelessWidget {
  const RequestTypeDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppTheme.primaryDark.withValues(alpha: 0.3),
                        AppTheme.secondaryDark.withValues(alpha: 0.2),
                      ]
                    : [
                        AppTheme.primaryLight.withValues(alpha: 0.3),
                        AppTheme.secondaryLight.withValues(alpha: 0.2),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Text(
                  'Select Request Type',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Choose the type of request you want to submit',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark
                        ? Colors.white70
                        : AppTheme.textSecondaryLight,
                  ),
                ),
                SizedBox(height: 24),

                // Leave Request Button
                _buildRequestTypeButton(
                  context: context,
                  isDark: isDark,
                  title: 'Leave Request',
                  description: 'Submit a leave application',
                  icon: Icons.calendar_today_outlined,
                  color: AppTheme.primaryLight,
                  onTap: () {
                    Navigator.pop(context, 'leave');
                  },
                ),

                SizedBox(height: 16),

                // On-Duty Request Button
                _buildRequestTypeButton(
                  context: context,
                  isDark: isDark,
                  title: 'On-Duty Request',
                  description: 'Apply for official on-duty',
                  icon: Icons.business_center_outlined,
                  color: AppTheme.secondaryLight,
                  onTap: () {
                    Navigator.pop(context, 'on_duty');
                  },
                ),

                SizedBox(height: 16),

                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppTheme.textSecondaryLight,
                      fontSize: 14.sp,
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

  Widget _buildRequestTypeButton({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark
                          ? Colors.white70
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

