import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppHeroImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadiusGeometry borderRadius;
  final bool showShadow;
  final Widget? fallback;
  final Alignment alignment;

  const AppHeroImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(24),
    ),
    this.showShadow = true,
    this.fallback,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return fallback ?? const _HeroImageFallback();
        },
      ),
    );

    if (!showShadow) {
      return image;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(
              alpha: 0.12,
            ),
            blurRadius: 20,
            offset: const Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: image,
    );
  }
}

class _HeroImageFallback extends StatelessWidget {
  const _HeroImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.cardGreen,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 42,
        color: AppColors.primary,
      ),
    );
  }
}