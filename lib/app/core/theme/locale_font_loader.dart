import 'package:flutter/services.dart';
import 'package:flutter_web_portfolio/app/core/logging/app_logger.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';

/// Loads the fonts a language needs beyond the eagerly declared Latin set.
abstract interface class LocaleFontLoader {
  /// Completes once the language's font is registered. Safe to call repeatedly.
  Future<void> loadForLanguage(String languageCode);
}

/// Loader for languages whose fonts are already available.
final class NoopLocaleFontLoader implements LocaleFontLoader {
  const NoopLocaleFontLoader();

  @override
  Future<void> loadForLanguage(String languageCode) async {}
}

/// Loads the Arabic and Devanagari fonts from the asset bundle, once each.
final class AssetLocaleFontLoader implements LocaleFontLoader {
  AssetLocaleFontLoader({required this.logger, AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AppLogger logger;
  final AssetBundle _bundle;
  final Map<String, Future<void>> _loads = <String, Future<void>>{};

  @override
  Future<void> loadForLanguage(String languageCode) {
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
    if (family == null || path == null) return Future<void>.value();
    return _loads.putIfAbsent(family, () => _load(family, path));
  }

  Future<void> _load(String family, String path) async {
    try {
      await (FontLoader(family)..addFont(_bundle.load(path))).load();
    } on Object catch (error, stackTrace) {
      // Allow a later switch to retry a failed fetch.
      _loads.removeWhere((key, _) => key == family);
      logger.error(
        'Failed to load the $family font',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
