import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../services/user_lookup_service.dart';
import '../widgets/admin_glass_widgets.dart';

/// Tab 2: Leave Requests - Read-only audit view of all requests
class LeaveRequestsTab extends StatefulWidget {
  const LeaveRequestsTab({super.key});

  @override
  State<LeaveRequestsTab> createState() => _LeaveRequestsTabState();
}

class _LeaveRequestsTabState extends State<LeaveRequestsTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _filteredRequests = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'All';

  final List<String> _statusFilters = ['All', 'pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);

    try {
      final requests = await ApiService().getAllRequests(limit: 500);

      // Use UserLookupService to get student names
      final userLookup = await UserLookupService().getUserLookup();

      if (mounted) {
        setState(() {
          _requests = requests.map((r) {
            final req = r as Map<String, dynamic>;
            req['student_name'] = UserLookupService().getUserName(
              req['student_id']?.toString(),
              fallback: 'Unknown Student',
            );
            return req;
          }).toList();
          _requests.sort((a, b) {
            final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
            final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
            return dateB.compareTo(dateA);
          });
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredRequests = _requests.where((request) {
        final matchesStatus = _selectedStatusFilter == 'All' ||
                             request['status']?.toString().toLowerCase() == _selectedStatusFilter;
        final searchTerm = _searchController.text.toLowerCase();
        final matchesSearch = searchTerm.isEmpty ||
                             (request['student_name']?.toString().toLowerCase().contains(searchTerm) ?? false) ||
                             (request['reason']?.toString().toLowerCase().contains(searchTerm) ?? false);
        return matchesStatus && matchesSearch;
      }).toList();
    });
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(6.w, 4.h, 6.w, 2.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leave Requests',
                        style: TextStyle(
                          fontSize: 24.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_filteredRequests.length} requests',
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
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00D9FF)),
                ),
              ],
            ),
          ),
        ),

        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1E33).withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search requests...',
                  hintStyle: TextStyle(color: Colors.white60, fontSize: 13.sp),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF00D9FF)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white60),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                ),
                onChanged: (value) => _applyFilters(),
              ),
            ),
          ),
        ),

        // Status Filter Chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 6.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              itemCount: _statusFilters.length,
              itemBuilder: (context, index) {
                final status = _statusFilters[index];
                final isSelected = _selectedStatusFilter == status;

                return Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedStatusFilter = status);
                      _applyFilters();
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
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11.sp,
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
        ),

        SliverToBoxAdapter(child: SizedBox(height: 2.h)),

        // Requests List
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
            ),
          )
        else if (_filteredRequests.isEmpty)
          SliverFillRemaining(
            child: Center(
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
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final request = _filteredRequests[index];
                  final status = request['status']?.toString() ?? 'pending';
                  final statusColor = _getStatusColor(status);

                  return Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: AdminGlassCard(
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
                                      request['student_name'] ?? 'Unknown Student',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'ID: ${request['id']?.toString().substring(0, 8)}',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
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
                          if (request['reason'] != null) ...[
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
                                    request['reason'] ?? '',
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
                        ],
                      ),
                    ),
                  );
                },
                childCount: _filteredRequests.length,
              ),
            ),
          ),

        SliverToBoxAdapter(child: SizedBox(height: 10.h)),
      ],
    );
  }
}

