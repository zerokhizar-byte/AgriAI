import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  static const List<_NavItem> _items = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Yield',
    ),
    _NavItem(
      icon: Icons.local_florist_outlined,
      activeIcon: Icons.local_florist_rounded,
      label: 'Disease',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(
            color: AppColors.border,
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
        child: SizedBox(
          height: 72,
          child: Row(
            children: List.generate(
              _items.length,
              (index) {
                final _NavItem item = _items[index];

                final bool selected =
                    currentIndex == index;

                return Expanded(
                  child: _NavBarItem(
                    item: item,
                    selected: selected,
                    onTap: () {
                      onItemSelected(index);
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

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 6,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 5,
            horizontal: 2,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.cardGreen
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 160,
                ),
                child: Icon(
                  selected
                      ? item.activeIcon
                      : item.icon,
                  key: ValueKey<bool>(selected),
                  size: 23,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(
                  milliseconds: 160,
                ),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: selected
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
