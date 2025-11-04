import 'package:flutter/material.dart';
import 'dart:ui';

/// A glass-morphism style circular progress indicator
class GlassProgressIndicator extends StatelessWidget {
  final double value;
  final Color color;
  final double size;

  const GlassProgressIndicator({
    super.key,
    required this.value,
    this.color = Colors.blue,
    this.size = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Center(
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 4,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ),
    );
  }
}

