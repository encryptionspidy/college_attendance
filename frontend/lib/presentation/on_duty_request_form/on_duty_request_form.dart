import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

/// Modern On-Duty Request Form - Modal Popup with Liquid Glass Theme
class OnDutyRequestForm extends StatefulWidget {
  const OnDutyRequestForm({super.key});

  @override
  State<OnDutyRequestForm> createState() => _OnDutyRequestFormState();
}

class _OnDutyRequestFormState extends State<OnDutyRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _venueController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  File? _attachedDocument;
  bool _isSubmitting = false;

  // On-Duty type options
  final List<String> _odTypes = [
    'Academic Conference',
    'Technical Workshop',
    'Cultural Event',
    'Sports Event',
    'Industrial Visit',
    'Internship',
    'Project Work',
    'Other',
  ];
  String? _selectedODType;

  // Advisor selection
  List<Map<String, dynamic>> _advisors = [];
  List<String> _selectedAdvisorIds = [];
  bool _isLoadingAdvisors = true;

  @override
  void initState() {
    super.initState();
    _loadAdvisors();
  }

  Future<void> _loadAdvisors() async {
    try {
      final advisors = await ApiService().getAdvisors();
      setState(() {
        _advisors = List<Map<String, dynamic>>.from(advisors);
        _isLoadingAdvisors = false;
      });
    } catch (e) {
      setState(() => _isLoadingAdvisors = false);
      print('Failed to load advisors: $e');
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _venueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8B5CF6),
              surface: Color(0xFF1D1E33),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickDocument() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _attachedDocument = File(image.path);
      });
    }
  }

  void _showAdvisorSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Select Advisor(s)',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _advisors.map((advisor) {
              final advisorId = advisor['id'] as String;
              final isSelected = _selectedAdvisorIds.contains(advisorId);
              return CheckboxListTile(
                title: Text(
                  advisor['name'] ?? advisor['username'] ?? 'Unknown',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Advisor',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                value: isSelected,
                activeColor: const Color(0xFF00D9FF),
                checkColor: Colors.white,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedAdvisorIds.add(advisorId);
                    } else {
                      _selectedAdvisorIds.remove(advisorId);
                    }
                  });
                  Navigator.pop(context);
                  _showAdvisorSelector();
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedAdvisorIds.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: Color(0xFF00D9FF))),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      _showSnackBar('Please select start and end dates', isError: true);
      return;
    }
    if (_selectedODType == null) {
      _showSnackBar('Please select OD type', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Convert document to base64 if attached
      String? imageData;
      if (_attachedDocument != null) {
        final bytes = await _attachedDocument!.readAsBytes();
        imageData = base64Encode(bytes);
      }

      final reason = '[ON-DUTY: $_selectedODType] Event: ${_eventNameController.text.trim()} | Venue: ${_venueController.text.trim()} | ${_descriptionController.text.trim()}';

      final result = await ApiService().createLeaveRequest(
        startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
        reason: reason,
        imageData: imageData,
        advisorIds: _selectedAdvisorIds.isNotEmpty ? _selectedAdvisorIds : null,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (result['success'] == true) {
          _showSnackBar('On-Duty request submitted successfully!');
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) Navigator.pop(context, true);
        } else {
          _showSnackBar(result['error'] ?? 'Failed to submit request', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnackBar('Error: $e', isError: true);
      }
    }
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
    return Container(
      height: 85.h,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0E21),
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

          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, 2.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'On-Duty Request',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Submit your OD application',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // OD Type
                    _buildSectionLabel('On-Duty Type'),
                    _buildGlassContainer(
                      child: DropdownButtonFormField<String>(
                        value: _selectedODType,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Select OD type',
                          hintStyle: TextStyle(color: Colors.white60),
                        ),
                        dropdownColor: const Color(0xFF1D1E33),
                        style: TextStyle(color: Colors.white, fontSize: 13.sp),
                        items: _odTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedODType = value);
                        },
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Event Name
                    _buildSectionLabel('Event/Activity Name'),
                    _buildGlassContainer(
                      child: TextFormField(
                        controller: _eventNameController,
                        style: TextStyle(color: Colors.white, fontSize: 13.sp),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'e.g., National Tech Symposium',
                          hintStyle: TextStyle(color: Colors.white60),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Event name is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Venue
                    _buildSectionLabel('Venue/Location'),
                    _buildGlassContainer(
                      child: TextFormField(
                        controller: _venueController,
                        style: TextStyle(color: Colors.white, fontSize: 13.sp),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'e.g., Anna University, Chennai',
                          hintStyle: TextStyle(color: Colors.white60),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Venue is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Date Selection
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionLabel('Start Date'),
                              _buildGlassContainer(
                                onTap: () => _selectDate(context, true),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _startDate == null
                                          ? 'Select date'
                                          : DateFormat('dd MMM yyyy').format(_startDate!),
                                      style: TextStyle(
                                        color: _startDate == null
                                            ? Colors.white60
                                            : Colors.white,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      color: Color(0xFF8B5CF6),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionLabel('End Date'),
                              _buildGlassContainer(
                                onTap: () => _selectDate(context, false),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _endDate == null
                                          ? 'Select date'
                                          : DateFormat('dd MMM yyyy').format(_endDate!),
                                      style: TextStyle(
                                        color: _endDate == null
                                            ? Colors.white60
                                            : Colors.white,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      color: Color(0xFF8B5CF6),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),

                    // Description
                    _buildSectionLabel('Description'),
                    _buildGlassContainer(
                      child: TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        style: TextStyle(color: Colors.white, fontSize: 13.sp),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Provide details about the event/activity...',
                          hintStyle: TextStyle(color: Colors.white60),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          }
                          if (value.trim().length < 10) {
                            return 'Description must be at least 10 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Advisor Selection
                    _buildSectionLabel('Select Advisor (Optional)'),
                    _isLoadingAdvisors
                        ? _buildGlassContainer(
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF00D9FF),
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : _buildGlassContainer(
                            onTap: () => _showAdvisorSelector(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedAdvisorIds.isEmpty
                                        ? 'Tap to select advisor(s)'
                                        : '${_selectedAdvisorIds.length} advisor(s) selected',
                                    style: TextStyle(
                                      color: _selectedAdvisorIds.isEmpty
                                          ? Colors.white60
                                          : Colors.white,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ),
                                Icon(
                                  _selectedAdvisorIds.isEmpty
                                      ? Icons.person_add_outlined
                                      : Icons.check_circle,
                                  color: _selectedAdvisorIds.isEmpty
                                      ? const Color(0xFF00D9FF)
                                      : const Color(0xFF4CAF50),
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                    SizedBox(height: 2.h),

                    // Attachment
                    _buildSectionLabel('Supporting Document (Optional)'),
                    _buildGlassContainer(
                      onTap: _pickDocument,
                      child: _attachedDocument == null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.attach_file_rounded,
                                  color: Color(0xFF8B5CF6),
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  'Tap to attach document',
                                  style: TextStyle(
                                    color: const Color(0xFF8B5CF6),
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF4CAF50),
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Document attached',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() => _attachedDocument = null);
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    SizedBox(height: 4.h),

                    // Submit Button
                    _buildGlassButton(
                      label: _isSubmitting ? 'Submitting...' : 'Submit Request',
                      onTap: _isSubmitting ? null : _submitRequest,
                      color: const Color(0xFF8B5CF6),
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildGlassContainer({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1E33).withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildGlassButton({
    required String label,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: color.withOpacity(onTap == null ? 0.3 : 0.8),
          borderRadius: BorderRadius.circular(16),
          boxShadow: onTap == null
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

