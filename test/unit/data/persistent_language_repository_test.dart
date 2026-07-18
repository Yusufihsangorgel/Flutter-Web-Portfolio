import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/data/repositories/persistent_language_repository.dart';
import 'package:flutter_web_portfolio/app/domain/providers/asset_loader.dart';
import 'package:flutter_web_portfolio/app/domain/providers/key_value_store.dart';

final class _StubAssetLoader implements AssetLoader {
  @override
  Future<Map<String, dynamic>> loadNarrative() => throw UnsupportedError(
    'Narrative loading is outside this test boundary.',
  );

  @override
  Future<Map<String, dynamic>> loadPortfolio() => throw UnsupportedError(
    'Portfolio loading is outside this test boundary.',
  );

  @override
  Future<Map<String, dynamic>> loadTranslations(String languageCode) async => {
    'language': languageCode,
  };
}

final class _MemoryKeyValueStore implements KeyValueStore {
  String? value;

  @override
  String? readString(String key) => value;

  @override
  Future<void> writeString(String key, String value) async {
    this.value = value;
  }
}

final class _FailingKeyValueStore implements KeyValueStore {
  @override
  String? readString(String key) => throw StateError('unavailable');

  @override
  Future<void> writeString(String key, String value) =>
      throw StateError('unavailable');
}

void main() {
  late _MemoryKeyValueStore preferences;
  late PersistentLanguageRepository repository;

  setUp(() {
    preferences = _MemoryKeyValueStore();
    repository = PersistentLanguageRepository(
      assetLoader: _StubAssetLoader(),
      preferenceStore: preferences,
    );
  });

  group('PersistentLanguageRepository', () {
    test('publishes the complete supported locale set', () {
      expect(
        repository.supportedLanguages,
        equals({'tr', 'en', 'de', 'fr', 'es', 'ar', 'hi'}),
      );
    });

    test('defaults, persists, and replaces the selected locale', () async {
      expect(await repository.getSelectedLanguage(), 'en');

      await repository.saveSelectedLanguage('de');
      expect(await repository.getSelectedLanguage(), 'de');

      await repository.saveSelectedLanguage('ar');
      expect(await repository.getSelectedLanguage(), 'ar');
    });

    test('delegates translation loading with the requested locale', () async {
      expect(await repository.getTranslations('tr'), {'language': 'tr'});
    });

    test(
      'keeps English usable when preference storage is unavailable',
      () async {
        final unavailable = PersistentLanguageRepository(
          assetLoader: _StubAssetLoader(),
          preferenceStore: _FailingKeyValueStore(),
        );

        expect(await unavailable.getSelectedLanguage(), 'en');
        await expectLater(unavailable.saveSelectedLanguage('fr'), completes);
      },
    );
  });
}
