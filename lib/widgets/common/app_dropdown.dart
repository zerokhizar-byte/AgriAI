import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final ValueChanged<T?>? onChanged;
  final String Function(T item)? itemLabel;
  final Widget? prefixIcon;
  final bool enabled;
  final String? Function(T?)? validator;

  const AppDropdown({
    super.key,
    required this.items,
    this.value,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.itemLabel,
    this.prefixIcon,
    this.enabled = true,
    this.validator,
  });

  String _getItemLabel(T item) {
    return itemLabel?.call(item) ?? item.toString();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 21,
        color: AppColors.textMuted,
      ),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: enabled
            ? AppColors.background
            : AppColors.border.withValues(
                alpha: 0.35,
              ),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        labelStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        hintStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
        prefixIconColor: AppColors.primary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            _getItemLabel(item),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }
}