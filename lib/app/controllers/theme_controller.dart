import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

/// Uygulama temasını yöneten controller sınıfı.
/// Koyu mavi-siyah renk şeması üzerine kurulu, modern bir tema sağlar.
class ThemeController extends GetxController {
  static const String themeKey = 'dark_mode';

  static ThemeController get to => Get.find();

  // Tema durumu - her zaman koyu mod
  final RxBool _isDarkMode = true.obs;

  // Tema
  late final ThemeData darkTheme;

  // Getter'lar
  bool get isDarkMode => true; // Her zaman true döndür
  Color get backgroundColor =>
      const Color(0xFF00101F); // Koyu mavi-siyah arka plan
  Color get cardColor => const Color(0xFF001628); // Koyu mavi kart rengi
  Color get surfaceColor => const Color(0xFF01162D); // Bölüm arka plan rengi
  Color get primaryTextColor => Colors.white; // Ana metin rengi
  Color get secondaryTextColor => Colors.white70; // İkincil metin rengi
  Color get primaryColor => const Color(0xFF00A3FF); // Mavi ana renk
  Color get accentColor => const Color(0xFF00A3FF); // Mavi aksan rengi
  Color get secondaryColor => const Color(0xFF00A3FF); // İkincil renk

  @override
  void onInit() {
    super.onInit();
    _initializeTheme();
  }

  /// Temayı başlatır ve yapılandırır
  void _initializeTheme() {
    final ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      secondary: accentColor,
      background: backgroundColor,
      surface: surfaceColor,
      onSurface: primaryTextColor,
    );

    // Koyu tema yapılandırması
    darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      brightness: Brightness.dark,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: primaryTextColor,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      scaffoldBackgroundColor: backgroundColor,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColor),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    );
  }

  /// Tema değiştirme fonksiyonu - uyumluluk için korunmuştur
  /// Bu uygulama her zaman koyu tema kullanır
  Future<void> toggleTheme() async {
    // Hiçbir şey yapma, her zaman koyu mod
    update();
  }
}
