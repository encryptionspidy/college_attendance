import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:ui';

import '../../../core/app_export.dart';

class PendingRequestCard extends StatefulWidget {
  final Map<String, dynamic> request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onTap;

  const PendingRequestCard({
    Key? key,
    required this.request,
    required this.onApprove,
    required this.onReject,
    required this.onTap,
  }) : super(key: key);

  @override
  State<PendingRequestCard> createState() => _PendingRequestCardState();
}

class _PendingRequestCardState extends State<PendingRequestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _expandAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded
          ? _animationController.forward()
          : _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                    decoration:
                        AppTheme.glassmorphismDecoration(isLight: !isDark),
                    child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                            onTap: () {
                              _toggleExpanded();
                              widget.onTap();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                                padding: EdgeInsets.all(4.w),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildRequestHeader(),
                                      SizedBox(height: 2.h),
                                      _buildRequestSummary(),
                                      AnimatedBuilder(
                                          animation: _expandAnimation,
                                          builder: (context, child) {
                                            return SizeTransition(
                                                sizeFactor: _expandAnimation,
                                                child: child);
                                          },
                                          child: _buildExpandedContent()),
                                      SizedBox(height: 2.h),
                                      _buildActionButtons(),
                                    ]))))))));
  }

  Widget _buildRequestHeader() {
    return Row(children: [
      CircleAvatar(
          radius: 6.w,
          backgroundColor: AppTheme.lightTheme.primaryColor,
          child: Text(
              (widget.request['studentName'] as String)
                  .substring(0, 1)
                  .toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600))),
      SizedBox(width: 3.w),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.request['studentName'] as String,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
        Text('Roll No: ${widget.request['rollNumber']}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ])),
      Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
          decoration: BoxDecoration(
              color: _getRequestTypeColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _getRequestTypeColor().withValues(alpha: 0.3),
                  width: 1)),
          child: Text(widget.request['type'] as String,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _getRequestTypeColor(), fontWeight: FontWeight.w500))),
    ]);
  }

  Widget _buildRequestSummary() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CustomIconWidget(
            iconName: 'calendar_today',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 4.w),
        SizedBox(width: 2.w),
        Text('${widget.request['startDate']} - ${widget.request['endDate']}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
      ]),
      SizedBox(height: 1.h),
      Text(widget.request['reason'] as String,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: _isExpanded ? null : 2,
          overflow: _isExpanded ? null : TextOverflow.ellipsis),
    ]);
  }

  Widget _buildExpandedContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 2.h),
      Divider(color: Theme.of(context).dividerColor, thickness: 1),
      SizedBox(height: 2.h),
      _buildDetailRow('Department', widget.request['department'] as String),
      SizedBox(height: 1.h),
      _buildDetailRow('Class', widget.request['class'] as String),
      SizedBox(height: 1.h),
      _buildDetailRow('Contact', widget.request['contact'] as String),
      SizedBox(height: 1.h),
      _buildDetailRow('Submitted', widget.request['submittedDate'] as String),
      if (widget.request['hasAttachment'] == true) ...[
        SizedBox(height: 2.h),
        Row(children: [
          CustomIconWidget(
              iconName: 'attach_file',
              color: AppTheme.lightTheme.primaryColor,
              size: 4.w),
          SizedBox(width: 2.w),
          Text('Attachment Available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.primaryColor,
                  fontWeight: FontWeight.w500)),
        ]),
      ],
    ]);
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
          width: 20.w,
          child: Text('$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500))),
      Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
    ]);
  }

  Widget _buildActionButtons() {
    return Row(children: [
      Expanded(
          child: OutlinedButton.icon(
              onPressed: widget.onReject,
              icon: CustomIconWidget(
                  iconName: 'close', color: AppTheme.absentStatus, size: 4.w),
              label: Text('Reject',
                  style: TextStyle(
                      color: AppTheme.absentStatus,
                      fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.absentStatus),
                  padding: EdgeInsets.symmetric(vertical: 1.5.h)))),
      SizedBox(width: 3.w),
      Expanded(
          child: ElevatedButton.icon(
              onPressed: widget.onApprove,
              icon: CustomIconWidget(
                  iconName: 'check', color: Colors.white, size: 4.w),
              label: Text('Approve',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.presentStatus,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h)))),
    ]);
  }

  Color _getRequestTypeColor() {
    switch ((widget.request['type'] as String).toLowerCase()) {
      case 'medical':
        return AppTheme.absentStatus;
      case 'personal':
        return AppTheme.onDutyStatus;
      case 'official':
        return AppTheme.presentStatus;
      default:
        return AppTheme.lightTheme.primaryColor;
    }
  }
}
