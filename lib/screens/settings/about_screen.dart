import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class AboutScreen extends StatelessWidget {
  final String appVersion;

  const AboutScreen({
    super.key,
    this.appVersion = '1.0.0',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About AgriAI'),
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
            30,
          ),
          child: Column(
            children: [
              _AppInfoHeader(
                appVersion: appVersion,
              ),
              const SizedBox(height: 18),
              _AboutCard(
                title: 'About the App',
                icon: Icons.eco_outlined,
                child: const Text(
                  'AgriAI is a smart farming assistant designed to help farmers make better agricultural decisions using artificial intelligence, machine learning, weather information and crop insights.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _AboutCard(
                title: 'Key Features',
                icon: Icons.auto_awesome_outlined,
                child: const Column(
                  children: [
                    _FeatureRow(
                      icon: Icons.analytics_outlined,
                      text: 'Crop yield prediction',
                    ),
                    _FeatureRow(
                      icon: Icons.local_florist_outlined,
                      text: 'Plant disease detection',
                    ),
                    _FeatureRow(
                      icon: Icons.water_drop_outlined,
                      text: 'Soil analysis',
                    ),
                    _FeatureRow(
                      icon: Icons.cloud_outlined,
                      text: 'Weather information',
                    ),
                    _FeatureRow(
                      icon: Icons.lightbulb_outline_rounded,
                      text: 'Smart farming recommendations',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _AboutCard(
                title: 'Technology',
                icon: Icons.memory_rounded,
                child: const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TechnologyChip(
                      label: 'Flutter',
                    ),
                    _TechnologyChip(
                      label: 'Dart',
                    ),
                    _TechnologyChip(
                      label: 'Machine Learning',
                    ),
                    _TechnologyChip(
                      label: 'Artificial Intelligence',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Developed for smarter and more sustainable farming.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Version $appVersion',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppInfoHeader extends StatelessWidget {
  final String appVersion;

  const _AppInfoHeader({
    required this.appVersion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius22,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(
              alpha: 0.05,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: 0.10,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/agriai_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const Icon(
                    Icons.eco_rounded,
                    size: 48,
                    color: AppColors.primary,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'AgriAI',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Smart Farming Assistant',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Version $appVersion',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _AboutCard({
    required this.title,
    required this.icon,
    required this.child,
  });

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
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.cardGreen,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 11),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnologyChip extends StatelessWidget {
  final String label;

  const _TechnologyChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}