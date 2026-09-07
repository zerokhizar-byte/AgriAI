import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class SettingsScreen extends StatelessWidget {
  final bool notificationsEnabled;
  final bool locationEnabled;
  final bool automaticWeatherUpdates;
  final ValueChanged<bool>? onNotificationsChanged;
  final ValueChanged<bool>? onLocationChanged;
  final ValueChanged<bool>? onAutomaticWeatherChanged;
  final VoidCallback? onLanguageTap;
  final VoidCallback? onAboutTap;

  const SettingsScreen({
    super.key,
    this.notificationsEnabled = true,
    this.locationEnabled = true,
    this.automaticWeatherUpdates = true,
    this.onNotificationsChanged,
    this.onLocationChanged,
    this.onAutomaticWeatherChanged,
    this.onLanguageTap,
    this.onAboutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
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
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SettingsSectionTitle(
                title: 'Preferences',
              ),
              const SizedBox(height: 10),
              _SettingsCard(
                children: [
                  _SettingsSwitchTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle:
                        'Receive farming alerts and recommendations',
                    value: notificationsEnabled,
                    onChanged:
                        onNotificationsChanged,
                  ),
                  const _SettingsDivider(),
                  _SettingsSwitchTile(
                    icon: Icons.location_on_outlined,
                    title: 'Location',
                    subtitle:
                        'Use your location for local weather data',
                    value: locationEnabled,
                    onChanged: onLocationChanged,
                  ),
                  const _SettingsDivider(),
                  _SettingsSwitchTile(
                    icon: Icons.cloud_outlined,
                    title: 'Automatic Weather Updates',
                    subtitle:
                        'Keep weather information updated automatically',
                    value:
                        automaticWeatherUpdates,
                    onChanged:
                        onAutomaticWeatherChanged,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _SettingsSectionTitle(
                title: 'App',
              ),
              const SizedBox(height: 10),
              _SettingsCard(
                children: [
                  _SettingsNavigationTile(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    subtitle:
                        'Choose your preferred app language',
                    onTap: onLanguageTap,
                  ),
                  const _SettingsDivider(),
                  _SettingsNavigationTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About AgriAI',
                    subtitle:
                        'App information and project details',
                    onTap: onAboutTap,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _SettingsSectionTitle(
                title: 'Information',
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: AppColors.cardGreen,
                  borderRadius:
                      BorderRadius.circular(
                    AppDimensions.radius18,
                  ),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.eco_outlined,
                      size: 22,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'AgriAI helps farmers make smarter decisions using weather, soil, crop and AI-based agricultural insights.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color:
                              AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  final String title;

  const _SettingsSectionTitle({
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

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              alpha: 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          _SettingsIcon(
            icon: icon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsNavigationTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsNavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
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
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              _SettingsIcon(
                icon: icon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        height: 1.3,
                        fontWeight:
                            FontWeight.w500,
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
                size: 22,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  final IconData icon;

  const _SettingsIcon({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius:
            BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        size: 21,
        color: AppColors.primary,
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(
        left: 70,
      ),
      child: Divider(
        height: 1,
        color: AppColors.divider,
      ),
    );
  }
}