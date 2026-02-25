import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.15,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard.withValues(alpha: opacity),
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              border: border ??
                  Border.all(
                    color: AppColors.darkBorder.withValues(alpha: 0.3),
                    width: 1,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
