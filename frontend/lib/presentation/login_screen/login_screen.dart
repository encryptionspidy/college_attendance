import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();

    try {
      // Call real API
      final result = await ApiService().login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (result['success'] == true) {
        // Get current user to determine role
        final user = await ApiService().getCurrentUser();

        if (user != null) {
          HapticFeedback.mediumImpact();

          // Navigate based on role
          final role = user['role'];
          String route;

          switch (role) {
            case 'admin':
              route = AppRoutes.adminDashboard; // Admin dashboard
              break;
            case 'advisor':
              route = AppRoutes.advisorApprovalDashboard;
              break;
            case 'attendance_incharge':
              route = AppRoutes.attendanceMarkingScreen;
              break;
            case 'student':
              route = AppRoutes.studentDashboard;
              break;
            default:
              route = AppRoutes.studentDashboard;
          }

          if (mounted) {
            Navigator.pushReplacementNamed(context, route);
          }
        } else {
          setState(() {
            _errorMessage = 'Failed to load user data. Please try again.';
          });
        }
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = 'Invalid username or password. Please check your credentials.';
        });
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'Login failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Liquid Glass Dark Theme Colors (matching all dashboards)
    const darkBackground = Color(0xFF0A0E21);
    const glassBackground = Color(0xFF1D1E33);
    const accentColor = Color(0xFF00D9FF);
    const accentSecondary = Color(0xFF8B5CF6);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              darkBackground,
              Color(0xFF0D1219),
              glassBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // SIET Logo with stylish design (includes the cap and text)
                      _buildLogo(),

                      SizedBox(height: 2.h),

                      Text(
                        'Attendance Management System',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.5,
                        ),
                      ),

                      SizedBox(height: 4.h),

                      // Login Form Card
                      _buildLoginCard(),

                      SizedBox(height: 2.h),

                      // Error Message
                      if (_errorMessage != null) _buildErrorMessage(),

                      SizedBox(height: 2.h),

                      // Help Text
                      _buildHelpText(),

                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      height: 14.h, // Reduced from 20.h to make logo smaller
      child: _buildStylishTitle(),
    );
  }

  Widget _buildStylishTitle() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Cap icon positioned on top, slightly tilted
        Positioned(
          top: -8.h, // Adjusted for smaller size
          right: 5.w,
          child: Transform.rotate(
            angle: 0.2, // Slight tilt for design appeal
            child: Container(
              width: 14.w, // Reduced from 18.w
              height: 14.w, // Reduced from 18.w
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00D9FF).withOpacity(0.3),
                    const Color(0xFF8B5CF6).withOpacity(0.3),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D9FF).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                'assets/images/cap_logo-removebg-preview.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        // SIET text with stylish font
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              const Color(0xFF00D9FF),
              const Color(0xFF8B5CF6),
              const Color(0xFF00D9FF),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: Text(
            'SIET',
            style: GoogleFonts.audiowide(  // Modern tech look
              fontSize: 36.sp, // Reduced from 52.sp
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 8, // Reduced from 12
              height: 1.2,
              shadows: [
                Shadow(
                  color: const Color(0xFF00D9FF).withOpacity(0.6),
                  blurRadius: 20, // Reduced from 25
                  offset: const Offset(0, 4), // Reduced from (0, 5)
                ),
                Shadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.4),
                  blurRadius: 12, // Reduced from 15
                  offset: const Offset(0, 6), // Reduced from (0, 8)
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    const accentColor = Color(0xFF00D9FF);
    const accentSecondary = Color(0xFF8B5CF6);
    const glassBackground = Color(0xFF1D1E33);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: glassBackground.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 3.h),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.person, color: accentColor),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 2.h),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.lock, color: accentColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 3.h),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[300]),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red[100],
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpText() {
    return Column(
      children: [
        Text(
          'Test Credentials',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Students: 23CS001 to 23CS060 / 1234',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10.sp,
          ),
        ),
        Text(
          'Advisors: advisor1-4 / 1234',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10.sp,
          ),
        ),
        Text(
          'Attendance: attendance_i / 1234',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10.sp,
          ),
        ),
        Text(
          'Admin: admin / admin123',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }
}

