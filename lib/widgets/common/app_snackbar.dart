import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AppSnackBarType {
  success,
  error,
  warning,
  info,
}

class AppSnackBar {
  const AppSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarType type = AppSnackBarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(
      seconds: 3,
    ),
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: _SnackBarContent(
            message: message,
            type: type,
          ),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          backgroundColor: AppColors.surface,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: AppColors.border,
              width: 0.8,
            ),
          ),
          action: actionLabel == null
              ? null
              : SnackBarAction(
                  label: actionLabel,
                  onPressed: onAction ?? () {},
                  textColor: AppColors.primary,
                ),
        ),
      );
  }

  static void success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: AppSnackBarType.success,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: AppSnackBarType.error,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: AppSnackBarType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: AppSnackBarType.info,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class _SnackBarContent extends StatelessWidget {
  final String message;
  final AppSnackBarType type;

  const _SnackBarContent({
    required this.message,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: data.backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            data.icon,
            size: 19,
            color: data.foregroundColor,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  _SnackBarData get _data {
    switch (type) {
      case AppSnackBarType.success:
        return const _SnackBarData(
          icon: Icons.check_circle_rounded,
          foregroundColor: AppColors.primary,
          backgroundColor: Color(0xFFEAF7EC),
        );

      case AppSnackBarType.error:
        return const _SnackBarData(
          icon: Icons.error_rounded,
          foregroundColor: Color(0xFFD64545),
          backgroundColor: Color(0xFFFFEEEE),
        );

      case AppSnackBarType.warning:
        return const _SnackBarData(
          icon: Icons.warning_rounded,
          foregroundColor: Color(0xFFB7791F),
          backgroundColor: Color(0xFFFFF7E8),
        );

      case AppSnackBarType.info:
        return const _SnackBarData(
          icon: Icons.info_rounded,
          foregroundColor: Color(0xFF2878B5),
          backgroundColor: Color(0xFFEDF6FF),
        );
    }
  }
}

class _SnackBarData {
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;

  const _SnackBarData({
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
  });
}