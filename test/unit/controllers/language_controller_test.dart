import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';

void main() {
  group('LanguageController', () {
    group('getLanguageName', () {
      test('returns correct name for each supported language', () {
        expect(LanguageController.getLanguageName('tr'), 'Türkçe');
        expect(LanguageController.getLanguageName('en'), 'English');
        expect(LanguageController.getLanguageName('de'), 'Deutsch');
        expect(LanguageController.getLanguageName('fr'), 'Français');
        expect(LanguageController.getLanguageName('es'), 'Español');
        expect(LanguageController.getLanguageName('ar'), 'العربية');
        expect(LanguageController.getLanguageName('hi'), 'हिन्दी');
      });

      test('returns Unknown for unsupported language code', () {
        expect(LanguageController.getLanguageName('ja'), 'Unknown');
        expect(LanguageController.getLanguageName(''), 'Unknown');
        expect(LanguageController.getLanguageName('xyz'), 'Unknown');
      });
    });

    group('getLanguageFlag', () {
      test('returns a non-empty flag for each supported language', () {
        for (final code in ['tr', 'en', 'de', 'fr', 'es']) {
          final flag = LanguageController.getLanguageFlag(code);
          expect(flag.isNotEmpty, isTrue, reason: 'Flag for $code should not be empty');
        }
      });

      test('returns globe emoji for unsupported language', () {
        final fallback = LanguageController.getLanguageFlag('xx');
        expect(fallback, isNotEmpty);
      });
    });
  });
}
