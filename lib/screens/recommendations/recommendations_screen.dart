import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import 'widgets/crop_recommendation.dart';
import 'widgets/fertilizer_recommendation.dart';
import 'widgets/irrigation_recommendation.dart';

class RecommendationsScreen extends StatelessWidget {
  final String? irrigationRecommendation;
  final String? fertilizerRecommendation;
  final String? cropRecommendation;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const RecommendationsScreen({
    super.key,
    this.irrigationRecommendation,
    this.fertilizerRecommendation,
    this.cropRecommendation,
    this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Smart Recommendations'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (onRefresh != null)
            IconButton(
              onPressed: isLoading ? null : onRefresh,
              tooltip: 'Refresh',
              icon: const Icon(
                Icons.refresh_rounded,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            if (onRefresh != null && !isLoading) {
              onRefresh!();
            }
          },
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              30,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const _RecommendationsHeader(),
                const SizedBox(height: 20),
                if (isLoading)
                  const _LoadingCard()
                else ...[
                  if (irrigationRecommendation != null)
                    IrrigationRecommendation(
                      recommendation:
                          irrigationRecommendation!,
                    ),
                  if (irrigationRecommendation != null)
                    const SizedBox(height: 12),
                  if (fertilizerRecommendation != null)
                    FertilizerRecommendation(
                      recommendation:
                          fertilizerRecommendation!,
                    ),
                  if (fertilizerRecommendation != null)
                    const SizedBox(height: 12),
                  if (cropRecommendation != null)
                    CropRecommendation(
                      recommendation:
                          cropRecommendation!,
                    ),
                  if (_hasNoRecommendations)
                    const _EmptyCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasNoRecommendations {
    return (irrigationRecommendation == null ||
            irrigationRecommendation!.trim().isEmpty) &&
        (fertilizerRecommendation == null ||
            fertilizerRecommendation!.trim().isEmpty) &&
        (cropRecommendation == null ||
            cropRecommendation!.trim().isEmpty);
  }
}

class _RecommendationsHeader extends StatelessWidget {
  const _RecommendationsHeader();

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
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius:
                  BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-Powered Guidance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Practical recommendations based on your farm conditions.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius18,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Generating recommendations...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius18,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 42,
            color: AppColors.primary,
          ),
          SizedBox(height: 12),
          Text(
            'No recommendations available',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Complete your farm and crop information to receive personalized recommendations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}