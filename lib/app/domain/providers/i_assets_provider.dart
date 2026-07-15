/// Contract for loading bundled JSON assets.
abstract interface class IAssetsProvider {
  Future<Map<String, dynamic>> loadTranslations(String languageCode);

  Future<Map<String, dynamic>> loadPortfolio();

  Future<Map<String, dynamic>> loadNarrative();
}
