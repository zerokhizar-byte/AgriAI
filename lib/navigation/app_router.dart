import 'package:flutter/material.dart';

import '../screens/language/language_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/about_screen.dart';
import '../screens/settings/language_settings_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/soil_analysis/soil_analysis_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/weather/weather_screen.dart';
import '../screens/yield_prediction/yield_prediction_screen.dart';
import '../screens/disease_detection/disease_detection_screen.dart';
import '../screens/recommendations/recommendations_screen.dart';
import 'main_navigation.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String language = '/language';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String yieldPrediction = '/yield-prediction';
  static const String diseaseDetection = '/disease-detection';
  static const String soilAnalysis = '/soil-analysis';
  static const String weather = '/weather';
  static const String recommendations = '/recommendations';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String languageSettings = '/settings/language';
  static const String about = '/settings/about';

  static Route<dynamic> generateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(
          const SplashScreen(),
          settings,
        );

      case language:
        return _fadeRoute(
          const LanguageScreen(),
          settings,
        );

      case onboarding:
        return _fadeRoute(
          const OnboardingScreen(),
          settings,
        );

      // IMPORTANT:
      // Home is the root of the authenticated app.
      // It must use MainNavigation so the bottom navigation
      // controls Home, Weather, Insights and Profile.
      case home:
        return _fadeRoute(
          const MainNavigation(),
          settings,
        );

      case yieldPrediction:
        return _fadeRoute(
          const YieldPredictionScreen(),
          settings,
        );

      case diseaseDetection:
        return _fadeRoute(
          const DiseaseDetectionScreen(),
          settings,
        );

      case soilAnalysis:
        return _fadeRoute(
          const SoilAnalysisScreen(),
          settings,
        );

      case weather:
        return _fadeRoute(
          const WeatherScreen(),
          settings,
        );

      case recommendations:
        return _fadeRoute(
          const RecommendationsScreen(),
          settings,
        );

      // Direct profile route is retained for compatibility.
      case profile:
        return _fadeRoute(
          const ProfileScreen(),
          settings,
        );

      case AppRouter.settings:
        return _fadeRoute(
          const SettingsScreen(),
          settings,
        );

      case languageSettings:
        return _fadeRoute(
          const LanguageSettingsScreen(),
          settings,
        );

      case about:
        return _fadeRoute(
          const AboutScreen(),
          settings,
        );

      default:
        return _fadeRoute(
          const _UnknownRouteScreen(),
          settings,
        );
    }
  }

  static PageRouteBuilder<dynamic> _fadeRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: const Duration(
        milliseconds: 280,
      ),
      reverseTransitionDuration: const Duration(
        milliseconds: 220,
      ),
      pageBuilder: (
        context,
        animation,
        secondaryAnimation,
      ) {
        return page;
      },
      transitionsBuilder: (
        context,
        animation,
        secondaryAnimation,
        child,
      ) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    );
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
            ),
            const SizedBox(height: 12),
            const Text(
              'Page not found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRouter.home,
                  (route) => false,
                );
              },
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}