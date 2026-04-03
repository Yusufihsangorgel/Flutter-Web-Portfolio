import 'dart:developer' as dev;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_local_storage_provider.dart';

/// Thin SharedPreferences wrapper — async init, typed get/set.
final class LocalStorageProvider implements ILocalStorageProvider {
  SharedPreferences? _prefs;

  @override
  bool get isInitialized => _prefs != null;

  Future<LocalStorageProvider> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      dev.log('SharedPreferences init failed', name: 'LocalStorage', error: e);
    }
    return this;
  }

  @override
  String? getString(String key) => _prefs?.getString(key);

  @override
  Future<bool> setString(String key, String value) {
    if (_prefs == null) return Future.value(false);
    return _prefs!.setString(key, value);
  }

  @override
  bool? getBool(String key) => _prefs?.getBool(key);

  @override
  Future<bool> setBool(String key, bool value) {
    if (_prefs == null) return Future.value(false);
    return _prefs!.setBool(key, value);
  }

  @override
  int? getInt(String key) => _prefs?.getInt(key);

  @override
  Future<bool> setInt(String key, int value) {
    if (_prefs == null) return Future.value(false);
    return _prefs!.setInt(key, value);
  }

  @override
  Future<bool> remove(String key) {
    if (_prefs == null) return Future.value(false);
    return _prefs!.remove(key);
  }

  @override
  Future<bool> clear() {
    if (_prefs == null) return Future.value(false);
    return _prefs!.clear();
  }
}
