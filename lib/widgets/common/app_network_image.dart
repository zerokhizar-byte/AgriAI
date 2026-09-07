import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadiusGeometry borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(16),
    ),
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl =
        url != null && url!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: width,
        height: height,
        color: backgroundColor ??
            AppColors.cardGreen,
        child: hasUrl
            ? Image.network(
                url!,
                width: width,
                height: height,
                fit: fit,
                filterQuality: FilterQuality.medium,
                loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                ) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return placeholder ??
                      const _ImagePlaceholder();
                },
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return errorWidget ??
                      const _ImageError();
                },
              )
            : errorWidget ?? const _ImageError(),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor:
              AlwaysStoppedAnimation<Color>(
            AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 32,
        color: AppColors.textMuted,
      ),
    );
  }
}