import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class SoilInputForm extends StatelessWidget {
  final TextEditingController phController;
  final TextEditingController moistureController;
  final TextEditingController nitrogenController;
  final TextEditingController phosphorusController;
  final TextEditingController potassiumController;
  final TextEditingController temperatureController;
  final VoidCallback? onAnalyze;
  final bool isLoading;

  const SoilInputForm({
    super.key,
    required this.phController,
    required this.moistureController,
    required this.nitrogenController,
    required this.phosphorusController,
    required this.potassiumController,
    required this.temperatureController,
    this.onAnalyze,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Soil Parameters',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your soil conditions to get an AI-based soil analysis.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        _SoilInputField(
          controller: phController,
          label: 'Soil pH',
          hint: 'e.g. 6.5',
          suffix: 'pH',
          icon: Icons.science_outlined,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
        ),
        const SizedBox(height: 12),
        _SoilInputField(
          controller: moistureController,
          label: 'Soil Moisture',
          hint: 'e.g. 45',
          suffix: '%',
          icon: Icons.water_drop_outlined,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
        ),
        const SizedBox(height: 12),
        _SoilInputField(
          controller: nitrogenController,
          label: 'Nitrogen',
          hint: 'e.g. 40',
          suffix: 'mg/kg',
          icon: Icons.eco_outlined,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
        ),
        const SizedBox(height: 12),
        _SoilInputField(
          controller: phosphorusController,
          label: 'Phosphorus',
          hint: 'e.g. 30',
          suffix: 'mg/kg',
          icon: Icons.grass_outlined,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
        ),
        const SizedBox(height: 12),
        _SoilInputField(
          controller: potassiumController,
          label: 'Potassium',
          hint: 'e.g. 35',
          suffix: 'mg/kg',
          icon: Icons.spa_outlined,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
        ),
        const SizedBox(height: 12),
        _SoilInputField(
          controller: temperatureController,
          label: 'Soil Temperature',
          hint: 'e.g. 28',
          suffix: '°C',
          icon: Icons.thermostat_outlined,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeight,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onAnalyze,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.analytics_outlined,
                    size: 20,
                  ),
            label: Text(
              isLoading
                  ? 'Analyzing Soil...'
                  : 'Analyze Soil',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.55),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.radius16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SoilInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String suffix;
  final IconData icon;
  final TextInputType keyboardType;

  const _SoilInputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.suffix,
    required this.icon,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: AppColors.primary,
          size: 21,
        ),
        suffixText: suffix,
        suffixStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        hintStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.textMuted,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radius16,
          ),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radius16,
          ),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radius16,
          ),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}