import 'dart:developer' as dev;

import 'package:flutter_web_portfolio/app/domain/providers/i_assets_provider.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_local_storage_provider.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/i_language_repository.dart';

/// JSON-backed language repo — reads translations from assets, persists preference.
final class LanguageRepositoryImpl implements ILanguageRepository {
  factory LanguageRepositoryImpl({
    required IAssetsProvider assetsProvider,
    required ILocalStorageProvider localStorageProvider,
  }) => LanguageRepositoryImpl._(assetsProvider, localStorageProvider);

  LanguageRepositoryImpl._(this._assetsProvider, this._localStorageProvider);
  final IAssetsProvider _assetsProvider;
  final ILocalStorageProvider _localStorageProvider;

  static const String _languageKey = 'selected_language';

  static const Set<String> _supportedLanguages = {
    'tr',
    'en',
    'de',
    'fr',
    'es',
    'ar',
    'hi',
  };

  @override
  Set<String> getSupportedLanguages() => _supportedLanguages;

  @override
  Future<String> getSelectedLanguage() async {
    try {
      final savedLanguage = _localStorageProvider.getString(_languageKey);
      return savedLanguage ?? 'en';
    } catch (e) {
      dev.log(
        'Failed to load language preference',
        name: 'LanguageRepository',
        error: e,
      );
      return 'en';
    }
  }

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {
    try {
      await _localStorageProvider.setString(_languageKey, languageCode);
    } catch (e) {
      dev.log(
        'Failed to save language preference',
        name: 'LanguageRepository',
        error: e,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async =>
      _assetsProvider.loadTranslations(languageCode);
}
