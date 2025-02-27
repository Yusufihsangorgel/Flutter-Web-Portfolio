import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  final Map<String, String> _localizedStrings = {};
  Map<String, dynamic> _cvData = {};

  Future<bool> load() async {
    // Load the language JSON file from the "assets/data" folder
    String jsonString = await rootBundle.loadString(
      'assets/data/cv_data_${locale.languageCode}.json',
    );
    _cvData = json.decode(jsonString);

    return true;
  }

  // Helper method to keep the code in the widget concise
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Get CV data
  Map<String, dynamic> get cvData => _cvData;

  // Getters for different sections of CV data
  Map<String, dynamic> get personalInfo => _cvData['personal_info'] ?? {};
  List<dynamic> get experiences => _cvData['experiences'] ?? [];
  List<dynamic> get projects => _cvData['projects'] ?? [];
  List<dynamic> get education => _cvData['education'] ?? [];
  List<dynamic> get skills => _cvData['skills'] ?? [];
  List<dynamic> get references => _cvData['references'] ?? [];
  List<dynamic> get languages => _cvData['languages'] ?? [];
  Map<String, dynamic> get contact => _cvData['contact'] ?? {};
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'tr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Extension to get app localization from context
extension LocalizationExtension on BuildContext {
  AppLocalizations get locale => AppLocalizations.of(this);
}
