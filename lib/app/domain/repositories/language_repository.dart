/// Language catalog and persisted locale selection used by the application.
abstract interface class LanguageRepository {
  Set<String> get supportedLanguages;
  Future<String> getSelectedLanguage();
  Future<void> saveSelectedLanguage(String languageCode);
  Future<Map<String, dynamic>> getTranslations(String languageCode);
}
