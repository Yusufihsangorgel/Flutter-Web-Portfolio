import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

/// Uygulama temasını yöneten controller sınıfı
class ThemeController extends GetxController {
  static const String themeKey = 'dark_mode';

  static ThemeController get to => Get.find();

  // Tema durumu - her zaman koyu mod
  final RxBool _isDarkMode = true.obs;

  // Tema
  late final ThemeData darkTheme;

  // Getter'lar
  bool get isDarkMode => true; // Her zaman true döndür
  Color get backgroundColor => const Color(0xFF00101F);
  Color get cardColor => const Color(0xFF001628);
  Color get surfaceColor => const Color(0xFF01162D); // Bölüm arka plan rengi
  Color get primaryTextColor => Colors.white;
  Color get secondaryTextColor => Colors.white70;
  Color get primaryColor => const Color(0xFF00A3FF); // Mavi
  Color get accentColor => const Color(0xFF00A3FF); // Mavi aksan
  Color get secondaryColor => const Color(0xFF00A3FF); // Mavi - accent ile aynı

  @override
  void onInit() {
    super.onInit();
    _initializeTheme();
  }

  // Temayı başlat
  void _initializeTheme() {
    final ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      secondary: accentColor,
      background: const Color(0xFF00101F), // Koyu mavi-siyah arka plan
      surface: const Color(0xFF001628), // Koyu mavi kart rengi
      onSurface: Colors.white,
    );

    // Dark tema
    darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      brightness: Brightness.dark,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: const Color(0xFF00101F), // Koyu mavi-siyah
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      scaffoldBackgroundColor: const Color(0xFF00101F), // Koyu mavi-siyah
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF00A3FF), // Mavi
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF00A3FF)),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    );
  }

  // Tema değiştirme fonksiyonu - artık işlevsiz, sadece uyumluluk için
  Future<void> toggleTheme() async {
    // Hiçbir şey yapma, her zaman koyu mod
    update();
  }
}
