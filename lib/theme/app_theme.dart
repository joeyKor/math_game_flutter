import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0F172A);
  static const Color cardBg = Color(0xFF1E293B);
  static const Color primary = Color(0xFF6366F1);
  static const Color secondary = Color(0xFFEC4899);
  static const Color accent = Color(0xFF10B981);
  static const Color textBody = Color(0xFF94A3B8);
  static const Color textHeading = Colors.white;
}

ThemeData premiumTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: AppColors.textHeading,
      fontSize: 32,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: TextStyle(
      color: AppColors.textHeading,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    bodyMedium: TextStyle(color: AppColors.textBody, fontSize: 14),
  ),
  cardTheme: CardThemeData(
    color: AppColors.cardBg,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 4,
  ),
);
