import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? imagePath;
  final String? name;
  final IconData fallbackIcon;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool showBorder;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.imagePath,
    this.name,
    this.fallbackIcon = Icons.person_rounded,
    this.size = 48,
    this.backgroundColor,
    this.iconColor,
    this.onTap,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardGreen,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: AppColors.surface,
                width: 2,
              )
            : null,
      ),
      child: ClipOval(
        child: _buildContent(),
      ),
    );

    if (onTap == null) {
      return avatar;
    }

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      ),
    );
  }

  Widget _buildContent() {
    final hasImageUrl =
        imageUrl != null &&
        imageUrl!.trim().isNotEmpty;

    final hasImagePath =
        imagePath != null &&
        imagePath!.trim().isNotEmpty;

    if (hasImageUrl) {
      return Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return _fallback();
        },
      );
    }

    if (hasImagePath) {
      return Image.asset(
        imagePath!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return _fallback();
        },
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    final initials = _getInitials();

    if (initials.isNotEmpty) {
      return Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.32,
            fontWeight: FontWeight.w800,
            color: iconColor ?? AppColors.primary,
          ),
        ),
      );
    }

    return Icon(
      fallbackIcon,
      size: size * 0.48,
      color: iconColor ?? AppColors.primary,
    );
  }

  String _getInitials() {
    if (name == null || name!.trim().isEmpty) {
      return '';
    }

    final parts = name!
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '';
    }

    if (parts.length == 1) {
      final value = parts.first;

      return value.length >= 2
          ? value.substring(0, 2).toUpperCase()
          : value.toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }
}