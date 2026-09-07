import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String? title;
  final String? subtitle;

  const AppLogo({
    super.key,
    this.size = 72,
    this.showText = false,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (!showText) {
      return _LogoMark(size: size);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LogoMark(size: size),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title ?? 'AgriAI',
              style: TextStyle(
                fontSize: size * 0.32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null &&
                subtitle!.trim().isNotEmpty)
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: size * 0.14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  final double size;

  const _LogoMark({
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(size * 0.25),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: 0.10,
            ),
            blurRadius: size * 0.22,
            offset: Offset(
              0,
              size * 0.08,
            ),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.eco_rounded,
          size: size * 0.48,
          color: Colors.white,
        ),
      ),
    );
  }
}