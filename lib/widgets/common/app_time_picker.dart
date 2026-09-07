import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class AppTimePicker {
  const AppTimePicker._();

  static Future<TimeOfDay?> show(
    BuildContext context, {
    TimeOfDay? initialTime,
    String? helpText,
  }) {
    return showTimePicker(
      context: context,
      initialTime:
          initialTime ?? TimeOfDay.now(),
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
            timePickerTheme:
                const TimePickerThemeData(
              backgroundColor: AppColors.surface,
              hourMinuteColor:
                  AppColors.cardGreen,
              hourMinuteTextColor:
                  AppColors.primary,
              dialBackgroundColor:
                  AppColors.background,
              dialHandColor:
                  AppColors.primary,
              dialTextColor:
                  AppColors.textPrimary,
              entryModeIconColor:
                  AppColors.primary,
              dayPeriodColor:
                  AppColors.cardGreen,
              dayPeriodTextColor:
                  AppColors.primary,
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

class AppTimePickerField extends StatelessWidget {
  final TimeOfDay? value;
  final String hintText;
  final String? labelText;
  final ValueChanged<TimeOfDay?>? onChanged;
  final bool enabled;
  final IconData icon;

  const AppTimePickerField({
    super.key,
    this.value,
    this.hintText = 'Select time',
    this.labelText,
    this.onChanged,
    this.enabled = true,
    this.icon = Icons.access_time_rounded,
  });

  Future<void> _pickTime(
    BuildContext context,
  ) async {
    if (!enabled) {
      return;
    }

    final selected = await AppTimePicker.show(
      context,
      initialTime: value,
    );

    if (selected != null) {
      onChanged?.call(selected);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0
        ? 12
        : time.hourOfPeriod;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final displayText = value == null
        ? hintText
        : _formatTime(value!);

    return InkWell(
      onTap: enabled
          ? () => _pickTime(context)
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
          displayText,
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