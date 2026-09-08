import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../screens/disease_detection/disease_detection_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/yield_prediction/yield_prediction_screen.dart';
import 'bottom_nav_bar.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigation> createState() =>
      _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with AutomaticKeepAliveClientMixin<MainNavigation> {
  late int _currentIndex;

  late final List<Widget> _screens;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex.clamp(0, 3);

    _screens = [
      HomeScreen(
        onYieldPrediction: _openYieldPrediction,
        onDiseaseDetection: _openDiseasePrediction,
        onSoilAnalysis: _openSoilAnalysis,
        onWeather: _openWeather,
        onRecommendations: _openRecommendations,
        onProfile: _openSettings,
        onCropHistory: _openCropHistory,
      ),
      const YieldPredictionScreen(),
      const DiseaseDetectionScreen(),
      const SettingsScreen(),
    ];
  }

  void _onNavigationChanged(int index) {
    if (index < 0 || index >= _screens.length) {
      return;
    }

    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  // ignore: unused_element
  void _openHome() {
    _onNavigationChanged(0);
  }

  void _openYieldPrediction() {
    _onNavigationChanged(1);
  }

  void _openDiseasePrediction() {
    _onNavigationChanged(2);
  }

  void _openSettings() {
    _onNavigationChanged(3);
  }

  void _openSoilAnalysis() {
    Navigator.of(context).pushNamed('/soil-analysis');
  }

  void _openWeather() {
    Navigator.of(context).pushNamed('/weather');
  }

  void _openRecommendations() {
    Navigator.of(context).pushNamed('/recommendations');
  }

  void _openCropHistory() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Crop History will be available soon.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: false,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onItemSelected: _onNavigationChanged,
      ),
    );
  }
}