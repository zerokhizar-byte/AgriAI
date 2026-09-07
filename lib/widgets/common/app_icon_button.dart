import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? borderColor;
  final bool showBorder;
  final bool filled;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 44,
    this.iconSize = 21,
    this.backgroundColor,
    this.iconColor,
    this.borderColor,
    this.showBorder = false,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final background = backgroundColor ??
        (filled
            ? AppColors.cardGreen
            : Colors.transparent);

    final foreground =
        iconColor ?? AppColors.primary;

    final button = Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: showBorder
            ? BorderSide(
                color: borderColor ?? AppColors.border,
                width: 1,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: iconSize,
            color: onPressed == null
                ? foreground.withValues(alpha: 0.45)
                : foreground,
          ),
        ),
      ),
    );

    if (tooltip == null ||
        tooltip!.trim().isEmpty) {
      return button;
    }

    return Tooltip(
      message: tooltip!,
      child: button,
    );
  }
}