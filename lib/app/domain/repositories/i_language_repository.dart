abstract interface class ILanguageRepository {
  Map<String, String> getSupportedLanguages();
  Future<String> getSelectedLanguage();
  Future<void> saveSelectedLanguage(String languageCode);
  Future<Map<String, dynamic>> getTranslations(String languageCode);
  Map<String, dynamic> getCVData(String languageCode);
}
