import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class AppIconContainer extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final double size;
  final double iconSize;
  final VoidCallback? onTap;

  const AppIconContainer({
    super.key,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.backgroundColor = AppColors.cardGreen,
    this.size = AppDimensions.iconButtonSize,
    this.iconSize = 21.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius14,
        ),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor,
      ),
    );

    if (onTap == null) {
      return container;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius14,
        ),
        child: container,
      ),
    );
  }
}