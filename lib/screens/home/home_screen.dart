import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class HomeScreen extends StatelessWidget {
  final String? farmerName;
  final VoidCallback? onYieldPrediction;
  final VoidCallback? onDiseaseDetection;
  final VoidCallback? onSoilAnalysis;
  final VoidCallback? onWeather;
  final VoidCallback? onRecommendations;
  final VoidCallback? onProfile;

  const HomeScreen({
    super.key,
    this.farmerName,
    this.onYieldPrediction,
    this.onDiseaseDetection,
    this.onSoilAnalysis,
    this.onWeather,
    this.onRecommendations,
    this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        farmerName?.trim().isNotEmpty == true
            ? farmerName!.trim()
            : 'Farmer';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await Future<void>.delayed(
              const Duration(milliseconds: 500),
            );
          },
          child: CustomScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  28,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HomeHeader(
                      farmerName: name,
                      onProfile: onProfile,
                    ),
                    const SizedBox(height: 18),
                    _WelcomeCard(
                      farmerName: name,
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle(
                      title: 'Today at a Glance',
                    ),
                    const SizedBox(height: 10),
                    const _WeatherCard(),
                    const SizedBox(height: 12),
                    const _FarmStatusCard(),
                    const SizedBox(height: 20),
                    const _SectionTitle(
                      title: 'Quick Actions',
                    ),
                    const SizedBox(height: 10),
                    _QuickActionsGrid(
                      onYieldPrediction:
                          onYieldPrediction,
                      onDiseaseDetection:
                          onDiseaseDetection,
                      onSoilAnalysis:
                          onSoilAnalysis,
                      onWeather: onWeather,
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle(
                      title: 'Smart Recommendation',
                    ),
                    const SizedBox(height: 10),
                    _RecommendationCard(
                      onTap: onRecommendations,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String farmerName;
  final VoidCallback? onProfile;

  const _HomeHeader({
    required this.farmerName,
    this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Good day,',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                farmerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onProfile,
            borderRadius:
                BorderRadius.circular(50),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.cardGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
                size: 23,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String farmerName;

  const _WelcomeCard({
    required this.farmerName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius22,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: 0.16,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your farm, smarter.',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use AI-powered insights to make better decisions for your crops.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(
                      alpha: 0.88,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.14,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
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
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.cardGreen,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.wb_sunny_outlined,
              color: AppColors.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Check current conditions',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _FarmStatusCard extends StatelessWidget {
  const _FarmStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
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
        children: [
          Expanded(
            child: _StatusItem(
              icon: Icons.water_drop_outlined,
              title: 'Soil',
              value: 'Analysis',
            ),
          ),
          Container(
            width: 1,
            height: 42,
            color: AppColors.divider,
          ),
          Expanded(
            child: _StatusItem(
              icon: Icons.eco_outlined,
              title: 'Crop',
              value: 'Health',
            ),
          ),
          Container(
            width: 1,
            height: 42,
            color: AppColors.divider,
          ),
          Expanded(
            child: _StatusItem(
              icon: Icons.insights_outlined,
              title: 'Yield',
              value: 'Prediction',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatusItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 21,
          color: AppColors.primary,
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback? onYieldPrediction;
  final VoidCallback? onDiseaseDetection;
  final VoidCallback? onSoilAnalysis;
  final VoidCallback? onWeather;

  const _QuickActionsGrid({
    this.onYieldPrediction,
    this.onDiseaseDetection,
    this.onSoilAnalysis,
    this.onWeather,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.analytics_outlined,
        title: 'Yield Prediction',
        subtitle: 'Predict crop yield',
        onTap: onYieldPrediction,
      ),
      _QuickAction(
        icon: Icons.local_florist_outlined,
        title: 'Disease Detection',
        subtitle: 'Check plant health',
        onTap: onDiseaseDetection,
      ),
      _QuickAction(
        icon: Icons.water_drop_outlined,
        title: 'Soil Analysis',
        subtitle: 'Analyze soil',
        onTap: onSoilAnalysis,
      ),
      _QuickAction(
        icon: Icons.cloud_outlined,
        title: 'Weather',
        subtitle: 'View forecast',
        onTap: onWeather,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 11,
        mainAxisSpacing: 11,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        return _QuickActionCard(
          action: actions[index],
        );
      },
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;

  const _QuickActionCard({
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(17),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: AppColors.cardGreen,
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: Icon(
                  action.icon,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                action.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _RecommendationCard({
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius18,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: AppColors.cardGreen,
            borderRadius: BorderRadius.circular(
              AppDimensions.radius18,
            ),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Recommendations',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Get personalized suggestions for your farm.',
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}