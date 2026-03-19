import 'dart:developer' as dev;

import '../../domain/repositories/i_language_repository.dart';
import '../providers/assets_provider.dart';
import '../providers/local_storage_provider.dart';

class LanguageRepositoryImpl implements ILanguageRepository {

  LanguageRepositoryImpl({
    required AssetsProvider assetsProvider,
    required LocalStorageProvider localStorageProvider,
  }) : _assetsProvider = assetsProvider,
       _localStorageProvider = localStorageProvider;
  final AssetsProvider _assetsProvider;
  final LocalStorageProvider _localStorageProvider;

  static const String _languageKey = 'selected_language';

  static const Map<String, String> _supportedLanguages = {
    'tr': '\u{1F1F9}\u{1F1F7}',
    'en': '\u{1F1EC}\u{1F1E7}',
    'de': '\u{1F1E9}\u{1F1EA}',
    'fr': '\u{1F1EB}\u{1F1F7}',
    'es': '\u{1F1EA}\u{1F1F8}',
  };

  @override
  Map<String, String> getSupportedLanguages() => _supportedLanguages;

  @override
  Future<String> getSelectedLanguage() async {
    try {
      final savedLanguage = _localStorageProvider.getString(_languageKey);
      return savedLanguage ?? 'tr';
    } catch (e) {
      dev.log('Failed to load language preference', name: 'LanguageRepository', error: e);
      return 'tr';
    }
  }

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {
    try {
      await _localStorageProvider.setString(_languageKey, languageCode);
    } catch (e) {
      dev.log('Failed to save language preference', name: 'LanguageRepository', error: e);
    }
  }

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async => _assetsProvider.loadTranslations(languageCode);

  @override
  Map<String, dynamic> getCVData(String languageCode) => {
    'personal_info': {
      'name': 'Yusuf Ihsan Gorgel',
      'title': 'Software Engineer',
      'phone': '+90 544 953 0128',
      'email': 'developeryusuf@icloud.com',
      'github': 'https://github.com/Yusufihsangorgel',
      'linkedin': 'https://linkedin.com/in/yusuf-ihsan-görgel/',
      'location': 'Antalya, Turkey (Remote)',
      'bio': 'Software Engineer with 4+ years of experience specializing in Flutter cross-platform development, backend systems with Node.js and Go, and DevOps with AWS. Experienced in ERP, POS, and mobile publishing platforms. Passionate about clean architecture, SOLID principles, and building scalable applications.',
    },
    'experiences': [
      {
        'company': 'Junius Tech',
        'position': 'Full Stack Developer',
        'position_tr': 'Full Stack Gelistirici',
        'start_date': 'Jun 2023',
        'end_date': 'Feb 2025',
        'description': 'Led mobile development team on the Dorse logistics platform. Built Flutter apps deployed across Android, iOS, and web. Handled frontend, backend coordination, deployment pipelines, and QA processes.',
        'description_tr': 'Dorse lojistik platformunda mobil gelistirme ekibine liderlik ettim. Flutter ile Android, iOS ve web uygulamalari gelistirdim.',
        'technologies': ['Flutter', 'React', 'Node.js', 'WebSocket', 'REST API', 'Google Maps'],
      },
      {
        'company': 'Uzman Adres',
        'position': 'Flutter Developer',
        'position_tr': 'Flutter Gelistirici',
        'start_date': 'Mar 2022',
        'end_date': 'Oct 2024',
        'description': 'Developed FugaSoft POS and sales management system with Flutter. Built complex SQL architectures, real-time socket communication, and barcode scanning. Deployed on Android/iOS tablets and desktop (Linux, macOS, Windows).',
        'description_tr': 'FugaSoft POS ve satis yonetim sistemini Flutter ile gelistirdim. Karmasik SQL mimarileri ve gercek zamanli soket iletisimi kurdum.',
        'technologies': ['Flutter', 'SQLite', 'Drift', 'GetX', 'Socket.IO', 'MSSQL'],
      },
      {
        'company': 'Promob TR',
        'position': 'Flutter Developer (Freelance)',
        'position_tr': 'Flutter Gelistirici (Serbest)',
        'start_date': 'Oct 2022',
        'end_date': 'Jun 2024',
        'description': 'Built Aydinlik E-Newspaper and Bilim ve Utopya E-Magazine mobile apps. Implemented MVVM architecture with GetX state management and Dio networking. Published on Google Play and App Store.',
        'description_tr': 'Aydinlik E-Gazete ve Bilim ve Utopya E-Dergi mobil uygulamalarini gelistirdim. Google Play ve App Store\'da yayinladim.',
        'technologies': ['Flutter', 'GetX', 'Dio', 'MVVM', 'PHP', 'Laravel'],
      },
    ],
    'projects': [
      {
        'title': 'FugaSoft',
        'description': 'Cross-platform POS & Sales Management system. SQLite-Drift local DB, reactive programming with Mediator Pattern, i18n localization. Runs on Android/iOS tablets and desktop.',
        'technologies': ['Flutter', 'SQLite', 'Drift', 'GetX'],
        'url': 'https://fugasoft.com/',
      },
      {
        'title': 'Dorse App',
        'description': 'Logistics platform with mobile app and website. Google/Apple Maps integration, real-time WebSocket tracking, RESTful API architecture.',
        'technologies': ['Flutter', 'React', 'WebSocket', 'Maps API'],
        'url': {'website': 'https://dorseapp.com/', 'google_play': 'https://play.google.com/store/apps/details?id=com.juniustech.dorse'},
      },
      {
        'title': 'Aydinlik E-Newspaper',
        'description': 'Digital newspaper app with MVVM architecture, offline reading, and push notifications. Published on both app stores.',
        'technologies': ['Flutter', 'GetX', 'Dio', 'MVVM'],
        'url': {'google_play': 'https://play.google.com/store/apps/details?id=com.aydinlikgazetesi.egazete'},
      },
      {
        'title': 'Bilim ve Utopya E-Magazine',
        'description': 'Science magazine digital reading app with subscription management and content caching.',
        'technologies': ['Flutter', 'GetX', 'Dio', 'MVVM'],
        'url': {'google_play': 'https://play.google.com/store/apps/details?id=com.aydinlikgazetesi.edergi_v1_bvu'},
      },
    ],
    'skills': [
      {
        'category': 'Mobile',
        'items': ['Flutter', 'Dart', 'Swift', 'SwiftUI', 'GetX', 'BLoC', 'Provider'],
      },
      {
        'category': 'Backend',
        'items': ['Node.js', 'Express.js', 'Go', 'Spring Boot', 'MongoDB', 'MSSQL', 'SQLite'],
      },
      {
        'category': 'Frontend',
        'items': ['React', 'JavaScript', 'TypeScript', 'HTML', 'CSS'],
      },
      {
        'category': 'DevOps',
        'items': ['AWS', 'Docker', 'Git', 'CI/CD', 'Firebase'],
      },
    ],
    'education': [
      {
        'school': 'Mehmet Akif Ersoy University',
        'degree': 'Software Engineering',
        'period': '2021 - 2025',
      },
      {
        'school': 'Dursun Yalim Science High School',
        'degree': 'Science',
        'period': '2015 - 2020',
      },
    ],
    'languages': [
      {'name': 'Turkish', 'level': 'Native'},
      {'name': 'English', 'level': 'B2'},
    ],
  };
}
