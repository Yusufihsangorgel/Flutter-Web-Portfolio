import 'dart:developer' as dev;

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageProvider extends GetxService {
  SharedPreferences? _prefs;
  bool get isInitialized => _prefs != null;

  Future<LocalStorageProvider> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      dev.log('SharedPreferences init failed', name: 'LocalStorage', error: e);
    }
    return this;
  }

  String? getString(String key) => _prefs?.getString(key);

  Future<bool> setString(String key, String value) {
    if (_prefs == null) return Future.value(false);
    return _prefs!.setString(key, value);
  }

  bool? getBool(String key) => _prefs?.getBool(key);

  Future<bool> setBool(String key, bool value) {
    if (_prefs == null) return Future.value(false);
    return _prefs!.setBool(key, value);
  }

  int? getInt(String key) => _prefs?.getInt(key);

  Future<bool> setInt(String key, int value) {
    if (_prefs == null) return Future.value(false);
    return _prefs!.setInt(key, value);
  }

  Future<bool> remove(String key) {
    if (_prefs == null) return Future.value(false);
    return _prefs!.remove(key);
  }

  Future<bool> clear() {
    if (_prefs == null) return Future.value(false);
    return _prefs!.clear();
  }
}
