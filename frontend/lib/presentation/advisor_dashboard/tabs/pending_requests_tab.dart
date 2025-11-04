import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/api_service.dart';
import '../../../services/user_lookup_service.dart';
import '../../student_dashboard/widgets/glass_card.dart';
import '../modals/request_detail_modal.dart';

/// Tab 1: Pending Requests Screen
///
/// Displays all pending leave/on-duty requests in a clean list
/// Uses GlassCard widgets matching the Student Dashboard aesthetic
class PendingRequestsTab extends StatefulWidget {
  const PendingRequestsTab({super.key});

  @override
  State<PendingRequestsTab> createState() => _PendingRequestsTabState();
}

class _PendingRequestsTabState extends State<PendingRequestsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ApiService _apiService = ApiService();
  final UserLookupService _userLookup = UserLookupService();
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String _filterType = 'All';

  // Liquid Glass Theme Colors
  static const darkBackground = Color(0xFF0A0E21);
  static const glassBackground = Color(0xFF1D1E33);
  static const accentColor = Color(0xFF00D9FF);
  static const accentSecondary = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    
    try {
      // Load user lookup if not already loaded
      await _userLookup.getUserLookup();

      final data = await _apiService.getPendingRequests();

      // Fetch all users to get complete student details
      final users = await _apiService.getAllUsers(limit: 500);
      final userDetailsMap = <String, Map<String, dynamic>>{};
      for (var user in users) {
        if (user is Map<String, dynamic> && user['id'] != null) {
          userDetailsMap[user['id'].toString()] = user;
        }
      }

      setState(() {
        _requests = data.map((req) {
          final studentId = req['student_id']?.toString();
          final studentDetails = userDetailsMap[studentId];
          final studentName = _userLookup.getUserName(studentId);

          return {
            'id': req['id'],
            'student_id': studentId,
            'student_name': studentName,
            'roll_no': studentDetails?['roll_no'] ?? 'N/A',
            'course': studentDetails?['course'] ?? 'N/A',
            'start_date': req['start_date'],
            'end_date': req['end_date'],
            'reason': req['reason'] ?? '',
            'status': req['status'],
            'created_at': req['created_at'],
            'image_data': req['image_data'],
            'type': _determineRequestType(req['reason'] ?? ''),
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load requests: $e'),
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

  List<Map<String, dynamic>> get _filteredRequests {
    if (_filterType == 'All') return _requests;
    return _requests.where((r) => r['type'] == _filterType).toList();
  }

  void _showRequestDetail(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RequestDetailModal(
        request: request,
        onRequestProcessed: _loadRequests,
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'On-Duty':
        return const Color(0xFF4CAF50);
      case 'Medical':
        return const Color(0xFFF44336);
      case 'Leave':
      default:
        return accentSecondary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'On-Duty':
        return Icons.work_rounded;
      case 'Medical':
        return Icons.medical_services_rounded;
      case 'Leave':
      default:
        return Icons.event_busy_rounded;
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
                        Icons.assignment_outlined,
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
                            'Pending Requests',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${_filteredRequests.length} awaiting review',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loadRequests,
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
                    children: ['All', 'On-Duty', 'Medical', 'Leave'].map((type) {
                      final isSelected = _filterType == type;
                      return Padding(
                        padding: EdgeInsets.only(right: 2.w),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(type),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: glassBackground.withOpacity(0.5),
                          selectedColor: accentColor,
                          checkmarkColor: Colors.white,
                          onSelected: (selected) {
                            setState(() => _filterType = type);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Request List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(accentColor),
                    ),
                  )
                : _filteredRequests.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadRequests,
                        color: accentColor,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          itemCount: _filteredRequests.length,
                          itemBuilder: (context, index) {
                            final request = _filteredRequests[index];
                            return _buildRequestCard(request);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final type = request['type'] as String;
    final typeColor = _getTypeColor(type);
    final typeIcon = _getTypeIcon(type);

    return GlassCard(
      margin: EdgeInsets.only(bottom: 3.h),
      onTap: () => _showRequestDetail(request),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Info Row
          Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    (request['student_name'] as String)
                        .split(' ')
                        .map((e) => e[0])
                        .take(2)
                        .join()
                        .toUpperCase(),
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
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
                      request['student_name'],
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${request['roll_no']} • ${request['course']}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Type Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: typeColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeIcon, color: typeColor, size: 4.w),
                    SizedBox(width: 1.w),
                    Text(
                      type,
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 2.h),
          Divider(color: Colors.white.withOpacity(0.1)),
          SizedBox(height: 1.h),

          // Dates
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: accentColor, size: 4.w),
              SizedBox(width: 2.w),
              Text(
                '${request['start_date']} to ${request['end_date']}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 1.h),

          // Reason Preview
          Text(
            request['reason'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withOpacity(0.7),
              height: 1.4,
            ),
          ),

          SizedBox(height: 2.h),

          // Action Button
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 1.5.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor.withOpacity(0.3), accentSecondary.withOpacity(0.3)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                'Tap to Review',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
              Icons.check_circle_outline_rounded,
              color: accentColor,
              size: 20.w,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'No Pending Requests',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'All requests have been processed',
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
