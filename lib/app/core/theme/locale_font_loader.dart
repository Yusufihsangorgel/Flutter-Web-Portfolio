import 'package:flutter/services.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';

abstract final class LocaleFontLoader {
  static Future<void> loadForLanguage(String languageCode) async {
    final (family, path) = switch (languageCode) {
      'ar' => (
        AppFonts.notoSansArabicFamily,
        'assets/fonts/noto_sans_arabic/NotoSansArabic-Variable.ttf',
      ),
      'hi' => (
        AppFonts.notoSansDevanagariFamily,
        'assets/fonts/noto_sans_devanagari/NotoSansDevanagari-Variable.ttf',
      ),
      _ => (null, null),
    };
    if (family == null || path == null) return;

    try {
      await (FontLoader(family)..addFont(rootBundle.load(path))).load();
    } on Object {
      // The system font stack remains available when a locale font fails.
    }
  }
}
