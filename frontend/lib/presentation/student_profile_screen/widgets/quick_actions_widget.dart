import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class QuickActionsWidget extends StatelessWidget {
  final VoidCallback? onSubmitRequest;
  final VoidCallback? onDownloadReport;

  const QuickActionsWidget({
    Key? key,
    this.onSubmitRequest,
    this.onDownloadReport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: AppTheme.glassmorphismDecoration(isLight: !isDark),
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Submit New Request',
                        'add_circle_outline',
                        isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                        onSubmitRequest ??
                            () => _navigateToLeaveRequest(context),
                        isDark,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Download Report',
                        'download',
                        isDark
                            ? AppTheme.secondaryDark
                            : AppTheme.secondaryLight,
                        onDownloadReport ??
                            () => _downloadAttendanceReport(context),
                        isDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'View Calendar',
                        'calendar_month',
                        AppTheme.onDutyStatus,
                        () => _navigateToCalendar(context),
                        isDark,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        'Contact Advisor',
                        'contact_support',
                        AppTheme.presentStatus,
                        () => _contactAdvisor(context),
                        isDark,
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

  Widget _buildActionButton(
    BuildContext context,
    String title,
    String iconName,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: iconName,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToLeaveRequest(BuildContext context) {
    Navigator.pushNamed(context, '/leave-request-form');
  }

  void _downloadAttendanceReport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDownloadOptions(context),
    );
  }

  void _navigateToCalendar(BuildContext context) {
    Navigator.pushNamed(context, '/student-dashboard');
  }

  void _contactAdvisor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _buildContactDialog(context),
    );
  }

  Widget _buildDownloadOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Download Attendance Report',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
          ),
          SizedBox(height: 2.h),
          _buildDownloadOption(
            context,
            'PDF Report',
            'Complete attendance report with charts and statistics',
            'picture_as_pdf',
            () => _downloadPDF(context),
            isDark,
          ),
          SizedBox(height: 1.h),
          _buildDownloadOption(
            context,
            'CSV Data',
            'Raw attendance data for analysis',
            'table_chart',
            () => _downloadCSV(context),
            isDark,
          ),
          SizedBox(height: 1.h),
          _buildDownloadOption(
            context,
            'Monthly Summary',
            'Month-wise attendance summary',
            'calendar_view_month',
            () => _downloadMonthlySummary(context),
            isDark,
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildDownloadOption(
    BuildContext context,
    String title,
    String description,
    String iconName,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.cardDark : AppTheme.cardLight)
              .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
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
                color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: iconName,
                  color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                  size: 24,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'download',
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Contact Advisor'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: CustomIconWidget(
              iconName: 'email',
              color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
              size: 24,
            ),
            title: const Text('Send Email'),
            subtitle: const Text('advisor@college.edu'),
            onTap: () {
              Navigator.pop(context);
              _sendEmail(context);
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'phone',
              color: isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight,
              size: 24,
            ),
            title: const Text('Call'),
            subtitle: const Text('+1 (555) 123-4567'),
            onTap: () {
              Navigator.pop(context);
              _makeCall(context);
            },
          ),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'chat',
              color: AppTheme.presentStatus,
              size: 24,
            ),
            title: const Text('Chat'),
            subtitle: const Text('Start a conversation'),
            onTap: () {
              Navigator.pop(context);
              _startChat(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _downloadPDF(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF report downloaded successfully'),
        backgroundColor: AppTheme.presentStatus,
      ),
    );
  }

  void _downloadCSV(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV data downloaded successfully'),
        backgroundColor: AppTheme.presentStatus,
      ),
    );
  }

  void _downloadMonthlySummary(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Monthly summary downloaded successfully'),
        backgroundColor: AppTheme.presentStatus,
      ),
    );
  }

  void _sendEmail(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening email client...'),
        backgroundColor: AppTheme.presentStatus,
      ),
    );
  }

  void _makeCall(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening phone dialer...'),
        backgroundColor: AppTheme.presentStatus,
      ),
    );
  }

  void _startChat(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat feature coming soon...'),
        backgroundColor: AppTheme.onDutyStatus,
      ),
    );
  }
}
