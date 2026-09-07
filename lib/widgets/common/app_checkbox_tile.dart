import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class AppCheckboxTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? leading;
  final bool enabled;

  const AppCheckboxTile({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.onChanged,
    this.leading,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = enabled
        ? AppColors.textPrimary
        : AppColors.textMuted;

    final subtitleColor = enabled
        ? AppColors.textSecondary
        : AppColors.textMuted;

    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 180,
      ),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: value
            ? AppColors.cardGreen
            : AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius16,
        ),
        border: Border.all(
          color: value
              ? AppColors.primary
              : AppColors.border,
          width: value ? 1.2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled
              ? () => onChanged?.call(!value)
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
                          color: titleColor,
                        ),
                      ),
                      if (subtitle != null &&
                          subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _CustomCheckbox(
                  selected: value,
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

class _CustomCheckbox extends StatelessWidget {
  final bool selected;
  final bool enabled;

  const _CustomCheckbox({
    required this.selected,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = enabled
        ? AppColors.primary
        : AppColors.textMuted;

    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 180,
      ),
      curve: Curves.easeOutCubic,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected
            ? activeColor
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected
              ? activeColor
              : AppColors.textMuted,
          width: selected ? 1.5 : 1.4,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(
          milliseconds: 150,
        ),
        child: selected
            ? const Icon(
                Icons.check_rounded,
                key: ValueKey('checked'),
                size: 16,
                color: Colors.white,
              )
            : const SizedBox(
                key: ValueKey('unchecked'),
              ),
      ),
    );
  }
}