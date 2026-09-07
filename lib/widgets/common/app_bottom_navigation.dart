import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onItemSelected;

  const AppBottomNavigation({
    super.key,
    this.currentIndex = 0,
    this.onItemSelected,
  });

  static const List<_BottomNavItemData> _items = [
    _BottomNavItemData(
      icon: Icons.home_rounded,
      label: 'Home',
    ),
    _BottomNavItemData(
      icon: Icons.analytics_rounded,
      label: 'Yield',
    ),
    _BottomNavItemData(
      icon: Icons.local_florist_rounded,
      label: 'Disease',
    ),
    _BottomNavItemData(
      icon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(
              alpha: 0.08,
            ),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            10,
            7,
            10,
            8,
          ),
          child: Row(
            children: List.generate(
              _items.length,
              (index) {
                final item = _items[index];

                return Expanded(
                  child: _BottomNavItem(
                    icon: item.icon,
                    label: item.label,
                    selected: currentIndex == index,
                    onTap: () {
                      onItemSelected?.call(index);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 220,
      ),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(
        horizontal: 4,
      ),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.cardGreen
            : Colors.transparent,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius16,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            AppDimensions.radius16,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: selected ? 1.05 : 1.0,
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItemData {
  final IconData icon;
  final String label;

  const _BottomNavItemData({
    required this.icon,
    required this.label,
  });
}