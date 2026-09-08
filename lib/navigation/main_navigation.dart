import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../screens/disease_detection/disease_detection_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/yield_prediction/yield_prediction_screen.dart';
import 'bottom_nav_bar.dart';

typedef ThemeModeChanged = Future<void> Function(ThemeMode mode);

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  final ThemeModeChanged? onThemeModeChanged;

  const MainNavigation({
    super.key,
    this.initialIndex = 0,
    this.onThemeModeChanged,
  });

  @override
  State<MainNavigation> createState() =>
      _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
  }

  void _onNavigationChanged(int index) {
    if (index < 0 || index > 3) {
      return;
    }

    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(
          onProfile: () {
            _onNavigationChanged(3);
          },
        );

      case 1:
        return const YieldPredictionScreen();

      case 2:
        return const DiseaseDetectionScreen();

      case 3:
        return SettingsScreen(
          onThemeModeChanged: widget.onThemeModeChanged,
        );

      default:
        return HomeScreen(
          onProfile: () {
            _onNavigationChanged(3);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildCurrentScreen(),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onItemSelected: _onNavigationChanged,
      ),
    );
  }
}
