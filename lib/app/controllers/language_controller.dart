import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import '../domain/repositories/i_language_repository.dart';

class LanguageController extends GetxController {

  LanguageController({required ILanguageRepository languageRepository})
    : _languageRepository = languageRepository;
  final ILanguageRepository _languageRepository;

  final Rx<String> _currentLanguage = 'tr'.obs;
  String get currentLanguage => _currentLanguage.value;

  Locale get currentLocale => Locale(_currentLanguage.value);

  Map<String, String> get languageInfo => {
    'code': _currentLanguage.value,
    'name': getLanguageName(_currentLanguage.value),
    'flag': getLanguageFlag(_currentLanguage.value),
  };

  Map<String, String> get supportedLanguages =>
      _languageRepository.getSupportedLanguages();

  Map<String, dynamic> get cvData =>
      _languageRepository.getCVData(currentLanguage);

  String get appName => 'Portfolio';

  String getText(String key, {String defaultValue = ''}) => defaultValue;

  @override
  void onInit() {
    super.onInit();
    loadSavedLanguage();
  }

  Future<void> loadSavedLanguage() async {
    try {
      final savedLanguage = await _languageRepository.getSelectedLanguage();
      await changeLanguage(savedLanguage);
    } catch (e) {
      dev.log('Failed to load saved language', name: 'LanguageController', error: e);
      await changeLanguage('tr');
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (!supportedLanguages.containsKey(languageCode)) return;

    _currentLanguage.value = languageCode;
    Get.updateLocale(Locale(languageCode));
    await _languageRepository.saveSelectedLanguage(languageCode);
    await _updateTranslations(languageCode);
    update();
  }

  Future<void> _updateTranslations(String languageCode) async {
    try {
      await _languageRepository.getTranslations(languageCode);
    } catch (e) {
      dev.log('Failed to load translations', name: 'LanguageController', error: e);
    }
  }

  static String getLanguageName(String languageCode) => switch (languageCode) {
    'tr' => 'Turkce',
    'en' => 'English',
    'de' => 'Deutsch',
    'fr' => 'Francais',
    'es' => 'Espanol',
    _ => 'Unknown',
  };

  static String getLanguageFlag(String languageCode) => switch (languageCode) {
    'tr' => '\u{1F1F9}\u{1F1F7}',
    'en' => '\u{1F1EC}\u{1F1E7}',
    'de' => '\u{1F1E9}\u{1F1EA}',
    'fr' => '\u{1F1EB}\u{1F1F7}',
    'es' => '\u{1F1EA}\u{1F1F8}',
    _ => '\u{1F310}',
  };
}

/// Static translation helper
class KT {
  static String t(
    BuildContext context,
    String key,
    String defaultValue, {
    final String? fallbackKey,
    final Map<String, String>? translationParams,
  }) {
    try {
      final result = FlutterI18n.translate(
        context,
        key,
        fallbackKey: fallbackKey,
        translationParams: translationParams,
      );
      return result == key ? defaultValue : result;
    } catch (_) {
      return defaultValue;
    }
  }

  static Map<String, dynamic> mergeJson(
    Map<String, dynamic> json1,
    Map<String, dynamic> json2,
  ) {
    final merged = Map<String, dynamic>.from(json1);

    json2.forEach((key, value) {
      if (merged.containsKey(key) && merged[key] is Map && value is Map) {
        merged[key] = mergeJson(merged[key], value as Map<String, dynamic>);
      } else {
        merged[key] = value;
      }
    });

    return merged;
  }
}
