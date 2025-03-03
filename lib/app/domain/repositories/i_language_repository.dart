/// Dil verilerine erişim için repository interface
abstract class ILanguageRepository {
  /// Desteklenen dilleri getirir
  Map<String, String> getSupportedLanguages();

  /// Seçili dili getirir
  Future<String> getSelectedLanguage();

  /// Seçili dili kaydeder
  Future<void> saveSelectedLanguage(String languageCode);

  /// Belirli bir dil için çeviri metinlerini getirir
  Future<Map<String, dynamic>> getTranslations(String languageCode);

  /// Belirli bir dil için CV verilerini getirir
  Map<String, dynamic> getCVData(String languageCode);
}
