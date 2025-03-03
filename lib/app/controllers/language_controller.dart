import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter/material.dart';
import '../domain/repositories/i_language_repository.dart';

/// Uygulama içi dil değişimi ve çevirileri yöneten controller
class LanguageController extends GetxController {
  final ILanguageRepository _languageRepository;

  // Mevcut seçili dil kodu (tr, en, de, vb.)
  final Rx<String> _currentLanguage = 'tr'.obs;
  String get currentLanguage => _currentLanguage.value;

  // Mevcut Locale
  Locale get currentLocale => Locale(_currentLanguage.value);

  // Mevcut dil bilgisi (bayrak ve isim)
  Map<String, String> get languageInfo => {
    'code': _currentLanguage.value,
    'name': getLanguageName(_currentLanguage.value),
    'flag': getLanguageFlag(_currentLanguage.value),
  };

  // Dil seçenekleri
  Map<String, String> get supportedLanguages =>
      _languageRepository.getSupportedLanguages();

  // CV verileri - projeler, deneyimler, yetenekler vb.
  // Bu veri, JSON formatında veya Map olarak CV içeriğini döndürür
  Map<String, dynamic> get cvData =>
      _languageRepository.getCVData(currentLanguage);

  // Uygulama adı
  String get appName => getText('app.name', defaultValue: 'Portfolio');

  LanguageController({required ILanguageRepository languageRepository})
    : _languageRepository = languageRepository;

  @override
  void onInit() {
    super.onInit();
    loadSavedLanguage();
  }

  /// Kayıtlı dil tercihini yükler
  Future<void> loadSavedLanguage() async {
    try {
      final savedLanguage = await _languageRepository.getSelectedLanguage();
      changeLanguage(savedLanguage);
    } catch (e) {
      debugPrint('⚠️ Dil yüklenirken hata: $e');
      // Hata durumunda varsayılan dili kullan
      changeLanguage('tr');
    }
  }

  /// Dili değiştirir
  Future<void> changeLanguage(String languageCode) async {
    if (!supportedLanguages.containsKey(languageCode)) {
      return;
    }

    _currentLanguage.value = languageCode;
    Get.updateLocale(Locale(languageCode));
    await _languageRepository.saveSelectedLanguage(languageCode);

    // Çevirileri güncelle
    await _updateTranslations(languageCode);

    update(); // UI'ı güncelle
  }

  /// Çevirileri yükler ve günceller
  Future<void> _updateTranslations(String languageCode) async {
    try {
      final translations = await _languageRepository.getTranslations(
        languageCode,
      );
      // Burada çevirileri global bir şekilde saklayabilir veya GetX translations sistemine ekleyebilirsiniz
    } catch (e) {
      print('Çeviriler yüklenirken hata: $e');
    }
  }

  /// Belirli bir dil için çeviri metnini döndürür
  String getText(String key, {String defaultValue = ''}) {
    // Burada GetX translations sistemini veya kendi sistemimizi kullanabiliriz
    // Basitlik için şimdilik default değeri döndürüyoruz
    // Gerçek uygulamada: return Get.find<TranslationService>().translate(key, defaultValue: defaultValue);
    return defaultValue;
  }

  /// Belirli bir dil kodu için dil adını döndürür
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      default:
        return 'Unknown';
    }
  }

  /// Belirli bir dil kodu için bayrak emojisini döndürür
  static String getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return '🇹🇷';
      case 'en':
        return '🇬🇧';
      case 'de':
        return '🇩🇪';
      case 'fr':
        return '🇫🇷';
      case 'es':
        return '🇪🇸';
      default:
        return '🌐';
    }
  }
}

/// Statik çeviri yardımcı sınıfı
class KT {
  static String t(
    BuildContext context,
    String key,
    String defaultValue, {
    final String? fallbackKey,
    final Map<String, String>? translationParams,
  }) {
    try {
      var q = FlutterI18n.translate(
        context,
        key,
        fallbackKey: fallbackKey,
        translationParams: translationParams,
      );
      if (q == key) {
        return defaultValue;
      }
      return q;
    } catch (e) {
      return defaultValue;
    }
  }

  static Map<String, dynamic> mergeJson(
    Map<String, dynamic> json1,
    Map<String, dynamic> json2,
  ) {
    Map<String, dynamic> merged = Map.from(json1);

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
