import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/api_service.dart';
import '../widgets/admin_glass_widgets.dart';

enum UserFormMode { create, edit }

/// User Form Modal - Role-specific forms for creating/editing users
class UserFormModal extends StatefulWidget {
  final UserFormMode mode;
  final Map<String, dynamic>? userData;

  const UserFormModal({
    super.key,
    required this.mode,
    this.userData,
  });

  @override
  State<UserFormModal> createState() => _UserFormModalState();
}

class _UserFormModalState extends State<UserFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _semesterController = TextEditingController();
  final _yearController = TextEditingController();
  final _cgpaController = TextEditingController();
  final _courseController = TextEditingController();
  final _sectionController = TextEditingController();

  String _selectedRole = 'student';
  bool _isSubmitting = false;

  final List<String> _roles = ['student', 'advisor', 'attendance_incharge', 'admin'];

  @override
  void initState() {
    super.initState();
    if (widget.mode == UserFormMode.edit && widget.userData != null) {
      _loadUserData();
    }
  }

  void _loadUserData() {
    final user = widget.userData!;
    _usernameController.text = user['username'] ?? '';
    _nameController.text = user['name'] ?? '';
    _rollNoController.text = user['roll_no'] ?? '';
    _semesterController.text = user['semester']?.toString() ?? '';
    _yearController.text = user['year']?.toString() ?? '';
    _cgpaController.text = user['cgpa']?.toString() ?? '';
    _courseController.text = user['course'] ?? '';
    _sectionController.text = user['section'] ?? '';
    _selectedRole = user['role'] ?? 'student';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _rollNoController.dispose();
    _semesterController.dispose();
    _yearController.dispose();
    _cgpaController.dispose();
    _courseController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Password required for create mode
    if (widget.mode == UserFormMode.create && _passwordController.text.isEmpty) {
      _showSnackBar('Password is required', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = <String, dynamic>{
        'username': _usernameController.text.trim(),
        'role': _selectedRole,
        'name': _nameController.text.trim(),
      };

      // Add password for create or if provided for edit
      if (widget.mode == UserFormMode.create || _passwordController.text.isNotEmpty) {
        data['password'] = _passwordController.text;
      }

      // Add role-specific fields
      if (_selectedRole == 'student') {
        if (_rollNoController.text.isNotEmpty) data['roll_no'] = _rollNoController.text.trim();
        if (_semesterController.text.isNotEmpty) data['semester'] = int.tryParse(_semesterController.text);
        if (_yearController.text.isNotEmpty) data['year'] = _yearController.text.trim();
        if (_cgpaController.text.isNotEmpty) data['cgpa'] = double.tryParse(_cgpaController.text);
        if (_courseController.text.isNotEmpty) data['course'] = _courseController.text.trim();
        if (_sectionController.text.isNotEmpty) data['section'] = _sectionController.text.trim();
      }

      final result = widget.mode == UserFormMode.create
          ? await ApiService().createUser(data)
          : await ApiService().updateUser(widget.userData!['id'].toString(), data);

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (result['success'] == true) {
          _showSnackBar(
            widget.mode == UserFormMode.create
                ? 'User created successfully!'
                : 'User updated successfully!'
          );
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) Navigator.pop(context, true);
        } else {
          _showSnackBar(result['error'] ?? 'Operation failed', isError: true);
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
      height: 90.h,
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
                Text(
                  widget.mode == UserFormMode.create ? 'Create User' : 'Edit User',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
                    // Role Selection
                    AdminGlassDropdown(
                      label: 'Role',
                      value: _selectedRole,
                      items: _roles,
                      onChanged: (value) {
                        setState(() => _selectedRole = value ?? 'student');
                      },
                    ),
                    SizedBox(height: 2.h),

                    // Username
                    AdminGlassTextField(
                      controller: _usernameController,
                      label: 'Username',
                      hint: 'Enter username',
                      readOnly: widget.mode == UserFormMode.edit,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),

                    // Password
                    AdminGlassTextField(
                      controller: _passwordController,
                      label: widget.mode == UserFormMode.create
                          ? 'Password'
                          : 'Password (leave empty to keep current)',
                      hint: 'Enter password',
                      obscureText: true,
                      validator: widget.mode == UserFormMode.create
                          ? (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            }
                          : null,
                    ),
                    SizedBox(height: 2.h),

                    // Name
                    AdminGlassTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter full name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),

                    // Student-specific fields
                    if (_selectedRole == 'student') ...[
                      AdminGlassTextField(
                        controller: _rollNoController,
                        label: 'Roll Number',
                        hint: 'Enter roll number',
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Expanded(
                            child: AdminGlassTextField(
                              controller: _semesterController,
                              label: 'Semester',
                              hint: 'e.g., 6',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: AdminGlassTextField(
                              controller: _yearController,
                              label: 'Year',
                              hint: 'e.g., 3rd',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      AdminGlassTextField(
                        controller: _courseController,
                        label: 'Course',
                        hint: 'e.g., Computer Science',
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Expanded(
                            child: AdminGlassTextField(
                              controller: _sectionController,
                              label: 'Section',
                              hint: 'e.g., A',
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: AdminGlassTextField(
                              controller: _cgpaController,
                              label: 'CGPA',
                              hint: 'e.g., 8.5',
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                    ],

                    SizedBox(height: 4.h),

                    // Submit Button
                    AdminGlassButton(
                      label: widget.mode == UserFormMode.create
                          ? 'Create User'
                          : 'Update User',
                      onTap: _submitForm,
                      isLoading: _isSubmitting,
                      color: const Color(0xFF00D9FF),
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
}

