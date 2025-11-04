import 'dart:ui';
import 'package:flutter/material.dart';

/// A glassmorphic card widget with frosted glass effect
/// 
/// Features:
/// - Configurable blur intensity
/// - Optional gradient overlay
/// - Smooth elevation with shadow
/// - Responsive to theme (light/dark)
/// - Tap interaction support
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double elevation;
  final Border? border;
  final double width;
  final double height;

  const GlassCard({
    Key? key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.15,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.gradient,
    this.onTap,
    this.elevation = 8.0,
    this.border,
    this.width = double.infinity,
    this.height = double.infinity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(16);
    
    final defaultGradient = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? Colors.white.withOpacity(opacity)
                : Colors.white.withOpacity(opacity * 1.5),
            isDark
                ? Colors.white.withOpacity(opacity * 0.5)
                : Colors.white.withOpacity(opacity * 0.8),
          ],
        );

    Widget glassContent = ClipRRect(
      borderRadius: defaultBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: defaultGradient,
            borderRadius: defaultBorderRadius,
            border: border ??
                Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
                blurRadius: elevation,
                offset: Offset(0, elevation / 2),
              ),
            ],
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: defaultBorderRadius,
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: glassContent,
        ),
      );
    }

    return glassContent;
  }
}

/// A compact glass card for smaller UI elements
class GlassCardCompact extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  
  const GlassCardCompact({
    Key? key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(12),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 8.0,
      opacity: 0.12,
      padding: padding,
      borderRadius: BorderRadius.circular(12),
      elevation: 4.0,
      onTap: onTap,
      child: child,
    );
  }
}

/// A glass card with shimmer loading effect
class GlassCardShimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const GlassCardShimmer({
    Key? key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<GlassCardShimmer> createState() => _GlassCardShimmerState();
}

class _GlassCardShimmerState extends State<GlassCardShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return GlassCard(
          width: widget.width,
          height: widget.height,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          padding: EdgeInsets.zero,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [
              _animation.value - 0.3,
              _animation.value,
              _animation.value + 0.3,
            ],
            colors: [
              isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.1),
              isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.white.withOpacity(0.3),
              isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.1),
            ],
          ),
          child: const SizedBox(),
        );
      },
    );
  }
}
