import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';

class FertilizerRecommendation extends StatelessWidget {
  final String recommendation;
  final String? title;
  final String? fertilizer;
  final String? dosage;
  final String? frequency;
  final VoidCallback? onTap;

  const FertilizerRecommendation({
    super.key,
    required this.recommendation,
    this.title,
    this.fertilizer,
    this.dosage,
    this.frequency,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _RecommendationContainer(
      icon: Icons.eco_outlined,
      title: title ?? 'Fertilizer Recommendation',
      color: AppColors.primary,
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
          if (_hasValue(fertilizer) ||
              _hasValue(dosage) ||
              _hasValue(frequency)) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (_hasValue(fertilizer))
                  _InfoItem(
                    icon: Icons.grass_outlined,
                    label: 'Fertilizer',
                    value: fertilizer!,
                  ),
                if (_hasValue(dosage))
                  _InfoItem(
                    icon: Icons.scale_outlined,
                    label: 'Dosage',
                    value: dosage!,
                  ),
                if (_hasValue(frequency))
                  _InfoItem(
                    icon: Icons.schedule_outlined,
                    label: 'Frequency',
                    value: frequency!,
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
      constraints: const BoxConstraints(
        minWidth: 120,
        maxWidth: 220,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: AppColors.primary,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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