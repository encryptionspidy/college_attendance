import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/bulk_action_bar.dart';
import './widgets/dashboard_header.dart';
import './widgets/pending_request_card.dart';
import './widgets/request_detail_modal.dart';
import './widgets/signature_pad_modal.dart';

class AdvisorApprovalDashboard extends StatefulWidget {
  const AdvisorApprovalDashboard({Key? key}) : super(key: key);

  @override
  State<AdvisorApprovalDashboard> createState() =>
      _AdvisorApprovalDashboardState();
}

class _AdvisorApprovalDashboardState extends State<AdvisorApprovalDashboard>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;

  String _selectedFilter = 'All';
  List<int> _selectedRequests = [];
  bool _isRefreshing = false;

  // Mock data for pending requests
  final List<Map<String, dynamic>> _pendingRequests = [
    {
      'id': 1,
      'studentName': 'Sarah Johnson',
      'rollNumber': 'CS2021001',
      'department': 'Computer Science',
      'class': 'B.Tech CSE - III Year',
      'contact': '+1 234-567-8901',
      'email': 'sarah.johnson@college.edu',
      'type': 'Medical',
      'startDate': '2025-01-25',
      'endDate': '2025-01-27',
      'duration': 3,
      'reason':
          'Medical emergency - hospitalization required for surgery. Doctor has advised complete bed rest for recovery period.',
      'submittedDate': '2025-01-22',
      'hasAttachment': true,
      'attachmentUrl':
          'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=500&h=600&fit=crop',
      'overallAttendance': 92,
      'monthlyAttendance': 88,
      'attendanceHistory': [
        {'date': '2025-01-21', 'status': 'Present'},
        {'date': '2025-01-20', 'status': 'Present'},
        {'date': '2025-01-19', 'status': 'Absent'},
        {'date': '2025-01-18', 'status': 'Present'},
        {'date': '2025-01-17', 'status': 'On-Duty'},
      ],
    },
    {
      'id': 2,
      'studentName': 'Michael Chen',
      'rollNumber': 'EE2021045',
      'department': 'Electrical Engineering',
      'class': 'B.Tech EEE - III Year',
      'contact': '+1 234-567-8902',
      'email': 'michael.chen@college.edu',
      'type': 'Personal',
      'startDate': '2025-01-28',
      'endDate': '2025-01-30',
      'duration': 3,
      'reason':
          'Family wedding ceremony - need to attend important family function in hometown.',
      'submittedDate': '2025-01-23',
      'hasAttachment': false,
      'attachmentUrl': '',
      'overallAttendance': 85,
      'monthlyAttendance': 82,
      'attendanceHistory': [
        {'date': '2025-01-21', 'status': 'Present'},
        {'date': '2025-01-20', 'status': 'Absent'},
        {'date': '2025-01-19', 'status': 'Present'},
        {'date': '2025-01-18', 'status': 'Present'},
        {'date': '2025-01-17', 'status': 'Present'},
      ],
    },
    {
      'id': 3,
      'studentName': 'Emily Rodriguez',
      'rollNumber': 'ME2021078',
      'department': 'Mechanical Engineering',
      'class': 'B.Tech ME - III Year',
      'contact': '+1 234-567-8903',
      'email': 'emily.rodriguez@college.edu',
      'type': 'Official',
      'startDate': '2025-02-01',
      'endDate': '2025-02-03',
      'duration': 3,
      'reason':
          'Representing college in National Technical Symposium - selected as team leader for robotics competition.',
      'submittedDate': '2025-01-24',
      'hasAttachment': true,
      'attachmentUrl':
          'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=500&h=600&fit=crop',
      'overallAttendance': 96,
      'monthlyAttendance': 94,
      'attendanceHistory': [
        {'date': '2025-01-21', 'status': 'Present'},
        {'date': '2025-01-20', 'status': 'Present'},
        {'date': '2025-01-19', 'status': 'Present'},
        {'date': '2025-01-18', 'status': 'On-Duty'},
        {'date': '2025-01-17', 'status': 'Present'},
      ],
    },
    {
      'id': 4,
      'studentName': 'David Kumar',
      'rollNumber': 'CE2021032',
      'department': 'Civil Engineering',
      'class': 'B.Tech CE - III Year',
      'contact': '+1 234-567-8904',
      'email': 'david.kumar@college.edu',
      'type': 'Medical',
      'startDate': '2025-01-26',
      'endDate': '2025-01-28',
      'duration': 3,
      'reason':
          'Dental surgery scheduled - wisdom tooth extraction requires recovery time as advised by dentist.',
      'submittedDate': '2025-01-23',
      'hasAttachment': true,
      'attachmentUrl':
          'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=500&h=600&fit=crop',
      'overallAttendance': 89,
      'monthlyAttendance': 91,
      'attendanceHistory': [
        {'date': '2025-01-21', 'status': 'Present'},
        {'date': '2025-01-20', 'status': 'Present'},
        {'date': '2025-01-19', 'status': 'Present'},
        {'date': '2025-01-18', 'status': 'Absent'},
        {'date': '2025-01-17', 'status': 'Present'},
      ],
    },
    {
      'id': 5,
      'studentName': 'Lisa Thompson',
      'rollNumber': 'IT2021067',
      'department': 'Information Technology',
      'class': 'B.Tech IT - III Year',
      'contact': '+1 234-567-8905',
      'email': 'lisa.thompson@college.edu',
      'type': 'Personal',
      'startDate': '2025-02-05',
      'endDate': '2025-02-07',
      'duration': 3,
      'reason':
          'Job interview at major tech company - final round of interviews for internship opportunity.',
      'submittedDate': '2025-01-24',
      'hasAttachment': false,
      'attachmentUrl': '',
      'overallAttendance': 93,
      'monthlyAttendance': 95,
      'attendanceHistory': [
        {'date': '2025-01-21', 'status': 'Present'},
        {'date': '2025-01-20', 'status': 'Present'},
        {'date': '2025-01-19', 'status': 'On-Duty'},
        {'date': '2025-01-18', 'status': 'Present'},
        {'date': '2025-01-17', 'status': 'Present'},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _refreshAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _refreshController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_selectedFilter == 'All') {
      return _pendingRequests;
    }
    return _pendingRequests
        .where((request) => request['type'] == _selectedFilter)
        .toList();
  }

  Future<void> _refreshRequests() async {
    setState(() {
      _isRefreshing = true;
    });

    _refreshController.forward();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    _refreshController.reverse();

    setState(() {
      _isRefreshing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Requests updated successfully'),
          backgroundColor: AppTheme.presentStatus,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSignaturePad(Map<String, dynamic> request) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SignaturePadModal(
        onSignatureComplete: (signature) {
          _approveRequest(request, signature);
        },
      ),
    );
  }

  void _showRequestDetail(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RequestDetailModal(
        request: request,
        onApprove: () {
          Navigator.pop(context);
          _showSignaturePad(request);
        },
        onReject: () {
          Navigator.pop(context);
          _rejectRequest(request);
        },
      ),
    );
  }

  void _approveRequest(Map<String, dynamic> request, List<Offset> signature) {
    HapticFeedback.mediumImpact();

    setState(() {
      _pendingRequests.removeWhere((r) => r['id'] == request['id']);
      _selectedRequests.remove(request['id']);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: Colors.white,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text('Request approved for ${request['studentName']}'),
            ),
          ],
        ),
        backgroundColor: AppTheme.presentStatus,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _rejectRequest(Map<String, dynamic> request) {
    HapticFeedback.lightImpact();

    setState(() {
      _pendingRequests.removeWhere((r) => r['id'] == request['id']);
      _selectedRequests.remove(request['id']);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'cancel',
              color: Colors.white,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text('Request rejected for ${request['studentName']}'),
            ),
          ],
        ),
        backgroundColor: AppTheme.absentStatus,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleRequestSelection(int requestId) {
    setState(() {
      _selectedRequests.contains(requestId)
          ? _selectedRequests.remove(requestId)
          : _selectedRequests.add(requestId);
    });
  }

  void _approveAllSelected() {
    final selectedRequestsData = _pendingRequests
        .where((request) => _selectedRequests.contains(request['id']))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk Approval'),
        content: Text(
          'Are you sure you want to approve ${_selectedRequests.length} requests? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              for (final request in selectedRequestsData) {
                _approveRequest(request, []);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.presentStatus,
            ),
            child: Text('Approve All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _rejectAllSelected() {
    final selectedRequestsData = _pendingRequests
        .where((request) => _selectedRequests.contains(request['id']))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk Rejection'),
        content: Text(
          'Are you sure you want to reject ${_selectedRequests.length} requests? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              for (final request in selectedRequestsData) {
                _rejectRequest(request);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.absentStatus,
            ),
            child: Text('Reject All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedRequests.clear();
    });
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'search',
              color: AppTheme.lightTheme.primaryColor,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Text('Search Requests'),
          ],
        ),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Search by student name or roll number...',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'search',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 4.w,
              ),
            ),
          ),
          onChanged: (value) {
            // Implement search functionality
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Search'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Approval Dashboard',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/student-profile-screen'),
            icon: CustomIconWidget(
              iconName: 'person',
              color: Theme.of(context).appBarTheme.iconTheme?.color ??
                  Colors.white,
              size: 6.w,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'logout':
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login-screen',
                    (route) => false,
                  );
                  break;
                case 'settings':
                  // Navigate to settings
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'settings',
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Text('Settings'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'logout',
                      color: AppTheme.absentStatus,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Text('Logout',
                        style: TextStyle(color: AppTheme.absentStatus)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshRequests,
            color: AppTheme.lightTheme.primaryColor,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: DashboardHeader(
                    pendingCount: _filteredRequests.length,
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (filter) {
                      setState(() {
                        _selectedFilter = filter;
                        _selectedRequests.clear();
                      });
                    },
                    onSearchTap: _showSearchDialog,
                  ),
                ),
                _filteredRequests.isEmpty
                    ? SliverFillRemaining(
                        child: _buildEmptyState(context),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final request = _filteredRequests[index];
                            final isSelected =
                                _selectedRequests.contains(request['id']);

                            return GestureDetector(
                              onLongPress: () =>
                                  _toggleRequestSelection(request['id']),
                              child: Container(
                                decoration: isSelected
                                    ? BoxDecoration(
                                        color: AppTheme.lightTheme.primaryColor
                                            .withValues(alpha: 0.1),
                                        border: Border.all(
                                          color:
                                              AppTheme.lightTheme.primaryColor,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      )
                                    : null,
                                margin: isSelected
                                    ? EdgeInsets.symmetric(
                                        horizontal: 2.w, vertical: 0.5.h)
                                    : null,
                                child: PendingRequestCard(
                                  request: request,
                                  onApprove: () => _showSignaturePad(request),
                                  onReject: () => _rejectRequest(request),
                                  onTap: () => _showRequestDetail(request),
                                ),
                              ),
                            );
                          },
                          childCount: _filteredRequests.length,
                        ),
                      ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 15.h),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BulkActionBar(
              selectedCount: _selectedRequests.length,
              onApproveAll: _approveAllSelected,
              onRejectAll: _rejectAllSelected,
              onClearSelection: _clearSelection,
            ),
          ),
          if (_isRefreshing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _refreshAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _refreshAnimation.value * 2 * 3.14159,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: AppTheme.lightTheme.primaryColor,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Updating requests...',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: 'inbox',
              color: AppTheme.lightTheme.primaryColor,
              size: 15.w,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'No Pending Requests',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 1.h),
          Text(
            'All requests have been processed.\nPull down to refresh.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          SizedBox(height: 4.h),
          ElevatedButton.icon(
            onPressed: _refreshRequests,
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: Colors.white,
              size: 4.w,
            ),
            label: Text(
              'Refresh',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
