import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan tema ayarları
class AppTheme {
  // Temel renkler
  static const Color primaryColor = Color(0xFF6200EE);
  static const Color primaryVariantColor = Color(0xFF3700B3);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color secondaryVariantColor = Color(0xFF018786);
  static const Color errorColor = Color(0xFFB00020);

  // Arka plan renkleri
  static const Color darkBackgroundColor = Color(0xFF001020);
  static const Color darkSurfaceColor = Color(0xFF001A33);
  static const Color lightBackgroundColor = Color(0xFFF5F5F5);
  static const Color lightSurfaceColor = Color(0xFFFFFFFF);

  // Metin renkleri
  static const Color darkTextColor = Color(0xFFFFFFFF);
  static const Color lightTextColor = Color(0xFF000000);

  // Koyu tema
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: darkBackgroundColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        primaryContainer: primaryVariantColor,
        secondary: secondaryColor,
        secondaryContainer: secondaryVariantColor,
        surface: darkSurfaceColor,
        background: darkBackgroundColor,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: 'Poppins',
        bodyColor: darkTextColor,
        displayColor: darkTextColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      cardTheme: CardTheme(
        color: darkSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }

  // Açık tema
  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: lightBackgroundColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryVariantColor,
        secondary: secondaryColor,
        secondaryContainer: secondaryVariantColor,
        surface: lightSurfaceColor,
        background: lightBackgroundColor,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: ThemeData.light().textTheme.apply(
        fontFamily: 'Poppins',
        bodyColor: lightTextColor,
        displayColor: lightTextColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      cardTheme: CardTheme(
        color: lightSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }
}
