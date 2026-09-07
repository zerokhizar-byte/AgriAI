import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? message;

  const LoadingIndicator({
    super.key,
    this.size = 28,
    this.strokeWidth = 2.8,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorColor =
        color ?? AppColors.primary;

    if (message == null ||
        message!.trim().isEmpty) {
      return Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            color: indicatorColor,
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              color: indicatorColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}