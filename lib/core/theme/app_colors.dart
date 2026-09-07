import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFFEAF7EC);

  // Main backgrounds
  static const Color background = Color(0xFFF7FCF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF4FFF5);

  // Text
  static const Color textPrimary = Color(0xFF17351B);
  static const Color textSecondary = Color(0xFF638069);
  static const Color textMuted = Color(0xFF8A9B8D);

  // Borders
  static const Color border = Color(0xFFDDEFE0);
  static const Color divider = Color(0xFFEAF3EB);

  // Agriculture status
  static const Color healthy = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE69A2E);
  static const Color danger = Color(0xFFD94A4A);
  static const Color info = Color(0xFF3F7FBF);

  // Cards
  static const Color cardGreen = Color(0xFFEAF8EC);
  static const Color cardGreenLight = Color(0xFFF0F8F1);

  // Shadows
  static const Color shadow = Color(0x14245C2A);

  // Common transparent color
  static const Color transparent = Colors.transparent;
}