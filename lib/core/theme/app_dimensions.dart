import 'package:flutter/material.dart';

abstract final class AppDimensions {
  // Screen padding
  static const double screenHorizontal = 22.0;
  static const double screenVertical = 24.0;

  // Standard spacing
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing14 = 14.0;
  static const double spacing16 = 16.0;
  static const double spacing18 = 18.0;
  static const double spacing20 = 20.0;
  static const double spacing22 = 22.0;
  static const double spacing24 = 24.0;
  static const double spacing28 = 28.0;
  static const double spacing30 = 30.0;
  static const double spacing32 = 32.0;

  // Border radius
  static const double radius12 = 12.0;
  static const double radius14 = 14.0;
  static const double radius15 = 15.0;
  static const double radius16 = 16.0;
  static const double radius18 = 18.0;
  static const double radius20 = 20.0;
  static const double radius22 = 22.0;
  static const double radius24 = 24.0;
  static const double radius28 = 28.0;
  static const double radius32 = 32.0;

  // Common sizes
  static const double buttonHeight = 56.0;
  static const double smallButtonHeight = 44.0;
  static const double iconButtonSize = 44.0;
  static const double navigationHeight = 70.0;

  // Logo sizes
  static const double logoSmall = 48.0;
  static const double logoMedium = 72.0;
  static const double logoLarge = 140.0;

  // Feature cards
  static const double featureCardHeight = 145.0;
  static const double featureIconSize = 44.0;

  // Shadows
  static const double shadowBlur = 18.0;
  static const double shadowBlurLarge = 24.0;
  static const double shadowOffset = 8.0;

  // Standard page padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
    vertical: screenVertical,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);

  static const EdgeInsets largeCardPadding = EdgeInsets.all(20.0);

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 16.0,
  );
}