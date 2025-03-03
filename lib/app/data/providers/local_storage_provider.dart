import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Yerel depolama işlemleri için provider
class LocalStorageProvider extends GetxService {
  SharedPreferences? _prefs;
  bool get isInitialized => _prefs != null;

  /// Provider'ı başlatır ve SharedPreferences instance'ını oluşturur
  Future<LocalStorageProvider> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('❌ SharedPreferences initialization error: $e');
    }
    return this;
  }

  /// String veri okur
  String? getString(String key) {
    return _prefs?.getString(key);
  }

  /// String veri yazar
  Future<bool> setString(String key, String value) {
    if (_prefs == null) return Future.value(false);
    return _prefs!.setString(key, value);
  }

  /// Bool veri okur
  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  /// Bool veri yazar
  Future<bool> setBool(String key, bool value) {
    if (_prefs == null) return Future.value(false);
    return _prefs!.setBool(key, value);
  }

  /// Int veri okur
  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  /// Int veri yazar
  Future<bool> setInt(String key, int value) {
    if (_prefs == null) return Future.value(false);
    return _prefs!.setInt(key, value);
  }

  /// Belirli bir anahtarı siler
  Future<bool> remove(String key) {
    if (_prefs == null) return Future.value(false);
    return _prefs!.remove(key);
  }

  /// Tüm verileri temizler
  Future<bool> clear() {
    if (_prefs == null) return Future.value(false);
    return _prefs!.clear();
  }
}
