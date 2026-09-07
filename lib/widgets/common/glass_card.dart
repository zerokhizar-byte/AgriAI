import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double opacity;
  final double borderOpacity;
  final double borderRadius;
  final Color? color;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.blur = 12,
    this.opacity = 0.72,
    this.borderOpacity = 0.55,
    this.borderRadius = 20,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      borderRadius,
    );

    final backgroundColor =
        color ?? AppColors.surface;

    final card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
        ),
        child: Container(
          width: double.infinity,
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor.withValues(
              alpha: opacity,
            ),
            borderRadius: radius,
            border: Border.all(
              color: AppColors.border.withValues(
                alpha: borderOpacity,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(
                  alpha: 0.05,
                ),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: card,
      ),
    );
  }
}