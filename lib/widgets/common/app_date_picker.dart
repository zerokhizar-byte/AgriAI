import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class AppDatePicker {
  const AppDatePicker._();

  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
  }) async {
    final now = DateTime.now();

    final first = firstDate ?? DateTime(2000);
    final last = lastDate ?? DateTime(2100);

    var initial = initialDate ?? now;

    if (initial.isBefore(first)) {
      initial = first;
    }

    if (initial.isAfter(last)) {
      initial = last;
    }

    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: helpText,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    AppDimensions.radius22,
                  ),
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}

class AppDatePickerField extends StatelessWidget {
  final DateTime? value;
  final String hintText;
  final String? labelText;
  final ValueChanged<DateTime?>? onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final IconData icon;

  const AppDatePickerField({
    super.key,
    this.value,
    this.hintText = 'Select date',
    this.labelText,
    this.onChanged,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.icon = Icons.calendar_today_rounded,
  });

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> _pickDate(
    BuildContext context,
  ) async {
    if (!enabled) {
      return;
    }

    final selected = await AppDatePicker.show(
      context,
      initialDate: value,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selected != null) {
      onChanged?.call(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled
          ? () => _pickDate(context)
          : null,
      borderRadius: BorderRadius.circular(
        AppDimensions.radius16,
      ),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: Icon(
            icon,
            size: 21,
            color: enabled
                ? AppColors.textSecondary
                : AppColors.textMuted,
          ),
          suffixIcon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          filled: true,
          fillColor: enabled
              ? AppColors.surface
              : AppColors.background,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          labelStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          hintStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.textMuted,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppDimensions.radius16,
            ),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              AppDimensions.radius16,
            ),
            borderSide: const BorderSide(
              color: AppColors.divider,
            ),
          ),
        ),
        child: Text(
          value == null
              ? hintText
              : _formatDate(value!),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: value == null
                ? AppColors.textMuted
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}