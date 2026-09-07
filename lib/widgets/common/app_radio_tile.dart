import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class AppRadioTile<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final String title;
  final String? subtitle;
  final ValueChanged<T?>? onChanged;
  final Widget? leading;
  final bool enabled;

  const AppRadioTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.title,
    this.subtitle,
    this.onChanged,
    this.leading,
    this.enabled = true,
  });

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = enabled
        ? AppColors.textPrimary
        : AppColors.textMuted;

    final secondaryColor = enabled
        ? AppColors.textSecondary
        : AppColors.textMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: _selected
            ? AppColors.cardGreen
            : AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius16,
        ),
        border: Border.all(
          color: _selected
              ? AppColors.primary
              : AppColors.border,
          width: _selected ? 1.2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled
              ? () => onChanged?.call(value)
              : null,
          borderRadius: BorderRadius.circular(
            AppDimensions.radius16,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: foregroundColor,
                        ),
                      ),
                      if (subtitle != null &&
                          subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _CustomRadio(
                  selected: _selected,
                  enabled: enabled,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomRadio extends StatelessWidget {
  final bool selected;
  final bool enabled;

  const _CustomRadio({
    required this.selected,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = enabled
        ? AppColors.primary
        : AppColors.textMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? activeColor
              : AppColors.textMuted,
          width: selected ? 2 : 1.5,
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 10 : 0,
          height: selected ? 10 : 0,
          decoration: BoxDecoration(
            color: activeColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}