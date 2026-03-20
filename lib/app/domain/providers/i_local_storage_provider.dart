/// Contract for persistent key-value storage.
abstract interface class ILocalStorageProvider {
  bool get isInitialized;
  String? getString(String key);
  Future<bool> setString(String key, String value);
  bool? getBool(String key);
  Future<bool> setBool(String key, bool value);
  int? getInt(String key);
  Future<bool> setInt(String key, int value);
  Future<bool> remove(String key);
  Future<bool> clear();
}
