import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/api_service.dart';
import '../../../services/user_lookup_service.dart';
import '../../student_dashboard/widgets/glass_card.dart';

/// Tab 3: History Tab
///
/// Displays a read-only list of all previously processed requests
/// Provides audit trail for the advisor
class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ApiService _apiService = ApiService();
  final UserLookupService _userLookup = UserLookupService();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String _filterStatus = 'All';

  // Liquid Glass Theme Colors
  static const darkBackground = Color(0xFF0A0E21);
  static const glassBackground = Color(0xFF1D1E33);
  static const accentColor = Color(0xFF00D9FF);
  static const accentSecondary = Color(0xFF8B5CF6);
  static const approveGreen = Color(0xFF4CAF50);
  static const rejectRed = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    try {
      // Load user lookup if not already loaded
      await _userLookup.getUserLookup();

      // Fetch request history from API
      final historyData = await _apiService.getRequestHistory();

      setState(() {
        _history = historyData.map((item) {
          final data = Map<String, dynamic>.from(item);
          // Add student name from lookup
          data['student_name'] = _userLookup.getUserName(data['student_id']);
          // Add approver name from lookup
          if (data['approved_by'] != null) {
            data['approver_name'] = _userLookup.getUserName(data['approved_by']);
          }
          // Ensure required fields have defaults
          data['roll_no'] = data['roll_no'] ?? 'N/A';
          data['course'] = data['course'] ?? 'N/A';
          data['type'] = data['type'] ?? _determineRequestType(data['reason'] ?? '');
          return data;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load history: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  String _determineRequestType(String reason) {
    final lower = reason.toLowerCase();
    if (lower.contains('on-duty') || lower.contains('official')) {
      return 'On-Duty';
    } else if (lower.contains('medical') || lower.contains('sick')) {
      return 'Medical';
    }
    return 'Leave';
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_filterStatus == 'All') return _history;
    return _history.where((h) =>
      h['status']?.toString().toLowerCase() == _filterStatus.toLowerCase()
    ).toList();
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower == 'approved') return approveGreen;
    if (statusLower == 'rejected') return rejectRed;
    return Colors.grey; // For pending or other statuses
  }

  IconData _getStatusIcon(String status) {
    return status == 'Approved' ? Icons.check_circle_rounded : Icons.cancel_rounded;
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'On-Duty':
        return approveGreen;
      case 'Medical':
        return rejectRed;
      case 'Leave':
      default:
        return accentSecondary;
    }
  }

  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: darkBackground,
      body: Column(
        children: [
          // Header Section
          Padding(
            padding: EdgeInsets.all(5.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 2.h),
                // Title
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentColor, accentSecondary],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        color: Colors.white,
                        size: 7.w,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request History',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${_filteredHistory.length} processed requests',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loadHistory,
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: accentColor,
                        size: 6.w,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Approved', 'Rejected'].map((status) {
                      final isSelected = _filterStatus == status;
                      return Padding(
                        padding: EdgeInsets.only(right: 2.w),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(status),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: glassBackground.withOpacity(0.5),
                          selectedColor: accentColor,
                          checkmarkColor: Colors.white,
                          onSelected: (selected) {
                            setState(() => _filterStatus = status);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // History List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(accentColor),
                    ),
                  )
                : _filteredHistory.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        color: accentColor,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          itemCount: _filteredHistory.length,
                          itemBuilder: (context, index) {
                            final record = _filteredHistory[index];
                            return _buildHistoryCard(record);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> record) {
    final status = record['status'] as String;
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final type = record['type'] as String;
    final typeColor = _getTypeColor(type);

    return GlassCard(
      margin: EdgeInsets.only(bottom: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Status
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 4.w),
                    SizedBox(width: 1.w),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),
          Divider(color: Colors.white.withOpacity(0.1)),
          SizedBox(height: 1.5.h),

          // Student Info
          Row(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    (record['student_name'] as String)
                        .split(' ')
                        .map((e) => e[0])
                        .take(2)
                        .join()
                        .toUpperCase(),
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record['student_name'],
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${record['roll_no']} • ${record['course']}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Dates
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: accentColor.withOpacity(0.7), size: 4.w),
              SizedBox(width: 2.w),
              Text(
                '${record['start_date']} to ${record['end_date']}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),

          SizedBox(height: 1.h),

          // Processed Time
          Row(
            children: [
              Icon(Icons.access_time_rounded, color: accentColor.withOpacity(0.7), size: 4.w),
              SizedBox(width: 2.w),
              Text(
                'Processed: ${_formatDateTime(record['created_at'])}',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.white.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),

          // Approver/Rejecter Name
          if (record['approver_name'] != null) ...[
            SizedBox(height: 0.5.h),
            Row(
              children: [
                Icon(Icons.person_outline_rounded, color: accentColor.withOpacity(0.7), size: 4.w),
                SizedBox(width: 2.w),
                Text(
                  '${record['status'] == 'approved' ? 'Approved' : 'Rejected'} by: ${record['approver_name']}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.white.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 1.5.h),

          // Reason Preview
          Text(
            record['reason'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withOpacity(0.6),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: glassBackground.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              color: accentColor,
              size: 20.w,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'No History Yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Processed requests will appear here',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
