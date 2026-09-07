import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class ProfileScreen extends StatelessWidget {
  final String? name;
  final String? email;
  final String? phone;
  final String? location;
  final String? farmName;
  final VoidCallback? onEditProfile;
  final VoidCallback? onSettings;
  final VoidCallback? onLogout;

  const ProfileScreen({
    super.key,
    this.name,
    this.email,
    this.phone,
    this.location,
    this.farmName,
    this.onEditProfile,
    this.onSettings,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        name?.trim().isNotEmpty == true
            ? name!.trim()
            : 'Farmer';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (onSettings != null)
            IconButton(
              onPressed: onSettings,
              tooltip: 'Settings',
              icon: const Icon(
                Icons.settings_outlined,
              ),
            ),
        ],
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
              _ProfileHeader(
                name: displayName,
                email: email,
                onEdit: onEditProfile,
              ),
              const SizedBox(height: 18),
              _ProfileInformationCard(
                phone: phone,
                location: location,
                farmName: farmName,
              ),
              const SizedBox(height: 18),
              _ProfileActionCard(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle:
                    'Manage your app preferences',
                onTap: onSettings,
              ),
              if (onLogout != null) ...[
                const SizedBox(height: 12),
                _ProfileActionCard(
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  subtitle:
                      'Sign out of your account',
                  color: const Color(0xFFD64545),
                  backgroundColor:
                      const Color(0xFFFFF1F1),
                  onTap: onLogout,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String? email;
  final VoidCallback? onEdit;

  const _ProfileHeader({
    required this.name,
    this.email,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasEmail =
        email?.trim().isNotEmpty == true;

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
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.primary.withValues(
                        alpha: 0.18,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (onEdit != null)
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onEdit,
                    customBorder:
                        const CircleBorder(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.border,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (hasEmail) ...[
            const SizedBox(height: 5),
            Text(
              email!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'F';
    }

    if (parts.length == 1) {
      return parts.first
          .substring(
            0,
            parts.first.length > 1 ? 2 : 1,
          )
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }
}

class _ProfileInformationCard extends StatelessWidget {
  final String? phone;
  final String? location;
  final String? farmName;

  const _ProfileInformationCard({
    this.phone,
    this.location,
    this.farmName,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_ProfileInfoItem>[
      if (_hasValue(phone))
        _ProfileInfoItem(
          icon: Icons.phone_outlined,
          title: 'Phone',
          value: phone!,
        ),
      if (_hasValue(location))
        _ProfileInfoItem(
          icon: Icons.location_on_outlined,
          title: 'Location',
          value: location!,
        ),
      if (_hasValue(farmName))
        _ProfileInfoItem(
          icon: Icons.agriculture_outlined,
          title: 'Farm',
          value: farmName!,
        ),
    ];

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(
            AppDimensions.radius18,
          ),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: const Text(
          'Add your farm and personal information to complete your profile.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.4,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

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
        children: [
          for (var i = 0; i < items.length; i++) ...[
            items[i],
            if (i != items.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 13,
                ),
                child: Divider(
                  height: 1,
                  color: AppColors.divider,
                ),
              ),
          ],
        ],
      ),
    );
  }

  bool _hasValue(String? value) {
    return value != null &&
        value.trim().isNotEmpty;
  }
}

class _ProfileInfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileInfoItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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

class _ProfileActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const _ProfileActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color = AppColors.primary,
    this.backgroundColor = AppColors.surface,
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
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: backgroundColor,
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color ==
                                const Color(
                                  0xFFD64545,
                                )
                            ? color
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
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