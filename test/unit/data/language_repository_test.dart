import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/data/repositories/language_repository_impl.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_assets_provider.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_local_storage_provider.dart';

class _MockAssetsProvider implements IAssetsProvider {
  @override
  Future<List<Map<String, dynamic>>> loadProjectsData() async => [];

  @override
  Future<Map<String, dynamic>> loadTranslations(String langCode) async =>
      {'key': 'value', 'lang': langCode};
}

class _MockLocalStorage implements ILocalStorageProvider {
  String? _savedLanguage;

  @override
  bool get isInitialized => true;

  @override
  String? getString(String key) => _savedLanguage;

  @override
  Future<bool> setString(String key, String value) async {
    _savedLanguage = value;
    return true;
  }

  @override
  bool? getBool(String key) => null;

  @override
  Future<bool> setBool(String key, bool value) async => true;

  @override
  int? getInt(String key) => null;

  @override
  Future<bool> setInt(String key, int value) async => true;

  @override
  Future<bool> remove(String key) async => true;

  @override
  Future<bool> clear() async => true;
}

void main() {
  late LanguageRepositoryImpl repository;
  late _MockAssetsProvider mockAssets;
  late _MockLocalStorage mockStorage;

  setUp(() {
    mockAssets = _MockAssetsProvider();
    mockStorage = _MockLocalStorage();
    repository = LanguageRepositoryImpl(
      assetsProvider: mockAssets,
      localStorageProvider: mockStorage,
    );
  });

  group('LanguageRepositoryImpl', () {
    group('getSupportedLanguages', () {
      test('returns 7 languages', () {
        final languages = repository.getSupportedLanguages();
        expect(languages.length, 7);
      });

      test('contains all expected language codes', () {
        final languages = repository.getSupportedLanguages();
        expect(languages.containsKey('tr'), isTrue);
        expect(languages.containsKey('en'), isTrue);
        expect(languages.containsKey('de'), isTrue);
        expect(languages.containsKey('fr'), isTrue);
        expect(languages.containsKey('es'), isTrue);
        expect(languages.containsKey('ar'), isTrue);
        expect(languages.containsKey('hi'), isTrue);
      });

      test('does not contain unsupported language codes', () {
        final languages = repository.getSupportedLanguages();
        expect(languages.containsKey('ja'), isFalse);
        expect(languages.containsKey('zh'), isFalse);
        expect(languages.containsKey('ko'), isFalse);
      });

      test('each language has a non-empty flag value', () {
        final languages = repository.getSupportedLanguages();
        for (final entry in languages.entries) {
          expect(entry.value.isNotEmpty, isTrue,
              reason: 'Flag for ${entry.key} should not be empty');
        }
      });
    });

    group('getSelectedLanguage', () {
      test('returns en when no saved preference', () async {
        final language = await repository.getSelectedLanguage();
        expect(language, 'en');
      });

      test('returns saved language when preference exists', () async {
        await repository.saveSelectedLanguage('de');
        final language = await repository.getSelectedLanguage();
        expect(language, 'de');
      });
    });

    group('saveSelectedLanguage', () {
      test('persists language code', () async {
        await repository.saveSelectedLanguage('fr');
        final language = await repository.getSelectedLanguage();
        expect(language, 'fr');
      });

      test('overwrites previous saved language', () async {
        await repository.saveSelectedLanguage('es');
        await repository.saveSelectedLanguage('ar');
        final language = await repository.getSelectedLanguage();
        expect(language, 'ar');
      });
    });

    group('getTranslations', () {
      test('returns translations from assets provider', () async {
        final translations = await repository.getTranslations('en');
        expect(translations, isNotEmpty);
        expect(translations['key'], 'value');
        expect(translations['lang'], 'en');
      });

      test('passes language code to assets provider', () async {
        final translations = await repository.getTranslations('tr');
        expect(translations['lang'], 'tr');
      });
    });
  });
}
