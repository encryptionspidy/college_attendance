import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../student_dashboard/widgets/glass_card.dart';

/// Role-Specific Edit Profile Screen
/// Shows appropriate fields based on user role
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const EditProfileScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  // Controllers for common fields
  late TextEditingController _nameController;
  late TextEditingController _profilePictureController;

  // Controllers for student-specific fields
  late TextEditingController _rollNoController;
  late TextEditingController _semesterController;
  late TextEditingController _yearController;
  late TextEditingController _cgpaController;
  late TextEditingController _courseController;
  late TextEditingController _sectionController;
  late TextEditingController _departmentController;
  DateTime? _selectedDob;
  String? _selectedGender;

  // Controllers for advisor/faculty fields
  late TextEditingController _employeeIdController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(EditProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinitialize controllers if the user changed
    if (oldWidget.currentUser['id'] != widget.currentUser['id']) {
      _disposeControllers();
      _initializeControllers();
    }
  }

    _yearController = TextEditingController(text: user['year']?.toString() ?? '');
    _cgpaController = TextEditingController(text: user['cgpa']?.toString() ?? '');
    _courseController = TextEditingController(text: user['course'] ?? '');
    _sectionController = TextEditingController(text: user['section'] ?? '');
    _departmentController = TextEditingController(text: user['department'] ?? '');
    _selectedGender = user['gender'];
    if (user['dob'] != null) {
      try {
        _selectedDob = DateTime.parse(user['dob']);
      } catch (e) {
        // Invalid date format
      }
    }

    // Advisor/Faculty fields
    _employeeIdController = TextEditingController(text: user['employee_id'] ?? '');
    _selectedDob = null;

  @override
  void dispose() {
    _nameController.dispose();
    _profilePictureController.dispose();
    _rollNoController.dispose();
    _semesterController.dispose();
    _yearController.dispose();
    _cgpaController.dispose();
    _courseController.dispose();
    _sectionController.dispose();
    _departmentController.dispose();
  void _disposeControllers() {
    super.dispose();
  }

  String get _userRole => widget.currentUser['role'] ?? 'student';

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

  }

  @override
  void dispose() {
    _disposeControllers();
    try {
      Map<String, dynamic> updateData = {
        'name': _nameController.text,
        'profile_picture_url': _profilePictureController.text,
      };

      // Add role-specific fields
      if (_userRole == 'student') {
        updateData.addAll({
          'roll_no': _rollNoController.text,
          'semester': int.tryParse(_semesterController.text),
          'year': int.tryParse(_yearController.text),
          'cgpa': double.tryParse(_cgpaController.text),
          'course': _courseController.text,
          'section': _sectionController.text,
          'department': _departmentController.text,
          'gender': _selectedGender,
          'dob': _selectedDob?.toIso8601String().split('T')[0],
        });
      } else if (_userRole == 'advisor' || _userRole == 'faculty') {
        updateData.addAll({
          'department': _departmentController.text,
          'employee_id': _employeeIdController.text,
        });
      }

      await _apiService.updateMyProfile(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2005, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    GlassCard(
                      child: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                  ],

                  // Common Fields
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 2.h),

                  // Role-specific fields
                  if (_userRole == 'student') ..._buildStudentFields(),
                  if (_userRole == 'advisor' || _userRole == 'faculty') ..._buildAdvisorFields(),

                  SizedBox(height: 3.h),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStudentFields() {
    return [
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
              icon: Icons.event,
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
              icon: Icons.grade,
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
      SizedBox(height: 2.h),
      GlassCard(
        child: InkWell(
          onTap: _selectDate,
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Icon(Icons.cake, color: Colors.white.withOpacity(0.7), size: 6.w),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    _selectedDob == null
                        ? 'Select Date of Birth'
                        : DateFormat('MMM dd, yyyy').format(_selectedDob!),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
      SizedBox(height: 2.h),
      GlassCard(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
          child: DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: InputDecoration(
              labelText: 'Gender',
              prefixIcon: Icon(Icons.wc, color: Colors.white.withOpacity(0.7)),
              border: InputBorder.none,
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            dropdownColor: const Color(0xFF1A1A2E),
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
            items: ['Male', 'Female', 'Other']
                .map((gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildAdvisorFields() {
    return [
      _buildTextField(
        controller: _departmentController,
        label: 'Department',
        icon: Icons.business,
      ),
      SizedBox(height: 2.h),
      _buildTextField(
        controller: _employeeIdController,
        label: 'Employee ID',
        icon: Icons.badge,
      ),
    ];
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return GlassCard(
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(4.w),
        ),
      ),
    );
  }
}

