import 'dart:developer' as dev;

import 'package:flutter_web_portfolio/app/domain/providers/key_value_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed storage for the public preference surface.
final class PreferenceStore implements KeyValueStore {
  PreferenceStore._(this._preferences);

  static Future<PreferenceStore> open() async {
    try {
      return PreferenceStore._(await SharedPreferences.getInstance());
    } on Object catch (error) {
      dev.log(
        'SharedPreferences initialization failed',
        name: 'PreferenceStore',
        error: error,
      );
      return PreferenceStore._(null);
    }
  }

  final SharedPreferences? _preferences;

  @override
  String? readString(String key) => _preferences?.getString(key);

  @override
  Future<void> writeString(String key, String value) async {
    final preferences = _preferences;
    if (preferences == null) {
      throw StateError('SharedPreferences is unavailable for $key.');
    }
    final persisted = await preferences.setString(key, value);
    if (!persisted) {
      throw StateError('SharedPreferences rejected the write for $key.');
    }
  }
}
