/// Contract for loading bundled JSON assets.
abstract interface class IAssetsProvider {
  Future<List<Map<String, dynamic>>> loadProjectsData();
  Future<Map<String, dynamic>> loadTranslations(String languageCode);
}
