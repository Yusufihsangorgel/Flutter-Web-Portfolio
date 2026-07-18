/// Loads the structured documents owned by the application bundle.
abstract interface class AssetLoader {
  Future<Map<String, dynamic>> loadTranslations(String languageCode);

  Future<Map<String, dynamic>> loadPortfolio();

  Future<Map<String, dynamic>> loadNarrative();
}
