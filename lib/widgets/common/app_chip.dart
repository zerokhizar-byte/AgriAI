import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class AppChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.selected = false,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ??
        (selected
            ? AppColors.primary
            : AppColors.cardGreen);

    final textColor = foregroundColor ??
        (selected
            ? Colors.white
            : AppColors.primary);

    final outlineColor = borderColor ??
        (selected
            ? AppColors.primary
            : AppColors.border);

    final chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(
          compact
              ? AppDimensions.radius12
              : AppDimensions.radius16,
        ),
        border: Border.all(
          color: outlineColor,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: compact ? 14 : 16,
              color: textColor,
            ),
            SizedBox(
              width: compact ? 5 : 6,
            ),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return chip;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          compact
              ? AppDimensions.radius12
              : AppDimensions.radius16,
        ),
        child: chip,
      ),
    );
  }
}