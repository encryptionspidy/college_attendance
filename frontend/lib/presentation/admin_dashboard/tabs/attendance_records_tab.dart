import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../services/user_lookup_service.dart';
import '../widgets/admin_glass_widgets.dart';

/// Tab 3: Attendance Records - Read-only audit view of all attendance
class AttendanceRecordsTab extends StatefulWidget {
  const AttendanceRecordsTab({super.key});

  @override
  State<AttendanceRecordsTab> createState() => _AttendanceRecordsTabState();
}

class _AttendanceRecordsTabState extends State<AttendanceRecordsTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'All';

  final List<String> _statusFilters = ['All', 'present', 'leave', 'on_duty', 'holiday'];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    try {
      final records = await ApiService().getAllAttendanceRecords(limit: 500);

      // Use UserLookupService to get student names
      await UserLookupService().getUserLookup();

      if (mounted) {
        setState(() {
          _records = records.map((r) {
            final rec = r as Map<String, dynamic>;
            rec['student_name'] = UserLookupService().getUserName(
              rec['student_id']?.toString(),
              fallback: 'Unknown Student',
            );
            return rec;
          }).toList();
          _records.sort((a, b) {
            final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
            final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
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
      _filteredRecords = _records.where((record) {
        final matchesStatus = _selectedStatusFilter == 'All' ||
                             record['status']?.toString().toLowerCase() == _selectedStatusFilter;
        final searchTerm = _searchController.text.toLowerCase();
        final matchesSearch = searchTerm.isEmpty ||
                             (record['student_name']?.toString().toLowerCase().contains(searchTerm) ?? false);
        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return const Color(0xFF4CAF50);
      case 'leave':
      case 'absent':
        return const Color(0xFF42A5F5);
      case 'on_duty':
        return const Color(0xFFFFA726);
      case 'holiday':
        return const Color(0xFF9C27B0);
      default:
        return Colors.white.withOpacity(0.3);
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
                        'Attendance Records',
                        style: TextStyle(
                          fontSize: 24.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_filteredRecords.length} records',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadRecords,
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
                  hintText: 'Search records...',
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
                          status.toUpperCase().replaceAll('_', ' '),
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

        // Records List
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
            ),
          )
        else if (_filteredRecords.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 20.w,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'No Records Found',
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
                  final record = _filteredRecords[index];
                  final status = record['status']?.toString() ?? 'present';
                  final statusColor = _getStatusColor(status);

                  return Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: AdminGlassCard(
                      child: Row(
                        children: [
                          Container(
                            width: 12.w,
                            height: 12.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor.withOpacity(0.3),
                              border: Border.all(color: statusColor, width: 2),
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: statusColor,
                              size: 6.w,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record['student_name'] ?? 'Unknown Student',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  'Date: ${_formatDate(record['date'])}',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.white.withOpacity(0.6),
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
                              border: Border.all(color: statusColor, width: 1),
                            ),
                            child: Text(
                              status.toUpperCase().replaceAll('_', ' '),
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _filteredRecords.length,
              ),
            ),
          ),

        SliverToBoxAdapter(child: SizedBox(height: 10.h)),
      ],
    );
  }
}

