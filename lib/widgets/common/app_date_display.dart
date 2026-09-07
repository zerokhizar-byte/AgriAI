import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppDateDisplay extends StatelessWidget {
  final DateTime date;
  final bool showTime;
  final bool showIcon;
  final String? prefix;
  final TextStyle? style;
  final Color? iconColor;

  const AppDateDisplay({
    super.key,
    required this.date,
    this.showTime = false,
    this.showIcon = false,
    this.prefix,
    this.style,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = _formatDate(date);
    final timeText = _formatTime(date);

    final text = showTime
        ? '$dateText • $timeText'
        : dateText;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            Icons.calendar_today_rounded,
            size: 14,
            color: iconColor ?? AppColors.textMuted,
          ),
          const SizedBox(width: 6),
        ],
        if (prefix != null &&
            prefix!.trim().isNotEmpty) ...[
          Text(
            prefix!,
            style: style ??
                const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: style ??
              const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();

    return '$day/$month/$year';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
            ? value.hour - 12
            : value.hour;

    final minute =
        value.minute.toString().padLeft(2, '0');

    final period = value.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}

class AppRelativeDate extends StatelessWidget {
  final DateTime date;
  final TextStyle? style;
  final bool showIcon;

  const AppRelativeDate({
    super.key,
    required this.date,
    this.style,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = _relativeDate(date);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          const Icon(
            Icons.schedule_rounded,
            size: 14,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 5),
        ],
        Text(
          text,
          style: style ??
              const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
        ),
      ],
    );
  }

  String _relativeDate(DateTime value) {
    final now = DateTime.now();
    final difference = now.difference(value);

    if (difference.isNegative) {
      return 'Just now';
    }

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return AppDateDisplay(
      date: value,
    )._formatDate(value);
  }
}