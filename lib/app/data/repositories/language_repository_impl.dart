import '../../domain/repositories/i_language_repository.dart';
import '../providers/assets_provider.dart';
import '../providers/local_storage_provider.dart';
import 'package:flutter/foundation.dart';

/// ILanguageRepository implementasyonu
class LanguageRepositoryImpl implements ILanguageRepository {
  final AssetsProvider _assetsProvider;
  final LocalStorageProvider _localStorageProvider;

  // Dil ayarı için storage anahtarı
  static const String languageKey = 'selected_language';

  // Desteklenen diller ve bayrakları
  static const Map<String, String> supportedLanguages = {
    'tr': '🇹🇷',
    'en': '🇬🇧',
    'de': '🇩🇪',
    'fr': '🇫🇷',
    'es': '🇪🇸',
  };

  LanguageRepositoryImpl({
    required AssetsProvider assetsProvider,
    required LocalStorageProvider localStorageProvider,
  }) : _assetsProvider = assetsProvider,
       _localStorageProvider = localStorageProvider;

  @override
  Map<String, String> getSupportedLanguages() {
    return supportedLanguages;
  }

  @override
  Future<String> getSelectedLanguage() async {
    try {
      // Kayıtlı dil tercihini al, yoksa varsayılan olarak Türkçe
      final savedLanguage = _localStorageProvider.getString(languageKey);
      return savedLanguage ?? 'tr';
    } catch (e) {
      debugPrint('⚠️ Dil tercihi yüklenirken hata: $e');
      return 'tr'; // Hata durumunda varsayılan dil
    }
  }

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {
    try {
      await _localStorageProvider.setString(languageKey, languageCode);
    } catch (e) {
      debugPrint('⚠️ Dil tercihi kaydedilirken hata: $e');
      // Hata durumunda sessizce devam et
    }
  }

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async {
    return await _assetsProvider.loadTranslations(languageCode);
  }

  @override
  Map<String, dynamic> getCVData(String languageCode) {
    // CV verilerini dil koduna göre döndür
    // Gerçek uygulamada bu veriler assetlerden veya API'dan yüklenebilir
    // Şimdilik basit bir mock veri dönüyoruz

    // Mock CV verileri (Örnek)
    final Map<String, dynamic> mockData = {
      'skills': [
        {'name': 'Flutter', 'level': 90, 'category': 'Mobile'},
        {'name': 'Dart', 'level': 85, 'category': 'Programming'},
        {'name': 'React', 'level': 80, 'category': 'Web'},
        {'name': 'Node.js', 'level': 75, 'category': 'Backend'},
      ],
      'experience': [
        {
          'company': 'ABC Tech',
          'position': 'Senior Developer',
          'period': '2020-2023',
          'description': 'Mobil uygulama geliştirme',
        },
        {
          'company': 'XYZ Software',
          'position': 'Developer',
          'period': '2018-2020',
          'description': 'Web uygulamaları geliştirme',
        },
      ],
      'projects': [
        {
          'name': 'E-Commerce App',
          'description': 'Flutter ile geliştirilmiş e-ticaret uygulaması',
          'technologies': ['Flutter', 'Firebase', 'GetX'],
        },
        {
          'name': 'Portfolio Website',
          'description': 'Kişisel portföy web sitesi',
          'technologies': ['React', 'Next.js', 'Tailwind CSS'],
        },
      ],
      'education': [
        {
          'institution': 'ABC Üniversitesi',
          'degree': 'Bilgisayar Mühendisliği',
          'period': '2014-2018',
        },
      ],
      'languages': [
        {'name': 'Türkçe', 'level': 'Ana dil'},
        {'name': 'İngilizce', 'level': 'İleri Seviye'},
        {'name': 'Almanca', 'level': 'Orta Seviye'},
      ],
    };

    return mockData;
  }
}
