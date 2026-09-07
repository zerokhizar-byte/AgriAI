import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppLoading extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? message;

  const AppLoading({
    super.key,
    this.size = 32.0,
    this.strokeWidth = 3.0,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final loadingColor = color ?? AppColors.primary;

    if (message == null || message!.trim().isEmpty) {
      return Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(
              loadingColor,
            ),
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
              valueColor: AlwaysStoppedAnimation<Color>(
                loadingColor,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class AppLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;

  const AppLoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            color: Colors.white.withValues(
              alpha: 0.72,
            ),
            child: AppLoading(
              message: message,
            ),
          ),
        ),
      ],
    );
  }
}