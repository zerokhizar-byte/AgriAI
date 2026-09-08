import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/language/language_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'navigation/main_navigation.dart';
import 'screens/yield_prediction/yield_prediction_screen.dart';
import 'screens/disease_detection/disease_detection_screen.dart';
import 'screens/soil_analysis/soil_analysis_screen.dart';
import 'screens/weather/weather_screen.dart';
import 'screens/recommendations/recommendations_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/language_settings_screen.dart';
import 'screens/settings/about_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

class AgriAIApp extends StatelessWidget {
  const AgriAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriAI',

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor:
            AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
      ),

      // FIRST SCREEN
      home: const SplashScreen(),

      // APP ROUTES
      routes: {
        '/splash': (context) =>
            const SplashScreen(),

        '/language': (context) =>
            const LanguageScreen(),

        '/onboarding': (context) =>
            const OnboardingScreen(),

        // IMPORTANT:
        // Always open MainNavigation instead
        // of opening HomeScreen directly.
        '/home': (context) =>
            const MainNavigation(),

        '/yield-prediction': (context) =>
            const YieldPredictionScreen(),

        '/disease-detection': (context) =>
            const DiseaseDetectionScreen(),

        '/soil-analysis': (context) =>
            const SoilAnalysisScreen(),

        '/weather': (context) =>
            const WeatherScreen(),

        '/recommendations': (context) =>
            const RecommendationsScreen(),

        '/profile': (context) =>
            const ProfileScreen(),

        '/settings': (context) =>
            const SettingsScreen(),

        '/language-settings': (context) =>
            const LanguageSettingsScreen(),

        '/about': (context) =>
            const AboutScreen(),

        '/login': (context) =>
            const LoginScreen(),

        '/register': (context) =>
            const RegisterScreen(),

        '/forgot-password': (context) =>
            const ForgotPasswordScreen(),
      },
    );
  }
}