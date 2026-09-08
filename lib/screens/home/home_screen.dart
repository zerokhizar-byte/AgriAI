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
  final VoidCallback? onCropHistory;

  const HomeScreen({
    super.key,
    this.farmerName,
    this.onYieldPrediction,
    this.onDiseaseDetection,
    this.onSoilAnalysis,
    this.onWeather,
    this.onRecommendations,
    this.onProfile,
    this.onCropHistory,
  });

  @override
  Widget build(BuildContext context) {
    final String name =
        farmerName?.trim().isNotEmpty == true
            ? farmerName!.trim()
            : 'Farmer';

    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await Future<void>.delayed(
              const Duration(milliseconds: 400),
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
                  30,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _HomeHeader(
                        farmerName: name,
                        onProfile: onProfile,
                      ),
                      const SizedBox(height: 20),
                      const _WeatherCard(),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        title: 'Quick Access',
                      ),
                      const SizedBox(height: 12),
                      _QuickAccessGrid(
                        onYieldPrediction:
                            onYieldPrediction,
                        onDiseaseDetection:
                            onDiseaseDetection,
                        onSoilAnalysis:
                            onSoilAnalysis,
                        onWeather:
                            onWeather,
                        onRecommendations:
                            onRecommendations,
                        onCropHistory:
                            onCropHistory,
                      ),
                      const SizedBox(height: 25),
                    ],
                  ),
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
                'Hello, Farmer! 👋',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                farmerName == 'Farmer'
                    ? 'What would you like to do today?'
                    : 'Good to see you again, $farmerName.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.cardGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withValues(
                      alpha: 0.05,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 26,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius18,
        ),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(
              alpha: 0.06,
            ),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.cardGreen,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.wb_sunny_rounded,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 13),
              const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '28°C',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Partly Cloudy',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 1,
                height: 50,
                color: AppColors.divider,
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Aurangabad,\nMaharashtra',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 1,
            color: AppColors.divider,
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _WeatherDetail(
                  icon: Icons.water_drop_outlined,
                  label: 'Humidity',
                  value: '65%',
                ),
              ),
              SizedBox(
                width: 1,
                height: 24,
                child: ColoredBox(
                  color: AppColors.divider,
                ),
              ),
              Expanded(
                child: _WeatherDetail(
                  icon: Icons.air_rounded,
                  label: 'Wind',
                  value: '12 km/h',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 17,
          color: AppColors.primary,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: RichText(
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final VoidCallback? onYieldPrediction;
  final VoidCallback? onDiseaseDetection;
  final VoidCallback? onSoilAnalysis;
  final VoidCallback? onWeather;
  final VoidCallback? onRecommendations;
  final VoidCallback? onCropHistory;

  const _QuickAccessGrid({
    this.onYieldPrediction,
    this.onDiseaseDetection,
    this.onSoilAnalysis,
    this.onWeather,
    this.onRecommendations,
    this.onCropHistory,
  });

  @override
  Widget build(BuildContext context) {
    final List<_QuickAction> actions = [
      _QuickAction(
        icon: Icons.eco_rounded,
        title: 'Crop Yield\nPrediction',
        subtitle: 'Predict crop yield',
        onTap: onYieldPrediction,
      ),
      _QuickAction(
        icon: Icons.local_florist_rounded,
        title: 'Disease\nDetection',
        subtitle: 'Check plant health',
        onTap: onDiseaseDetection,
      ),
      _QuickAction(
        icon: Icons.inventory_2_outlined,
        title: 'Fertilizer\nRecommendation',
        subtitle: 'Get fertilizer advice',
        onTap: onRecommendations,
      ),
      _QuickAction(
        icon: Icons.water_drop_rounded,
        title: 'Irrigation\nAdvisor',
        subtitle: 'Smart irrigation',
        onTap: onSoilAnalysis,
      ),
      _QuickAction(
        icon: Icons.wb_cloudy_rounded,
        title: 'Weather\nForecast',
        subtitle: 'View forecast',
        onTap: onWeather,
      ),
      _QuickAction(
        icon: Icons.history_rounded,
        title: 'Crop\nHistory',
        subtitle: 'View farm history',
        onTap: onCropHistory,
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
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.98,
      ),
      itemBuilder: (
        BuildContext context,
        int index,
      ) {
        return _QuickAccessCard(
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

class _QuickAccessCard extends StatelessWidget {
  final _QuickAction action;

  const _QuickAccessCard({
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            12,
            14,
            12,
            12,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(19),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(
                  alpha: 0.05,
                ),
                blurRadius: 13,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.cardGreen,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Icon(
                  action.icon,
                  size: 29,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                action.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                action.subtitle,
                textAlign: TextAlign.center,
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