import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/user_lookup_service.dart';

/// Modern Request History Screen - Full Screen with Liquid Glass Theme
class RequestHistoryScreen extends StatefulWidget {
  const RequestHistoryScreen({super.key});

  @override
  State<RequestHistoryScreen> createState() => _RequestHistoryScreenState();
}

class _RequestHistoryScreenState extends State<RequestHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allRequests = [];
  String _selectedFilter = 'All';
  final UserLookupService _userLookup = UserLookupService();

  final List<String> _filterOptions = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);

    try {
      // Load user lookup for approver names
      await _userLookup.getUserLookup();

      final requests = await ApiService().getMyLeaveRequests();
      if (mounted) {
        setState(() {
          _allRequests = requests.map((r) {
            final request = Map<String, dynamic>.from(r as Map<String, dynamic>);
            // Add approver name if request is processed
            if (request['approved_by'] != null) {
              request['approver_name'] = _userLookup.getUserName(request['approved_by']);
            }
            return request;
          }).toList();
          // Sort by date - newest first
          _allRequests.sort((a, b) {
            final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
            final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
            return dateB.compareTo(dateA);
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load requests', isError: true);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_selectedFilter == 'All') return _allRequests;
    return _allRequests
        .where((req) => req['status'].toString().toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFEF5350);
      case 'pending':
        return const Color(0xFFFFA726);
      default:
        return const Color(0xFF42A5F5);
    }
  }

  IconData _getTypeIcon(String reason) {
    if (reason.toLowerCase().contains('on-duty') || reason.toLowerCase().contains('on_duty')) {
      return Icons.business_center_rounded;
    }
    return Icons.event_busy_rounded;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getRequestType(String reason) {
    if (reason.toLowerCase().contains('on-duty') || reason.toLowerCase().contains('on_duty')) {
      return 'On-Duty';
    }
    return 'Leave';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF5350) : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, 2.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  SizedBox(width: 2.w),
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
                          '${_allRequests.length} total requests',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D9FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_filteredRequests.length}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00D9FF),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Chips
            SizedBox(
              height: 6.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                itemCount: _filterOptions.length,
                itemBuilder: (context, index) {
                  final option = _filterOptions[index];
                  final isSelected = _selectedFilter == option;

                  return Padding(
                    padding: EdgeInsets.only(right: 2.w),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedFilter = option);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00D9FF).withOpacity(0.3)
                              : const Color(0xFF1D1E33).withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00D9FF)
                                : Colors.white.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF00D9FF) : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 2.h),

            // Requests List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00D9FF),
                      ),
                    )
                  : _filteredRequests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_rounded,
                                size: 20.w,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'No Requests Found',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                _selectedFilter == 'All'
                                    ? 'You haven\'t submitted any requests yet'
                                    : 'No ${_selectedFilter.toLowerCase()} requests',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadRequests,
                          color: const Color(0xFF00D9FF),
                          backgroundColor: const Color(0xFF1D1E33),
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                            itemCount: _filteredRequests.length,
                            itemBuilder: (context, index) {
                              final request = _filteredRequests[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: 2.h),
                                child: _buildRequestCard(request),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status']?.toString() ?? 'pending';
    final reason = request['reason']?.toString() ?? '';
    final type = _getRequestType(reason);

    return GestureDetector(
      onTap: () => _showRequestDetails(request),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33).withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getTypeIcon(reason),
                        color: const Color(0xFF00D9FF),
                        size: 6.w,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'ID: ${request['id']?.toString().substring(0, 8) ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(status),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Divider(
              color: Colors.white.withOpacity(0.1),
              height: 1,
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 4.w,
                  color: Colors.white.withOpacity(0.6),
                ),
                SizedBox(width: 2.w),
                Text(
                  '${_formatDate(request['start_date'])} - ${_formatDate(request['end_date'])}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            if (reason.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.description_rounded,
                    size: 4.w,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (request['created_at'] != null) ...[
              SizedBox(height: 1.h),
              Text(
                'Submitted: ${_formatDate(request['created_at'])}',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 70.h,
        decoration: const BoxDecoration(
          color: Color(0xFF1D1E33),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 1.h),
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(6.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Request Details',
                          style: TextStyle(
                            fontSize: 20.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: _getStatusColor(request['status'] ?? 'pending').withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(request['status'] ?? 'pending'),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            request['status']?.toString().toUpperCase() ?? 'PENDING',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(request['status'] ?? 'pending'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    _buildDetailRow('Type', _getRequestType(request['reason'] ?? '')),
                    _buildDetailRow('Request ID', request['id']?.toString() ?? 'N/A'),
                    _buildDetailRow('Start Date', _formatDate(request['start_date'])),
                    _buildDetailRow('End Date', _formatDate(request['end_date'])),
                    _buildDetailRow('Reason', request['reason'] ?? 'N/A'),
                    if (request['created_at'] != null)
                      _buildDetailRow('Submitted On', _formatDate(request['created_at'])),
                    if (request['approver_name'] != null)
                      _buildDetailRow(
                        request['status'] == 'approved' ? 'Approved By' : 'Rejected By',
                        request['approver_name'],
                      ),
                    if (request['updated_at'] != null)
                      _buildDetailRow('Last Updated', _formatDate(request['updated_at'])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

