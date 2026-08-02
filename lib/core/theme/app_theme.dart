import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get gray => _buildGray();
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _buildGray() {
    final theme = _build(Brightness.light);
    return theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        surface: AppColors.grayBackground,
        surfaceContainer: AppColors.grayHistory,
      ),
      scaffoldBackgroundColor: AppColors.grayBackground,
      cardTheme: theme.cardTheme.copyWith(color: AppColors.grayHistory),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        fillColor: const Color(0xFFE5E7E6),
      ),
    );
  }

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: brightness,
      surface: isDark ? AppColors.darkBackground : AppColors.lightBackground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamilyFallback: const ['Hiragino Sans', 'Noto Sans JP'],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkKey : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
