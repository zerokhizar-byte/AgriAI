import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';

class IrrigationRecommendation extends StatelessWidget {
  final String recommendation;
  final String? title;
  final String? waterAmount;
  final String? timing;
  final VoidCallback? onTap;

  const IrrigationRecommendation({
    super.key,
    required this.recommendation,
    this.title,
    this.waterAmount,
    this.timing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _RecommendationContainer(
      icon: Icons.water_drop_outlined,
      title: title ?? 'Irrigation Recommendation',
      color: const Color(0xFF2E7D8A),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recommendation,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          if (_hasValue(waterAmount) ||
              _hasValue(timing)) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (_hasValue(waterAmount))
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.water_outlined,
                      label: 'Water',
                      value: waterAmount!,
                    ),
                  ),
                if (_hasValue(waterAmount) &&
                    _hasValue(timing))
                  const SizedBox(width: 10),
                if (_hasValue(timing))
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.schedule_outlined,
                      label: 'Timing',
                      value: timing!,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}

class _RecommendationContainer extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;
  final VoidCallback? onTap;

  const _RecommendationContainer({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
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
            blurRadius: 13,
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: color,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 21,
                  color: AppColors.textMuted,
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius18,
        ),
        child: content,
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: AppColors.primary,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
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