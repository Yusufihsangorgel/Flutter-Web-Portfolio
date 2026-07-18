import 'dart:developer' as dev;

import 'package:flutter_web_portfolio/app/domain/providers/asset_loader.dart';
import 'package:flutter_web_portfolio/app/domain/providers/key_value_store.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/language_repository.dart';

/// Reads locale documents from assets and persists the selected locale.
final class PersistentLanguageRepository implements LanguageRepository {
  factory PersistentLanguageRepository({
    required AssetLoader assetLoader,
    required KeyValueStore preferenceStore,
    required Set<String> supportedLanguages,
  }) => PersistentLanguageRepository._(
    assetLoader,
    preferenceStore,
    Set.unmodifiable(supportedLanguages),
  );

  const PersistentLanguageRepository._(
    this._assetLoader,
    this._preferenceStore,
    this._supportedLanguages,
  );

  final AssetLoader _assetLoader;
  final KeyValueStore _preferenceStore;

  static const _languageKey = 'selected_language';
  final Set<String> _supportedLanguages;

  @override
  Set<String> get supportedLanguages => _supportedLanguages;

  @override
  Future<String> getSelectedLanguage() async {
    try {
      final saved = _preferenceStore.readString(_languageKey);
      return saved != null && _supportedLanguages.contains(saved)
          ? saved
          : 'en';
    } on Object catch (error) {
      dev.log(
        'Failed to load language preference',
        name: 'PersistentLanguageRepository',
        error: error,
      );
      return 'en';
    }
  }

  @override
  Future<void> saveSelectedLanguage(String languageCode) =>
      _preferenceStore.writeString(_languageKey, languageCode);

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) =>
      _assetLoader.loadTranslations(languageCode);
}
