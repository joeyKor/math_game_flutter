import 'package:flutter/material.dart';

class ThemeConfig {
  final Color background;
  final Color cardBg;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color gradientStart;
  final Color gradientEnd;
  final Brightness brightness;
  final Color textColor;
  final Color subTextColor;
  final List<Color> vibrantColors;

  ThemeConfig({
    required this.background,
    required this.cardBg,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.gradientStart,
    required this.gradientEnd,
    this.brightness = Brightness.dark,
    this.textColor = Colors.white,
    this.subTextColor = const Color(0xFF94A3B8),
    required this.vibrantColors,
  });
}

class AppThemes {
  static final Map<String, ThemeConfig> configs = {
    'Default': ThemeConfig(
      background: const Color(0xFF0F172A),
      cardBg: const Color(0xFF1E293B),
      primary: const Color(0xFF6366F1),
      secondary: const Color(0xFFEC4899),
      accent: const Color(0xFF10B981),
      gradientStart: const Color(0xFF0F172A),
      gradientEnd: const Color(0xFF1E1E2C),
      vibrantColors: [
        const Color(0xFF6366F1),
        const Color(0xFFEC4899),
        const Color(0xFF10B981),
        const Color(0xFFF59E0B),
        const Color(0xFF3B82F6),
        const Color(0xFF14B8A6),
      ],
    ),
    'Space': ThemeConfig(
      background: const Color(0xFF09031A),
      cardBg: const Color(0xFF1A1233),
      primary: const Color(0xFFA855F7),
      secondary: const Color(0xFFD946EF),
      accent: const Color(0xFF22D3EE),
      gradientStart: const Color(0xFF09031A),
      gradientEnd: const Color(0xFF2D1B69),
      vibrantColors: [
        const Color(0xFFA855F7),
        const Color(0xFFD946EF),
        const Color(0xFF22D3EE),
        const Color(0xFF818CF8),
        const Color(0xFFC084FC),
        const Color(0xFFF472B6),
      ],
    ),
    'Matrix': ThemeConfig(
      background: const Color(0xFF000000),
      cardBg: const Color(0xFF051105),
      primary: const Color(0xFF00FF41),
      secondary: const Color(0xFF008F11),
      accent: const Color(0xFF00FF41),
      gradientStart: const Color(0xFF000000),
      gradientEnd: const Color(0xFF051F05),
      vibrantColors: [
        const Color(0xFF00FF41),
        const Color(0xFF008F11),
        const Color(0xFF003B00),
        const Color(0xFF0D310D),
        const Color(0xFF00D215),
        const Color(0xFF005E00),
      ],
    ),
    'Sunset': ThemeConfig(
      background: const Color(0xFF2D0A0A),
      cardBg: const Color(0xFF451A1A),
      primary: const Color(0xFFF97316),
      secondary: const Color(0xFFEF4444),
      accent: const Color(0xFFFACC15),
      gradientStart: const Color(0xFF210505),
      gradientEnd: const Color(0xFF7A1A1A),
      vibrantColors: [
        const Color(0xFFF97316),
        const Color(0xFFEF4444),
        const Color(0xFFFACC15),
        const Color(0xFFDC2626),
        const Color(0xFFB91C1C),
        const Color(0xFFEA580C),
      ],
    ),
    'Ocean': ThemeConfig(
      background: const Color(0xFF082F49),
      cardBg: const Color(0xFF0C4A6E),
      primary: const Color(0xFF38BDF8),
      secondary: const Color(0xFF2DD4BF),
      accent: const Color(0xFFF1F5F9),
      gradientStart: const Color(0xFF07263B),
      gradientEnd: const Color(0xFF0E7490),
      vibrantColors: [
        const Color(0xFF38BDF8),
        const Color(0xFF2DD4BF),
        const Color(0xFF0891B2),
        const Color(0xFF0284C7),
        const Color(0xFF0EA5E9),
        const Color(0xFF06B6D4),
      ],
    ),
    'Paper': ThemeConfig(
      background: const Color(0xFFFDF6E3),
      cardBg: const Color(0xFFF3EAD3),
      primary: const Color(0xFFB58900),
      secondary: const Color(0xFFCB4B16),
      accent: const Color(0xFF268BD2),
      gradientStart: const Color(0xFFFDF6E3),
      gradientEnd: const Color(0xFFE4D7AD),
      brightness: Brightness.light,
      textColor: const Color(0xFF586E75),
      subTextColor: const Color(0xFF93A1A1),
      vibrantColors: [
        const Color(0xFFB58900),
        const Color(0xFFCB4B16),
        const Color(0xFF268BD2),
        const Color(0xFF2AA198),
        const Color(0xFF859900),
        const Color(0xFFD33682),
      ],
    ),
    'Royal': ThemeConfig(
      background: const Color(0xFF1A1110),
      cardBg: const Color(0xFF2D2423),
      primary: const Color(0xFFFFD700),
      secondary: const Color(0xFFC0C0C0),
      accent: const Color(0xFFFFFFFF),
      gradientStart: const Color(0xFF000000),
      gradientEnd: const Color(0xFF2A2120),
      vibrantColors: [
        const Color(0xFFFFD700),
        const Color(0xFFC0C0C0),
        const Color(0xFFB8860B),
        const Color(0xFFDAA520),
        const Color(0xFFEEE8AA),
        const Color(0xFFF0E68C),
      ],
    ),
    'Cyberpunk': ThemeConfig(
      background: const Color(0xFF0D0221),
      cardBg: const Color(0xFF1B0344),
      primary: const Color(0xFFFF00E0),
      secondary: const Color(0xFF00F0FF),
      accent: const Color(0xFFF7EB00),
      gradientStart: const Color(0xFF0D0221),
      gradientEnd: const Color(0xFF2F0B5A),
      vibrantColors: [
        const Color(0xFFFF00E0),
        const Color(0xFF00F0FF),
        const Color(0xFFF7EB00),
        const Color(0xFF711C91),
        const Color(0xFF091833),
        const Color(0xFFEA00D9),
      ],
    ),
    'Forest': ThemeConfig(
      background: const Color(0xFF061A0C),
      cardBg: const Color(0xFF142B1A),
      primary: const Color(0xFF22C55E),
      secondary: const Color(0xFF15803D),
      accent: const Color(0xFFFACC15),
      gradientStart: const Color(0xFF061A0C),
      gradientEnd: const Color(0xFF1B4332),
      vibrantColors: [
        const Color(0xFF22C55E),
        const Color(0xFF15803D),
        const Color(0xFFFACC15),
        const Color(0xFF064E3B),
        const Color(0xFF10B981),
        const Color(0xFF34D399),
      ],
    ),
    'Frost': ThemeConfig(
      background: const Color(0xFF0B1E2B),
      cardBg: const Color(0xFF17374D),
      primary: const Color(0xFF67E8F9),
      secondary: const Color(0xFF38BDF8),
      accent: const Color(0xFFF1F5F9),
      gradientStart: const Color(0xFF0B1E2B),
      gradientEnd: const Color(0xFF2A5064),
      vibrantColors: [
        const Color(0xFF67E8F9),
        const Color(0xFF38BDF8),
        const Color(0xFFF1F5F9),
        const Color(0xFF0EA5E9),
        const Color(0xFF0284C7),
        const Color(0xFFBAE6FD),
      ],
    ),
    'Lava': ThemeConfig(
      background: const Color(0xFF1A0A0A),
      cardBg: const Color(0xFF2D1414),
      primary: const Color(0xFFEF4444),
      secondary: const Color(0xFFF97316),
      accent: const Color(0xFFFFD700),
      gradientStart: const Color(0xFF1A0A0A),
      gradientEnd: const Color(0xFF451A1A),
      vibrantColors: [
        const Color(0xFFEF4444),
        const Color(0xFFF97316),
        const Color(0xFFFFD700),
        const Color(0xFFB91C1C),
        const Color(0xFF991B1B),
        const Color(0xFFF87171),
      ],
    ),
    'Midnight': ThemeConfig(
      background: const Color(0xFF020617),
      cardBg: const Color(0xFF0F172A),
      primary: const Color(0xFF94A3B8),
      secondary: const Color(0xFF64748B),
      accent: const Color(0xFFF8FAFC),
      gradientStart: const Color(0xFF020617),
      gradientEnd: const Color(0xFF1E293B),
      vibrantColors: [
        const Color(0xFF94A3B8),
        const Color(0xFF64748B),
        const Color(0xFFF8FAFC),
        const Color(0xFF1E293B),
        const Color(0xFF334155),
        const Color(0xFF475569),
      ],
    ),
  };

  static ThemeData getTheme(String themeId) {
    final config = configs[themeId] ?? configs['Default']!;

    return ThemeData(
      brightness: config.brightness,
      primaryColor: config.primary,
      scaffoldBackgroundColor: config.background,
      colorScheme: ColorScheme(
        brightness: config.brightness,
        primary: config.primary,
        onPrimary: config.brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        secondary: config.secondary,
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: config.cardBg,
        onSurface: config.textColor,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: config.textColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: config.textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(color: config.subTextColor, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: config.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
      ),
    );
  }
}

// Keep AppColors for backward compatibility if possible, but map them to current theme
// or just update existing code to use the provider's theme config.
class AppColors {
  static const Color background = Color(0xFF0F172A);
  static const Color cardBg = Color(0xFF1E293B);
  static const Color primary = Color(0xFF6366F1);
  static const Color secondary = Color(0xFFEC4899);
  static const Color accent = Color(0xFF10B981);
  static const Color textBody = Color(0xFF94A3B8);
  static const Color textHeading = Colors.white;
}
