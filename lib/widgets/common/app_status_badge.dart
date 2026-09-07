import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

enum AppStatusType {
  success,
  warning,
  danger,
  info,
  neutral,
}

class AppStatusBadge extends StatelessWidget {
  final String text;
  final AppStatusType type;
  final IconData? icon;
  final bool compact;

  const AppStatusBadge({
    super.key,
    required this.text,
    this.type = AppStatusType.success,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusData;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(
          compact
              ? 10
              : AppDimensions.radius12,
        ),
        border: Border.all(
          color: status.borderColor,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: compact ? 13 : 15,
              color: status.foregroundColor,
            )
          else
            Container(
              width: compact ? 5 : 6,
              height: compact ? 5 : 6,
              decoration: BoxDecoration(
                color: status.foregroundColor,
                shape: BoxShape.circle,
              ),
            ),
          SizedBox(
            width: compact ? 5 : 6,
          ),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
              color: status.foregroundColor,
            ),
          ),
        ],
      ),
    );
  }

  _StatusData get _statusData {
    switch (type) {
      case AppStatusType.success:
        return _StatusData(
          foregroundColor: AppColors.primary,
          backgroundColor: const Color(0xFFEAF7EC),
          borderColor: const Color(0xFFCFE8D2),
        );

      case AppStatusType.warning:
        return _StatusData(
          foregroundColor: const Color(0xFFB7791F),
          backgroundColor: const Color(0xFFFFF7E8),
          borderColor: const Color(0xFFF4DFB2),
        );

      case AppStatusType.danger:
        return _StatusData(
          foregroundColor: const Color(0xFFD64545),
          backgroundColor: const Color(0xFFFFEEEE),
          borderColor: const Color(0xFFF1CCCC),
        );

      case AppStatusType.info:
        return _StatusData(
          foregroundColor: const Color(0xFF2878B5),
          backgroundColor: const Color(0xFFEDF6FF),
          borderColor: const Color(0xFFD1E6F7),
        );

      case AppStatusType.neutral:
        return _StatusData(
          foregroundColor: AppColors.textSecondary,
          backgroundColor: const Color(0xFFF2F5F3),
          borderColor: AppColors.border,
        );
    }
  }
}

class _StatusData {
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;

  const _StatusData({
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
  });
}