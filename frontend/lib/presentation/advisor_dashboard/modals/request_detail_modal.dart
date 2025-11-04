import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../services/api_service.dart';
import 'signature_pad_modal.dart';

/// Request Detail Modal - The Critical Approval Workflow
///
/// This modal displays full request details and handles the approval/rejection flow
/// When approving, it opens the signature pad and updates backend
class RequestDetailModal extends StatefulWidget {
  final Map<String, dynamic> request;
  final VoidCallback onRequestProcessed;

  const RequestDetailModal({
    super.key,
    required this.request,
    required this.onRequestProcessed,
  });

  @override
  State<RequestDetailModal> createState() => _RequestDetailModalState();
}

class _RequestDetailModalState extends State<RequestDetailModal> {
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;

  // Liquid Glass Theme Colors
  static const darkBackground = Color(0xFF0A0E21);
  static const glassBackground = Color(0xFF1D1E33);
  static const accentColor = Color(0xFF00D9FF);
  static const accentSecondary = Color(0xFF8B5CF6);
  static const approveGreen = Color(0xFF4CAF50);
  static const rejectRed = Color(0xFFF44336);

  void _showSignaturePad() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SignaturePadModal(
        onSignatureComplete: (signature) {
          _approveRequest();
        },
      ),
    );
  }

  Future<void> _approveRequest() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final result = await _apiService.approveRequest(widget.request['id'].toString());

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pop(context);
        widget.onRequestProcessed();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text('Request approved successfully'),
                ),
              ],
            ),
            backgroundColor: approveGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception(result['error'] ?? 'Failed to approve request');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: rejectRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectRequest() async {
    if (_isProcessing) return;

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: glassBackground,
        title: Text(
          'Reject Request',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to reject this request? This action cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: rejectRed,
            ),
            child: Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    HapticFeedback.lightImpact();

    try {
      final result = await _apiService.rejectRequest(widget.request['id'].toString());

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pop(context);
        widget.onRequestProcessed();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.cancel_rounded, color: Colors.white),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text('Request rejected'),
                ),
              ],
            ),
            backgroundColor: rejectRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception(result['error'] ?? 'Failed to reject request');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: rejectRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: glassBackground.withOpacity(0.95),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(5.w),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accentColor, accentSecondary],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.description_rounded,
                          color: Colors.white,
                          size: 6.w,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Request Details',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Review and take action',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withOpacity(0.6),
                          size: 6.w,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(5.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Student Info Card
                        _buildInfoSection(
                          'Student Information',
                          Icons.person_rounded,
                          [
                            _buildInfoRow('Name', widget.request['student_name']?.toString()),
                            _buildInfoRow('Roll Number', widget.request['roll_no']?.toString()),
                            _buildInfoRow('Course', widget.request['course']?.toString()),
                          ],
                        ),

                        SizedBox(height: 3.h),

                        // Request Details Card
                        _buildInfoSection(
                          'Request Details',
                          Icons.event_note_rounded,
                          [
                            _buildInfoRow('Type', widget.request['type']?.toString()),
                            _buildInfoRow('Start Date', widget.request['start_date']?.toString()),
                            _buildInfoRow('End Date', widget.request['end_date']?.toString()),
                            _buildInfoRow('Submitted On', widget.request['created_at']?.toString().split('T')[0] ?? 'N/A'),
                          ],
                        ),

                        SizedBox(height: 3.h),

                        // Reason Section
                        _buildReasonSection(),

                        SizedBox(height: 3.h),

                        // Attachment Section (if available)
                        if (widget.request['image_data'] != null) _buildAttachmentSection(),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: EdgeInsets.all(5.w),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _rejectRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: rejectRed,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isProcessing
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cancel_rounded, size: 5.w),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Reject',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _showSignaturePad,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: approveGreen,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isProcessing
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 5.w),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Approve',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: darkBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: darkBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, color: accentColor, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Reason',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            widget.request['reason'],
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: darkBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file_rounded, color: accentColor, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Attachment',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          GestureDetector(
            onTap: () => _showImagePreview(),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.image_rounded, color: accentColor, size: 6.w),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'View Attached Image',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: accentColor, size: 4.w),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePreview() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Blurred background
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            // Image container
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: 80.h,
                  maxWidth: 90.w,
                ),
                decoration: BoxDecoration(
                  color: glassBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Attached Image',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Image
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _apiService.getRequestImageUrl(widget.request['id'].toString()),
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  valueColor: AlwaysStoppedAnimation(accentColor),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: rejectRed,
                                      size: 12.w,
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
