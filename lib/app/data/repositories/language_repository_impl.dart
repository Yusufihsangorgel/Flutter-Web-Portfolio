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
  Map<String, dynamic> getCVData(String languageCode) {
    // TODO: Load from assets/data/cv_{languageCode}.json
    return {
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
          'description': 'Mobile application development',
        },
        {
          'company': 'XYZ Software',
          'position': 'Developer',
          'period': '2018-2020',
          'description': 'Web application development',
        },
      ],
      'projects': [
        {
          'name': 'E-Commerce App',
          'description': 'E-commerce application built with Flutter',
          'technologies': ['Flutter', 'Firebase', 'GetX'],
        },
        {
          'name': 'Portfolio Website',
          'description': 'Personal portfolio website',
          'technologies': ['React', 'Next.js', 'Tailwind CSS'],
        },
      ],
      'education': [
        {
          'institution': 'ABC University',
          'degree': 'Computer Engineering',
          'period': '2014-2018',
        },
      ],
      'languages': [
        {'name': 'Turkish', 'level': 'Native'},
        {'name': 'English', 'level': 'Advanced'},
        {'name': 'German', 'level': 'Intermediate'},
      ],
    };
  }
}
