import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const gold = Color(0xFFD4AF37);
  static const goldSoft = Color(0xFFE8CF7A);
  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFF9A9A9A);
}

ThemeData buildPremiumTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      secondary: AppColors.goldSoft,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.textPrimary,
    ),
    useMaterial3: true,
  );
}
