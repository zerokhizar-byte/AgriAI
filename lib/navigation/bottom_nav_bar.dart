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

  static const List<_BottomNavItem> _items = [
    _BottomNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _BottomNavItem(
      label: 'Yield Production',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
    ),
    _BottomNavItem(
      label: 'Disease Prediction',
      icon: Icons.local_florist_outlined,
      activeIcon: Icons.local_florist_rounded,
    ),
    _BottomNavItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 78,
        margin: const EdgeInsets.fromLTRB(
          12,
          0,
          12,
          10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.08,
              ),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: List.generate(
            _items.length,
            (index) {
              final _BottomNavItem item =
                  _items[index];

              final bool selected =
                  currentIndex == index;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(20),
                    onTap: () {
                      onItemSelected(index);
                    },
                    child: AnimatedContainer(
                      duration:
                          const Duration(
                        milliseconds: 220,
                      ),
                      curve: Curves.easeOutCubic,
                      margin:
                          const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.cardGreen
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            selected
                                ? item.activeIcon
                                : item.icon,
                            size: 23,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              height: 1.05,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
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
            },
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}