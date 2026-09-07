import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const GradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = colors ??
        [
          AppColors.background,
          AppColors.cardGreen,
        ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: begin,
          end: end,
        ),
        borderRadius: borderRadius,
      ),
      padding: padding,
      child: child,
    );
  }
}
