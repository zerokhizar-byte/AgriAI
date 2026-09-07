import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';

class CropRecommendation extends StatelessWidget {
  final String recommendation;
  final String? title;
  final String? crop;
  final String? reason;
  final String? season;
  final VoidCallback? onTap;

  const CropRecommendation({
    super.key,
    required this.recommendation,
    this.title,
    this.crop,
    this.reason,
    this.season,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _RecommendationCard(
      icon: Icons.agriculture_outlined,
      title: title ?? 'Crop Recommendation',
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
          if (_hasValue(crop) ||
              _hasValue(reason) ||
              _hasValue(season)) ...[
            const SizedBox(height: 14),
            if (_hasValue(crop))
              _HighlightedCrop(
                crop: crop!,
              ),
            if (_hasValue(reason)) ...[
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.info_outline_rounded,
                label: 'Why this crop',
                value: reason!,
              ),
            ],
            if (_hasValue(season)) ...[
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.calendar_month_outlined,
                label: 'Suitable season',
                value: season!,
              ),
            ],
          ],
        ],
      ),
    );
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}

class _RecommendationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;
  final VoidCallback? onTap;

  const _RecommendationCard({
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

class _HighlightedCrop extends StatelessWidget {
  final String crop;

  const _HighlightedCrop({
    required this.crop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: 0.12,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Recommended Crop',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              crop,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}