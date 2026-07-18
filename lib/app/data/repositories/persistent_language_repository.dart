import 'dart:developer' as dev;

import 'package:flutter_web_portfolio/app/domain/providers/asset_loader.dart';
import 'package:flutter_web_portfolio/app/domain/providers/key_value_store.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/language_repository.dart';

/// Reads locale documents from assets and persists the selected locale.
final class PersistentLanguageRepository implements LanguageRepository {
  factory PersistentLanguageRepository({
    required AssetLoader assetLoader,
    required KeyValueStore preferenceStore,
  }) => PersistentLanguageRepository._(assetLoader, preferenceStore);

  const PersistentLanguageRepository._(
    this._assetLoader,
    this._preferenceStore,
  );

  final AssetLoader _assetLoader;
  final KeyValueStore _preferenceStore;

  static const _languageKey = 'selected_language';
  static const _supportedLanguages = {'tr', 'en', 'de', 'fr', 'es', 'ar', 'hi'};

  @override
  Set<String> get supportedLanguages => _supportedLanguages;

  @override
  Future<String> getSelectedLanguage() async {
    try {
      return _preferenceStore.readString(_languageKey) ?? 'en';
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
  Future<void> saveSelectedLanguage(String languageCode) async {
    try {
      await _preferenceStore.writeString(_languageKey, languageCode);
    } on Object catch (error) {
      dev.log(
        'Failed to save language preference',
        name: 'PersistentLanguageRepository',
        error: error,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) =>
      _assetLoader.loadTranslations(languageCode);
}
