import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppProgressIndicator extends StatelessWidget {
  final double value;
  final double height;
  final Color? backgroundColor;
  final Color? valueColor;
  final BorderRadiusGeometry? borderRadius;
  final bool showPercentage;
  final String? label;

  const AppProgressIndicator({
    super.key,
    required this.value,
    this.height = 8,
    this.backgroundColor,
    this.valueColor,
    this.borderRadius,
    this.showPercentage = false,
    this.label,
  });

  double get _safeValue {
    if (value.isNaN || value.isInfinite) {
      return 0;
    }

    return value.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _safeValue;

    final hasLabel =
        label != null && label!.trim().isNotEmpty;

    if (!hasLabel && !showPercentage) {
      return ClipRRect(
        borderRadius: borderRadius ??
            BorderRadius.circular(height / 2),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: height,
          backgroundColor:
              backgroundColor ?? AppColors.cardGreen,
          valueColor: AlwaysStoppedAnimation<Color>(
            valueColor ?? AppColors.primary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (hasLabel)
              Expanded(
                child: Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            if (showPercentage)
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
          ],
        ),
        if (hasLabel || showPercentage)
          const SizedBox(height: 7),
        ClipRRect(
          borderRadius: borderRadius ??
              BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: height,
            backgroundColor:
                backgroundColor ?? AppColors.cardGreen,
            valueColor: AlwaysStoppedAnimation<Color>(
              valueColor ?? AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class AppCircularProgressIndicator extends StatelessWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? valueColor;
  final bool showPercentage;

  const AppCircularProgressIndicator({
    super.key,
    required this.value,
    this.size = 64,
    this.strokeWidth = 6,
    this.backgroundColor,
    this.valueColor,
    this.showPercentage = false,
  });

  double get _safeValue {
    if (value.isNaN || value.isInfinite) {
      return 0;
    }

    return value.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _safeValue;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              backgroundColor:
                  backgroundColor ?? AppColors.cardGreen,
              valueColor: AlwaysStoppedAnimation<Color>(
                valueColor ?? AppColors.primary,
              ),
            ),
          ),
          if (showPercentage)
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}