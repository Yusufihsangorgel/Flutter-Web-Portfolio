import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

/// Application-wide Material theme configuration.
final class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
      secondary: AppColors.accent,
      surface: AppColors.backgroundLight,
      onSurface: AppColors.textBright,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textBright,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppColors.accent, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }
}
