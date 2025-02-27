import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

/// Uygulama dilini ve çevirileri yöneten controller sınıfı
class LanguageController extends GetxController {
  static const String languageKey = 'language';

  // Desteklenen diller - assets/i18n klasöründeki dil dosyalarına göre
  static final Map<String, Locale> supportedLanguages = {
    'tr': const Locale('tr', ''), // Türkçe
    'en': const Locale('en', ''), // İngilizce
    'de': const Locale('de', ''), // Almanca
    'fr': const Locale('fr', ''), // Fransızca
    'hi': const Locale('hi', ''), // Hintçe
    'ar': const Locale('ar', ''), // Arapça
  };

  // Font aileleri - tüm diller için aynı
  static final Map<String, TextStyle> supportedLanguagesFonts = {
    'tr': const TextStyle(fontFamily: 'Poppins'),
    'en': const TextStyle(fontFamily: 'Poppins'),
    'de': const TextStyle(fontFamily: 'Poppins'),
    'fr': const TextStyle(fontFamily: 'Poppins'),
    'hi': const TextStyle(fontFamily: 'Poppins'),
    'ar': const TextStyle(fontFamily: 'Poppins'),
  };

  // Dil durumu
  final RxString _currentLanguage = 'tr'.obs;

  // Dil verileri
  final Rx<Map<String, dynamic>> _languageData = Rx<Map<String, dynamic>>({});

  // Çeviriler
  final Rx<Map<String, String>> _translations = Rx<Map<String, String>>({});

  // Getter'lar
  String get currentLanguage => _currentLanguage.value;
  Locale get currentLocale =>
      supportedLanguages[currentLanguage] ?? const Locale('tr', '');
  Map<String, dynamic> get languageData => _languageData.value;
  Map<String, dynamic> get cvData =>
      _languageData.value.containsKey('cv_data')
          ? _languageData.value['cv_data']
          : {};

  // Dil bilgisi
  Map<String, dynamic> get languageInfo =>
      _languageData.value.containsKey('language_info')
          ? _languageData.value['language_info']
          : {
            'code': 'tr',
            'name': 'Türkçe',
            'flag': '🇹🇷',
            'direction': 'ltr',
          };

  // Yazım yönü (RTL desteği için)
  String get textDirection =>
      languageInfo['direction'] == 'rtl' ? 'rtl' : 'ltr';
  bool get isRtl => textDirection == 'rtl';

  // Uygulama adı
  String get appName {
    try {
      return _languageData.value['app_name'] ?? 'Portfolio';
    } catch (e) {
      return 'Portfolio';
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadSavedLanguage();
  }

  // Kaydedilmiş dili yükle
  Future<void> loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(languageKey) ?? 'tr';

      // Sadece desteklenen dilleri kabul et
      if (supportedLanguages.containsKey(savedLanguage)) {
        _currentLanguage.value = savedLanguage;
      } else {
        _currentLanguage.value = 'tr'; // Varsayılan dil
      }

      await _loadLanguageData(); // Dil yüklendikten sonra kaynakları yükle
      update();
    } catch (e) {
      _currentLanguage.value = 'tr';
      await _loadLanguageData();
      update();
    }
  }

  // Dil verilerini yükle
  Future<void> _loadLanguageData() async {
    try {
      String jsonString = await rootBundle.loadString(
        'assets/i18n/${_currentLanguage.value}.json',
      );
      _languageData.value = json.decode(jsonString);
      _loadTranslations();
    } catch (e) {
      printError(info: 'Language data load error: ${e.toString()}');
      // Hata durumunda minimum veri
      _languageData.value = {
        'app_name': 'Portfolio',
        'translations': {'portfolio_loading': 'Loading...'},
        'language_info': {
          'code': _currentLanguage.value,
          'name': getLanguageName(_currentLanguage.value),
          'flag': getLanguageFlag(_currentLanguage.value),
          'direction': _currentLanguage.value == 'ar' ? 'rtl' : 'ltr',
        },
      };
      _loadTranslations();
    }
  }

  // Çevirileri yükle
  void _loadTranslations() {
    try {
      if (_languageData.value.containsKey('translations')) {
        final Map<String, dynamic> rawTranslations =
            _languageData.value['translations'];

        // Dynamic map'i string map'e çevir
        final Map<String, String> translationsMap = {};
        rawTranslations.forEach((key, value) {
          if (value is String) {
            translationsMap[key] = value;
          }
        });

        _translations.value = translationsMap;
      } else {
        // Çeviriler yoksa minimum çeviriler
        _translations.value = {
          'app_name': appName,
          'portfolio_loading': 'Loading...',
        };
      }
    } catch (e) {
      printError(info: 'Translations load error: ${e.toString()}');

      // Hata durumunda minimum çeviriler
      _translations.value = {
        'app_name': 'Portfolio',
        'portfolio_loading': 'Loading...',
      };
    }
  }

  // Dili değiştir
  Future<void> changeLanguage(String languageCode) async {
    if (!supportedLanguages.containsKey(languageCode)) return;

    _currentLanguage.value = languageCode;
    await _loadLanguageData(); // Dil değiştiğinde kaynakları yeniden yükle

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(languageKey, languageCode);

      // GetX lokal güncelleme
      await Get.updateLocale(supportedLanguages[languageCode]!);
    } catch (e) {
      printError(info: 'Language save error: ${e.toString()}');
    }

    update();
  }

  // Metni getir
  String getText(
    String key, {
    String defaultValue = '',
    Map<String, String>? params,
  }) {
    // Context varsa ve FlutterI18n kullanılabilirse, onu kullan
    if (Get.context != null) {
      try {
        final context = Get.context!;
        final translation = FlutterI18n.translate(
          context,
          key,
          translationParams: params,
        );
        if (translation != key) {
          return translation;
        }
      } catch (e) {
        // FlutterI18n hata verirse, yerel dosyalara bak
        printError(info: 'FlutterI18n error: ${e.toString()}');
      }
    }

    // Yerel dosyalar üzerinden çeviri dene
    try {
      // JSON dosyadaki veri yapısını izle - noktalı anahtar yolunu parçala
      List<String> keyParts = key.split('.');
      dynamic value = _languageData.value;

      for (String part in keyParts) {
        if (value is Map && value.containsKey(part)) {
          value = value[part];
        } else {
          value = null;
          break;
        }
      }

      if (value != null && value is String) {
        return value;
      }
    } catch (e) {
      printError(info: 'Local translation error: ${e.toString()}');
    }

    // Hiçbir yerde bulunamadıysa varsayılan değeri veya anahtarın kendisini döndür
    return defaultValue.isNotEmpty ? defaultValue : key;
  }

  // Desteklenen tüm dilleri getir
  Future<List<Map<String, dynamic>>> getSupportedLanguages() async {
    List<Map<String, dynamic>> languages = [];

    for (String locale in supportedLanguages.keys) {
      try {
        // Her dil için dil bilgilerini yükle
        String jsonString = await rootBundle.loadString(
          'assets/i18n/$locale.json',
        );
        Map<String, dynamic> data = json.decode(jsonString);

        if (data.containsKey('language_info')) {
          languages.add(data['language_info']);
        } else {
          // Dil bilgisi yoksa varsayılan bilgileri ekle
          Map<String, dynamic> defaultInfo = {
            'code': locale,
            'name': getLanguageName(locale),
            'flag': getLanguageFlag(locale),
            'direction': locale == 'ar' ? 'rtl' : 'ltr',
          };
          languages.add(defaultInfo);
        }
      } catch (e) {
        // Hata durumunda varsayılan bilgileri ekle
        Map<String, dynamic> defaultInfo = {
          'code': locale,
          'name': getLanguageName(locale),
          'flag': getLanguageFlag(locale),
          'direction': locale == 'ar' ? 'rtl' : 'ltr',
        };
        languages.add(defaultInfo);
      }
    }

    return languages;
  }

  // Dil adı yardımcı metodu
  static String getLanguageName(String code) {
    switch (code) {
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      case 'fr':
        return 'Français';
      case 'hi':
        return 'हिन्दी';
      case 'ar':
        return 'العربية';
      default:
        return code;
    }
  }

  // Dil bayrağı yardımcı metodu
  static String getLanguageFlag(String code) {
    switch (code) {
      case 'tr':
        return '🇹🇷';
      case 'en':
        return '🇬🇧';
      case 'de':
        return '🇩🇪';
      case 'fr':
        return '🇫🇷';
      case 'hi':
        return '🇮🇳';
      case 'ar':
        return '🇸🇦';
      default:
        return '🏳️';
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
