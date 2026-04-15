import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/i_language_repository.dart';
import 'package:flutter_web_portfolio/app/utils/web_url_strategy.dart'
    as url_strategy;

/// Reactive language state — loads i18n JSON, exposes getText() and cvData.
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

  // Full loaded JSON for current language — reactive via Rx wrapper
  final _translations = Rx<Map<String, dynamic>>({});

  Map<String, dynamic> get cvData => switch (_translations.value['cv_data']) {
    final Map<String, dynamic> data => data,
    _ => const <String, dynamic>{},
  };

  String get appName =>
      _translations.value['app_name']?.toString() ?? 'Portfolio';

  /// Sections that have data in the current language JSON.
  /// Sections without data are hidden from the UI, nav, and scroll dots.
  List<String> get activeSections {
    final data = cvData;
    return [
      'home',
      if (data['personal_info'] is Map) 'about',
      if (data['experiences'] case final List l when l.isNotEmpty) 'experience',
      if (data['testimonials'] case final List l when l.isNotEmpty) 'testimonials',
      if (_hasMediumUsername(data)) 'blog',
      if (data['projects'] case final List l when l.isNotEmpty) 'projects',
      'contact',
    ];
  }

  static bool _hasMediumUsername(Map<String, dynamic> data) {
    final info = data['personal_info'];
    if (info is! Map<String, dynamic>) return false;
    final medium = info['medium'];
    return medium is String && medium.isNotEmpty;
  }

  /// Looks up a dot-separated key in the loaded JSON.
  /// Falls back to [defaultValue] if not found.
  String getText(String key, {String defaultValue = ''}) {
    final parts = key.split('.');
    dynamic current = _translations.value;
    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return defaultValue;
      }
    }
    return current?.toString() ?? defaultValue;
  }

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
    unawaited(Get.updateLocale(Locale(languageCode)));
    url_strategy.setHtmlLang(languageCode);
    await _languageRepository.saveSelectedLanguage(languageCode);
    await _updateTranslations(languageCode);
  }

  Future<void> _updateTranslations(String languageCode) async {
    try {
      final data = await _languageRepository.getTranslations(languageCode);
      _translations.value = data;
    } catch (e) {
      dev.log('Failed to load translations', name: 'LanguageController', error: e);
    }
  }

  static const _languageData = <String, (String name, String flag)>{
    'tr': ('T\u00FCrk\u00E7e', '\u{1F1F9}\u{1F1F7}'),
    'en': ('English', '\u{1F1EC}\u{1F1E7}'),
    'de': ('Deutsch', '\u{1F1E9}\u{1F1EA}'),
    'fr': ('Fran\u00E7ais', '\u{1F1EB}\u{1F1F7}'),
    'es': ('Espa\u00F1ol', '\u{1F1EA}\u{1F1F8}'),
    'ar': ('\u0627\u0644\u0639\u0631\u0628\u064A\u0629', '\u{1F1F8}\u{1F1E6}'),
    'hi': ('\u0939\u093F\u0928\u094D\u0926\u0940', '\u{1F1EE}\u{1F1F3}'),
  };

  static String getLanguageName(String languageCode) =>
      _languageData[languageCode]?.$1 ?? 'Unknown';

  static String getLanguageFlag(String languageCode) =>
      _languageData[languageCode]?.$2 ?? '\u{1F310}';
}

/// Static translation helper for FlutterI18n lookups.
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
    } catch (e) {
      dev.log('FlutterI18n lookup failed for $key', name: 'KT', error: e);
      return defaultValue;
    }
  }

  static Map<String, dynamic> mergeJson(
    Map<String, dynamic> json1,
    Map<String, dynamic> json2,
  ) {
    final merged = Map<String, dynamic>.from(json1);

    json2.forEach((key, value) {
      if (merged[key] case final Map<String, dynamic> existing
          when value is Map<String, dynamic>) {
        merged[key] = mergeJson(existing, value);
      } else {
        merged[key] = value;
      }
    });

    return merged;
  }
}
