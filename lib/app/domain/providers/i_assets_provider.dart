/// Contract for loading bundled JSON assets.
abstract interface class IAssetsProvider {
  Future<Map<String, dynamic>> loadTranslations(String languageCode);
}
