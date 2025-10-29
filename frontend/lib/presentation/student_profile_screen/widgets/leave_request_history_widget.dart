import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class LeaveRequestHistoryWidget extends StatefulWidget {
  final List<Map<String, dynamic>> leaveRequests;

  const LeaveRequestHistoryWidget({
    Key? key,
    required this.leaveRequests,
  }) : super(key: key);

  @override
  State<LeaveRequestHistoryWidget> createState() =>
      _LeaveRequestHistoryWidgetState();
}

class _LeaveRequestHistoryWidgetState extends State<LeaveRequestHistoryWidget> {
  String _selectedFilter = 'All';
  final List<String> _statusFilters = [
    'All',
    'Pending',
    'Approved',
    'Rejected'
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredRequests = _getFilteredRequests();

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Leave Requests',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                          ),
                    ),
                    _buildStatusSummary(context, isDark),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildStatusFilter(context, isDark),
                SizedBox(height: 2.h),
                _buildRequestsList(context, filteredRequests, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSummary(BuildContext context, bool isDark) {
    final pending =
        widget.leaveRequests.where((req) => req['status'] == 'Pending').length;
    final approved =
        widget.leaveRequests.where((req) => req['status'] == 'Approved').length;
    final rejected =
        widget.leaveRequests.where((req) => req['status'] == 'Rejected').length;

    return Row(
      children: [
        _buildSummaryBadge(context, pending.toString(), 'Pending',
            AppTheme.onDutyStatus, isDark),
        SizedBox(width: 1.w),
        _buildSummaryBadge(context, approved.toString(), 'Approved',
            AppTheme.presentStatus, isDark),
        SizedBox(width: 1.w),
        _buildSummaryBadge(context, rejected.toString(), 'Rejected',
            AppTheme.absentStatus, isDark),
      ],
    );
  }

  Widget _buildSummaryBadge(BuildContext context, String count, String label,
      Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontSize: 8.sp,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statusFilters.map((status) {
          final isSelected = _selectedFilter == status;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = status;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                    : (isDark ? AppTheme.cardDark : AppTheme.cardLight)
                        .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                      : (isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
                  width: 1,
                ),
              ),
              child: Text(
                status,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? (isDark
                              ? AppTheme.onPrimaryDark
                              : AppTheme.onPrimaryLight)
                          : (isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRequestsList(
      BuildContext context, List<Map<String, dynamic>> requests, bool isDark) {
    if (requests.isEmpty) {
      return Container(
        height: 15.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'event_busy',
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
                size: 48,
              ),
              SizedBox(height: 1.h),
              Text(
                'No ${_selectedFilter.toLowerCase()} requests found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      separatorBuilder: (context, index) => SizedBox(height: 1.h),
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildRequestItem(context, request, isDark);
      },
    );
  }

  Widget _buildRequestItem(
      BuildContext context, Map<String, dynamic> request, bool isDark) {
    final status = request['status'] as String? ?? 'Pending';
    final statusColor = _getStatusColor(status);

    return GestureDetector(
      onTap: () => _showRequestDetails(context, request, isDark),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request['type'] as String? ?? 'Leave Request',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    status,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'date_range',
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  '${request['startDate']} - ${request['endDate']}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'schedule',
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Applied on ${request['appliedDate']}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                ),
              ],
            ),
            if (request['reason'] != null) ...[
              SizedBox(height: 1.h),
              Text(
                request['reason'] as String,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                      fontStyle: FontStyle.italic,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (status == 'Approved' && request['approvedBy'] != null) ...[
              SizedBox(height: 1.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'verified',
                    color: AppTheme.presentStatus,
                    size: 16,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'Approved by ${request['approvedBy']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.presentStatus,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ],
            if (status == 'Rejected' && request['rejectionReason'] != null) ...[
              SizedBox(height: 1.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'cancel',
                    color: AppTheme.absentStatus,
                    size: 16,
                  ),
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Text(
                      request['rejectionReason'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.absentStatus,
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRequestDetails(
      BuildContext context, Map<String, dynamic> request, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Request Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                            request['status'] as String? ?? 'Pending')
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(
                          request['status'] as String? ?? 'Pending'),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    request['status'] as String? ?? 'Pending',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(
                              request['status'] as String? ?? 'Pending'),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildDetailRow(
                context, 'Type', request['type'] as String? ?? 'N/A', isDark),
            _buildDetailRow(context, 'Start Date',
                request['startDate'] as String? ?? 'N/A', isDark),
            _buildDetailRow(context, 'End Date',
                request['endDate'] as String? ?? 'N/A', isDark),
            _buildDetailRow(context, 'Applied Date',
                request['appliedDate'] as String? ?? 'N/A', isDark),
            if (request['reason'] != null)
              _buildDetailRow(
                  context, 'Reason', request['reason'] as String, isDark),
            if (request['approvedBy'] != null)
              _buildDetailRow(context, 'Approved By',
                  request['approvedBy'] as String, isDark),
            if (request['approvedDate'] != null)
              _buildDetailRow(context, 'Approved Date',
                  request['approvedDate'] as String, isDark),
            if (request['rejectionReason'] != null)
              _buildDetailRow(context, 'Rejection Reason',
                  request['rejectionReason'] as String, isDark),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, String label, String value, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredRequests() {
    if (_selectedFilter == 'All') {
      return widget.leaveRequests;
    }
    return widget.leaveRequests
        .where((request) => request['status'] == _selectedFilter)
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppTheme.presentStatus;
      case 'rejected':
        return AppTheme.absentStatus;
      case 'pending':
      default:
        return AppTheme.onDutyStatus;
    }
  }
}
