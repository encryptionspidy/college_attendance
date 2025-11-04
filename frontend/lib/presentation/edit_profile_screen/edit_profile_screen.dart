import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import '../../services/app_state.dart';
import '../student_dashboard/widgets/glass_card.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _selectedImage;
  String? _currentImageUrl;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _rollNoController;
  late TextEditingController _semesterController;
  late TextEditingController _yearController;
  late TextEditingController _courseController;
  late TextEditingController _sectionController;
  late TextEditingController _cgpaController;
  late TextEditingController _genderController;

  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _rollNoController = TextEditingController();
    _semesterController = TextEditingController();
    _yearController = TextEditingController();
    _courseController = TextEditingController();
    _sectionController = TextEditingController();
    _cgpaController = TextEditingController();
    _genderController = TextEditingController();
  }

  Future<void> _loadUserData() async {
    final appState = context.read<AppState>();
    final userData = appState.currentUser;

    if (userData != null) {
      setState(() {
        _userRole = userData['role'] ?? 'student';
        _nameController.text = userData['name'] ?? '';
        _rollNoController.text = userData['roll_no'] ?? '';
        _semesterController.text = userData['semester']?.toString() ?? '';
        _yearController.text = userData['year']?.toString() ?? '';
        _courseController.text = userData['course'] ?? '';
        _sectionController.text = userData['section'] ?? '';
        _cgpaController.text = userData['cgpa']?.toString() ?? '';
        _genderController.text = userData['gender'] ?? '';
        _currentImageUrl = userData['profile_picture_url'];
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollNoController.dispose();
    _semesterController.dispose();
    _yearController.dispose();
    _courseController.dispose();
    _sectionController.dispose();
    _cgpaController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload profile picture if selected
      if (_selectedImage != null) {
        final uploadResult = await ApiService().uploadProfilePicture(_selectedImage!.path);
        if (!uploadResult['success']) {
          if (mounted) {
            _showSnackBar('Failed to upload profile picture: ${uploadResult['error']}', isError: true);
          }
        }
      }

      // Update profile data
      final profileData = <String, dynamic>{};
      
      if (_nameController.text.isNotEmpty) {
        profileData['name'] = _nameController.text.trim();
      }
      
      if (_userRole == 'student') {
        if (_rollNoController.text.isNotEmpty) {
          profileData['roll_no'] = _rollNoController.text.trim();
        }
        if (_semesterController.text.isNotEmpty) {
          profileData['semester'] = int.tryParse(_semesterController.text.trim());
        }
        if (_yearController.text.isNotEmpty) {
          profileData['year'] = int.tryParse(_yearController.text.trim());
        }
        if (_courseController.text.isNotEmpty) {
          profileData['course'] = _courseController.text.trim();
        }
        if (_sectionController.text.isNotEmpty) {
          profileData['section'] = _sectionController.text.trim();
        }
        if (_cgpaController.text.isNotEmpty) {
          profileData['cgpa'] = double.tryParse(_cgpaController.text.trim());
        }
      }
      
      if (_genderController.text.isNotEmpty) {
        profileData['gender'] = _genderController.text.trim();
      }

      if (profileData.isNotEmpty) {
        final result = await ApiService().updateMyProfile(profileData);
        
        if (result['success']) {
          // Refresh user data
          if (!mounted) return;
          await context.read<AppState>().loadCurrentUser();
          
          if (mounted) {
            _showSnackBar('Profile updated successfully!');
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            _showSnackBar('Failed to update profile: ${result['error']}', isError: true);
          }
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF00D9FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00D9FF);
    const backgroundColor = Color(0xFF0D0E1E);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          children: [
            // Profile Picture Section
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 30.w,
                    height: 30.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor, width: 3),
                      image: _selectedImage != null
                          ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : _currentImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(
                                    'http://localhost:8000$_currentImageUrl',
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: (_selectedImage == null && _currentImageUrl == null)
                        ? Icon(Icons.person, size: 15.w, color: Colors.white54)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: const BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.camera_alt, size: 5.w, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),

            // Name Field (All Roles)
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),

            // Gender Field (All Roles)
            _buildTextField(
              controller: _genderController,
              label: 'Gender',
              icon: Icons.wc,
            ),
            SizedBox(height: 2.h),

            // Student-specific fields
            if (_userRole == 'student') ...[
              _buildTextField(
                controller: _rollNoController,
                label: 'Roll Number',
                icon: Icons.badge,
              ),
              SizedBox(height: 2.h),
              
              _buildTextField(
                controller: _courseController,
                label: 'Course',
                icon: Icons.school,
              ),
              SizedBox(height: 2.h),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _semesterController,
                      label: 'Semester',
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: _buildTextField(
                      controller: _yearController,
                      label: 'Year',
                      icon: Icons.date_range,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _sectionController,
                      label: 'Section',
                      icon: Icons.class_,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: _buildTextField(
                      controller: _cgpaController,
                      label: 'CGPA',
                      icon: Icons.star,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],

            // Advisor-specific fields
            if (_userRole == 'advisor') ...[
              _buildTextField(
                controller: _courseController,
                label: 'Department',
                icon: Icons.business,
              ),
            ],

            SizedBox(height: 4.h),

            // Save Button
            GlassCard(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              glassColor: accentColor.withOpacity(0.3),
              onTap: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : Text(
                      'Save Changes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: const Color(0xFF00D9FF)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF00D9FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }
}
