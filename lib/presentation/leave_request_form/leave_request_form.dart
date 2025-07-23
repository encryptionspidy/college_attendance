import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/date_picker_widget.dart';
import './widgets/description_input_widget.dart';
import './widgets/form_header_widget.dart';
import './widgets/image_attachment_widget.dart';
import './widgets/reason_dropdown_widget.dart';
import './widgets/submit_button_widget.dart';

class LeaveRequestForm extends StatefulWidget {
  const LeaveRequestForm({Key? key}) : super(key: key);

  @override
  State<LeaveRequestForm> createState() => _LeaveRequestFormState();
}

class _LeaveRequestFormState extends State<LeaveRequestForm>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  // Form data
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedReason;
  String _description = '';
  List<String> _attachedImages = [];

  // Form validation
  final Map<String, String?> _errors = {};
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  // Auto-save timer
  DateTime _lastSaved = DateTime.now();

  // Mock data for demonstration
  final Map<String, dynamic> _mockUserData = {
    "id": "STU001",
    "name": "Sarah Johnson",
    "email": "sarah.johnson@college.edu",
    "rollNumber": "CS2021001",
    "department": "Computer Science",
    "year": "3rd Year",
    "advisor": "Dr. Michael Chen",
  };

  @override
  void initState() {
    super.initState();
    _loadDraftData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor:
            isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        body: Stack(
          children: [
            // Glassmorphism background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppTheme.primaryDark.withValues(alpha: 0.1),
                          AppTheme.secondaryDark.withValues(alpha: 0.05),
                        ]
                      : [
                          AppTheme.primaryLight.withValues(alpha: 0.1),
                          AppTheme.secondaryLight.withValues(alpha: 0.05),
                        ],
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(isDark),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Column(
                        children: [
                          SizedBox(height: 2.h),
                          FormHeaderWidget(
                            currentStep: _getCurrentStep(),
                            totalSteps: 5,
                          ),
                          SizedBox(height: 3.h),
                          _buildFormContent(),
                          SizedBox(height: 10.h), // Space for sticky button
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Sticky submit button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: SubmitButtonWidget(
                    isLoading: _isLoading,
                    onSubmit: _submitForm,
                    isEnabled: _isFormValid(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.surfaceDark.withValues(alpha: 0.9)
            : AppTheme.surfaceLight.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _onBackPressed(),
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color:
                  isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              size: 24,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leave Request',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _mockUserData["name"] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_hasUnsavedChanges)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.onDutyStatus : AppTheme.onDutyStatus,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Draft',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      children: [
        DatePickerWidget(
          label: 'From Date',
          selectedDate: _fromDate,
          onDateSelected: (date) {
            setState(() {
              _fromDate = date;
              _hasUnsavedChanges = true;
              _errors.remove('fromDate');
              // Auto-adjust to date if it's before from date
              if (_toDate != null && _toDate!.isBefore(date)) {
                _toDate = date;
              }
            });
            _saveDraft();
          },
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          errorText: _errors['fromDate'],
        ),
        SizedBox(height: 3.h),
        DatePickerWidget(
          label: 'To Date',
          selectedDate: _toDate,
          onDateSelected: (date) {
            setState(() {
              _toDate = date;
              _hasUnsavedChanges = true;
              _errors.remove('toDate');
            });
            _saveDraft();
          },
          firstDate: _fromDate ?? DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          errorText: _errors['toDate'],
        ),
        SizedBox(height: 3.h),
        ReasonDropdownWidget(
          selectedReason: _selectedReason,
          onReasonChanged: (reason) {
            setState(() {
              _selectedReason = reason;
              _hasUnsavedChanges = true;
              _errors.remove('reason');
            });
            _saveDraft();
          },
          errorText: _errors['reason'],
        ),
        SizedBox(height: 3.h),
        DescriptionInputWidget(
          description: _description,
          onDescriptionChanged: (description) {
            setState(() {
              _description = description;
              _hasUnsavedChanges = true;
              _errors.remove('description');
            });
            _saveDraft();
          },
          errorText: _errors['description'],
        ),
        SizedBox(height: 3.h),
        ImageAttachmentWidget(
          attachedImages: _attachedImages,
          onImagesChanged: (images) {
            setState(() {
              _attachedImages = images;
              _hasUnsavedChanges = true;
            });
            _saveDraft();
          },
        ),
      ],
    );
  }

  int _getCurrentStep() {
    int step = 0;
    if (_fromDate != null) step++;
    if (_toDate != null) step++;
    if (_selectedReason != null) step++;
    if (_description.isNotEmpty) step++;
    if (_attachedImages.isNotEmpty) step++;
    return step;
  }

  bool _isFormValid() {
    return _fromDate != null &&
        _toDate != null &&
        _selectedReason != null &&
        _description.trim().isNotEmpty &&
        _description.trim().length >= 10;
  }

  void _validateForm() {
    _errors.clear();

    if (_fromDate == null) {
      _errors['fromDate'] = 'Please select start date';
    }

    if (_toDate == null) {
      _errors['toDate'] = 'Please select end date';
    } else if (_fromDate != null && _toDate!.isBefore(_fromDate!)) {
      _errors['toDate'] = 'End date must be after start date';
    }

    if (_selectedReason == null) {
      _errors['reason'] = 'Please select a reason';
    }

    if (_description.trim().isEmpty) {
      _errors['description'] = 'Please provide a detailed explanation';
    } else if (_description.trim().length < 10) {
      _errors['description'] = 'Description must be at least 10 characters';
    }
  }

  Future<void> _submitForm() async {
    _validateForm();

    if (_errors.isNotEmpty) {
      setState(() {});
      _showErrorMessage('Please fix the errors before submitting');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Generate mock tracking number
      final trackingNumber =
          'LR${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      // Haptic feedback
      HapticFeedback.lightImpact();

      // Clear draft
      _clearDraft();

      // Show success dialog
      _showSuccessDialog(trackingNumber);
    } catch (e) {
      _showErrorMessage('Failed to submit request. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(String trackingNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Dialog(
          backgroundColor: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppTheme.presentStatus.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'check_circle',
                    color: AppTheme.presentStatus,
                    size: 48,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Request Submitted!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.presentStatus,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Your leave request has been submitted successfully.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.h),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.surfaceDark.withValues(alpha: 0.5)
                        : AppTheme.surfaceLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Tracking Number',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                            ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        trackingNumber,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppTheme.primaryDark
                                      : AppTheme.primaryLight,
                                ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.errorDark
            : AppTheme.errorLight,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      return await _showUnsavedChangesDialog() ?? false;
    }
    return true;
  }

  void _onBackPressed() async {
    if (_hasUnsavedChanges) {
      final shouldPop = await _showUnsavedChangesDialog();
      if (shouldPop == true && mounted) {
        Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool?> _showUnsavedChangesDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        title: Text(
          'Unsaved Changes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        content: Text(
          'You have unsaved changes. Do you want to save as draft before leaving?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearDraft();
              Navigator.of(context).pop(true);
            },
            child: Text(
              'Discard',
              style: TextStyle(
                color: isDark ? AppTheme.errorDark : AppTheme.errorLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveDraft();
              Navigator.of(context).pop(true);
            },
            child: const Text('Save Draft'),
          ),
        ],
      ),
    );
  }

  void _loadDraftData() {
    // Simulate loading draft data from local storage
    // In real implementation, this would load from Hive database
  }

  void _saveDraft() {
    _lastSaved = DateTime.now();
    // Simulate saving draft data to local storage
    // In real implementation, this would save to Hive database
  }

  void _clearDraft() {
    setState(() {
      _hasUnsavedChanges = false;
    });
    // Simulate clearing draft data from local storage
    // In real implementation, this would clear from Hive database
  }
}
