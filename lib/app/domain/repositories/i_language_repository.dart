/// Contract for language data access — translations and preferences.
abstract interface class ILanguageRepository {
  Set<String> getSupportedLanguages();
  Future<String> getSelectedLanguage();
  Future<void> saveSelectedLanguage(String languageCode);
  Future<Map<String, dynamic>> getTranslations(String languageCode);
}
