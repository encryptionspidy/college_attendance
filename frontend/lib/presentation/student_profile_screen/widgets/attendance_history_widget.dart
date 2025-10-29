import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:ui';

import '../../../../core/app_export.dart';

class AttendanceHistoryWidget extends StatefulWidget {
  final List<Map<String, dynamic>> historyData;

  const AttendanceHistoryWidget({
    Key? key,
    required this.historyData,
  }) : super(key: key);

  @override
  State<AttendanceHistoryWidget> createState() =>
      _AttendanceHistoryWidgetState();
}

class _AttendanceHistoryWidgetState extends State<AttendanceHistoryWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredHistory = [];
  String _selectedMonth = 'All';
  final List<String> _months = [
    'All',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June'
  ];

  @override
  void initState() {
    super.initState();
    _filteredHistory = widget.historyData;
    _searchController.addListener(_filterHistory);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterHistory() {
    setState(() {
      _filteredHistory = widget.historyData.where((record) {
        final searchTerm = _searchController.text.toLowerCase();
        final subject = (record['subject'] as String? ?? '').toLowerCase();
        final date = (record['date'] as String? ?? '').toLowerCase();
        final status = (record['status'] as String? ?? '').toLowerCase();

        final matchesSearch = subject.contains(searchTerm) ||
            date.contains(searchTerm) ||
            status.contains(searchTerm);

        final matchesMonth = _selectedMonth == 'All' ||
            (record['date'] as String? ?? '')
                .contains(_selectedMonth.substring(0, 3));

        return matchesSearch && matchesMonth;
      }).toList();
    });
  }

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
                  'Attendance History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                ),
                SizedBox(height: 2.h),
                _buildSearchAndFilter(context, isDark),
                SizedBox(height: 2.h),
                _buildHistoryList(context, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context, bool isDark) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by subject, date, or status...',
            prefixIcon: CustomIconWidget(
              iconName: 'search',
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                    },
                    child: CustomIconWidget(
                      iconName: 'clear',
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                      size: 20,
                    ),
                  )
                : null,
          ),
        ),
        SizedBox(height: 1.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _months.map((month) {
              final isSelected = _selectedMonth == month;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMonth = month;
                  });
                  _filterHistory();
                },
                child: Container(
                  margin: EdgeInsets.only(right: 2.w),
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? AppTheme.primaryDark
                            : AppTheme.primaryLight)
                        : (isDark ? AppTheme.cardDark : AppTheme.cardLight)
                            .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? (isDark
                              ? AppTheme.primaryDark
                              : AppTheme.primaryLight)
                          : (isDark
                              ? AppTheme.dividerDark
                              : AppTheme.dividerLight),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    month,
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
        ),
      ],
    );
  }

  Widget _buildHistoryList(BuildContext context, bool isDark) {
    if (_filteredHistory.isEmpty) {
      return Container(
        height: 20.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'search_off',
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
                size: 48,
              ),
              SizedBox(height: 2.h),
              Text(
                'No attendance records found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Try adjusting your search or filter',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
      itemCount: _filteredHistory.length,
      separatorBuilder: (context, index) => SizedBox(height: 1.h),
      itemBuilder: (context, index) {
        final record = _filteredHistory[index];
        return _buildHistoryItem(context, record, isDark);
      },
    );
  }

  Widget _buildHistoryItem(
      BuildContext context, Map<String, dynamic> record, bool isDark) {
    final status = record['status'] as String? ?? 'Present';
    final statusColor = AppTheme.getStatusColor(status);

    return GestureDetector(
      onLongPress: () => _showRecordDetails(context, record, isDark),
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
              width: 4,
              height: 8.h,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          record['subject'] as String? ?? 'Subject',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppTheme.textPrimaryDark
                                        : AppTheme.textPrimaryLight,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor, width: 1),
                        ),
                        child: Text(
                          status,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
                        iconName: 'calendar_today',
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        record['date'] as String? ?? 'Date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                            ),
                      ),
                      SizedBox(width: 4.w),
                      CustomIconWidget(
                        iconName: 'access_time',
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        record['time'] as String? ?? 'Time',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                            ),
                      ),
                    ],
                  ),
                  if (record['teacher'] != null) ...[
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'person',
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          record['teacher'] as String,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppTheme.textSecondaryDark
                                        : AppTheme.textSecondaryLight,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordDetails(
      BuildContext context, Map<String, dynamic> record, bool isDark) {
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
            Text(
              'Attendance Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
            ),
            SizedBox(height: 2.h),
            _buildDetailRow(context, 'Subject',
                record['subject'] as String? ?? 'N/A', isDark),
            _buildDetailRow(
                context, 'Date', record['date'] as String? ?? 'N/A', isDark),
            _buildDetailRow(
                context, 'Time', record['time'] as String? ?? 'N/A', isDark),
            _buildDetailRow(context, 'Status',
                record['status'] as String? ?? 'N/A', isDark),
            if (record['teacher'] != null)
              _buildDetailRow(
                  context, 'Teacher', record['teacher'] as String, isDark),
            if (record['notes'] != null)
              _buildDetailRow(
                  context, 'Notes', record['notes'] as String, isDark),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Implement dispute functionality
                      _showDisputeDialog(context, record, isDark);
                    },
                    child: const Text('Dispute'),
                  ),
                ),
              ],
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
            width: 20.w,
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

  void _showDisputeDialog(
      BuildContext context, Map<String, dynamic> record, bool isDark) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dispute Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject: ${record['subject']}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Date: ${record['date']}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for dispute',
                hintText:
                    'Please explain why you believe this attendance record is incorrect...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dispute submitted successfully'),
                    backgroundColor: AppTheme.presentStatus,
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
