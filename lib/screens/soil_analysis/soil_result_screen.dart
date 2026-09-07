import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class SoilResultScreen extends StatelessWidget {
  final double? ph;
  final double? moisture;
  final double? nitrogen;
  final double? phosphorus;
  final double? potassium;
  final double? temperature;
  final String? soilType;
  final String? recommendation;

  const SoilResultScreen({
    super.key,
    this.ph,
    this.moisture,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.temperature,
    this.soilType,
    this.recommendation,
  });

  String _formatValue(double? value) {
    if (value == null) {
      return '--';
    }

    return value.toStringAsFixed(
      value.truncateToDouble() == value ? 0 : 1,
    );
  }

  String get _soilStatus {
    final value = ph;

    if (value == null) {
      return 'Analysis Pending';
    }

    if (value < 5.5) {
      return 'Highly Acidic';
    }

    if (value < 6.5) {
      return 'Slightly Acidic';
    }

    if (value <= 7.5) {
      return 'Optimal';
    }

    if (value <= 8.5) {
      return 'Slightly Alkaline';
    }

    return 'Highly Alkaline';
  }

  Color get _statusColor {
    final value = ph;

    if (value == null) {
      return AppColors.textSecondary;
    }

    if (value >= 6.5 && value <= 7.5) {
      return AppColors.primary;
    }

    return const Color(0xFFE28A28);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Soil Analysis'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusCard(
                status: _soilStatus,
                color: _statusColor,
                soilType: soilType,
              ),
              const SizedBox(height: 18),
              const Text(
                'Soil Parameters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _ParameterGrid(
                parameters: [
                  _ParameterData(
                    label: 'pH',
                    value: _formatValue(ph),
                    unit: '',
                    icon: Icons.science_outlined,
                  ),
                  _ParameterData(
                    label: 'Moisture',
                    value: _formatValue(moisture),
                    unit: '%',
                    icon: Icons.water_drop_outlined,
                  ),
                  _ParameterData(
                    label: 'Nitrogen',
                    value: _formatValue(nitrogen),
                    unit: 'mg/kg',
                    icon: Icons.eco_outlined,
                  ),
                  _ParameterData(
                    label: 'Phosphorus',
                    value: _formatValue(phosphorus),
                    unit: 'mg/kg',
                    icon: Icons.grass_outlined,
                  ),
                  _ParameterData(
                    label: 'Potassium',
                    value: _formatValue(potassium),
                    unit: 'mg/kg',
                    icon: Icons.spa_outlined,
                  ),
                  _ParameterData(
                    label: 'Temperature',
                    value: _formatValue(temperature),
                    unit: '°C',
                    icon: Icons.thermostat_outlined,
                  ),
                ],
              ),
              if (recommendation != null &&
                  recommendation!.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                _RecommendationCard(
                  text: recommendation!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String status;
  final Color color;
  final String? soilType;

  const _StatusCard({
    required this.status,
    required this.color,
    this.soilType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius22,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_outlined,
              color: color,
              size: 29,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Soil Status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                if (soilType != null &&
                    soilType!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    soilType!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParameterGrid extends StatelessWidget {
  final List<_ParameterData> parameters;

  const _ParameterGrid({
    required this.parameters,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: parameters.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final parameter = parameters[index];

        return _ParameterCard(
          parameter: parameter,
        );
      },
    );
  }
}

class _ParameterCard extends StatelessWidget {
  final _ParameterData parameter;

  const _ParameterCard({
    required this.parameter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius18,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(
              alpha: 0.06,
            ),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                parameter.icon,
                size: 19,
                color: AppColors.primary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  parameter.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  parameter.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (parameter.unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 2,
                  ),
                  child: Text(
                    parameter.unit,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final String text;

  const _RecommendationCard({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius18,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cardGreen,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommendation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParameterData {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _ParameterData({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });
}