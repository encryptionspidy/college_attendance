import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/college_logo_widget.dart';
import './widgets/error_message_widget.dart';
import './widgets/login_form_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Mock credentials for different user roles
  final Map<String, Map<String, dynamic>> _mockCredentials = {
    'admin': {
      'password': 'admin123',
      'role': 'Admin',
      'route': '/student-dashboard', // Admin can access all features
    },
    'advisor': {
      'password': 'advisor123',
      'role': 'Advisor',
      'route': '/advisor-approval-dashboard',
    },
    'attendance': {
      'password': 'attend123',
      'role': 'Attendance Incharge',
      'route': '/attendance-marking-screen',
    },
    'student': {
      'password': 'student123',
      'role': 'Student',
      'route': '/student-dashboard',
    },
    'john.doe': {
      'password': 'password123',
      'role': 'Student',
      'route': '/student-dashboard',
    },
    'jane.smith': {
      'password': 'password123',
      'role': 'Advisor',
      'route': '/advisor-approval-dashboard',
    },
  };

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

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(
      String username, String password, bool rememberMe) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Simulate authentication delay
    await Future.delayed(const Duration(milliseconds: 1500));

    // Check credentials
    final userCredentials = _mockCredentials[username.toLowerCase()];

    if (userCredentials != null && userCredentials['password'] == password) {
      // Success - provide haptic feedback
      HapticFeedback.mediumImpact();

      // Navigate to appropriate dashboard based on role
      if (mounted) {
        Navigator.pushReplacementNamed(context, userCredentials['route']);
      }
    } else {
      // Failed authentication
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage =
            'Invalid username or password. Please check your credentials and try again.';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _dismissError() {
    setState(() {
      _errorMessage = null;
    });
  }

  Future<bool> _onWillPop() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Exit App',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            content: Text(
              'Are you sure you want to exit the application?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppTheme.backgroundDark,
                      AppTheme.surfaceDark,
                      AppTheme.backgroundDark.withValues(alpha: 0.8),
                    ]
                  : [
                      AppTheme.backgroundLight,
                      AppTheme.surfaceLight,
                      AppTheme.primaryLight.withValues(alpha: 0.1),
                    ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 8.h),

                        // College Logo with Animation
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: const CollegeLogoWidget(),
                          ),
                        ),

                        SizedBox(height: 6.h),

                        // Error Message
                        if (_errorMessage != null)
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: ErrorMessageWidget(
                              message: _errorMessage!,
                              onDismiss: _dismissError,
                            ),
                          ),

                        // Login Form with Animation
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: LoginFormWidget(
                              onLogin: _handleLogin,
                              isLoading: _isLoading,
                            ),
                          ),
                        ),

                        SizedBox(height: 4.h),

                        // Demo Credentials Info
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: 90.w,
                            padding: EdgeInsets.all(4.w),
                            decoration: AppTheme.glassmorphismDecoration(
                              isLight: !isDark,
                              borderRadius: 12.0,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CustomIconWidget(
                                          iconName: 'info_outline',
                                          color: isDark
                                              ? AppTheme.secondaryDark
                                              : AppTheme.secondaryLight,
                                          size: 4.w,
                                        ),
                                        SizedBox(width: 2.w),
                                        Text(
                                          'Demo Credentials',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? AppTheme.secondaryDark
                                                    : AppTheme.secondaryLight,
                                              ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Student: student / student123\nAdvisor: advisor / advisor123\nAttendance: attendance / attend123\nAdmin: admin / admin123',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? AppTheme.textSecondaryDark
                                                : AppTheme.textSecondaryLight,
                                            height: 1.4,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 8.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
