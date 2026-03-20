import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_local_storage_provider.dart';

/// Dark/light mode toggle — persists preference to localStorage.
class ThemeController extends GetxController {
  static const _storageKey = 'isDarkMode';

  final RxBool isDarkMode = true.obs;

  /// Current brightness derived from [isDarkMode].
  Brightness get brightness => isDarkMode.value ? Brightness.dark : Brightness.light;

  @override
  void onInit() {
    super.onInit();
    _loadSavedTheme();
  }

  void _loadSavedTheme() {
    try {
      if (Get.isRegistered<ILocalStorageProvider>()) {
        final storage = Get.find<ILocalStorageProvider>();
        if (storage.isInitialized) {
          final saved = storage.getBool(_storageKey);
          if (saved != null) {
            isDarkMode.value = saved;
          }
        }
      }
    } catch (e) {
      dev.log('Failed to load theme preference', name: 'ThemeController', error: e);
    }
  }

  /// Toggle between dark and light mode. Persists the choice.
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _persistTheme();
  }

  void _persistTheme() {
    try {
      if (Get.isRegistered<ILocalStorageProvider>()) {
        final storage = Get.find<ILocalStorageProvider>();
        if (storage.isInitialized) {
          storage.setBool(_storageKey, isDarkMode.value);
        }
      }
    } catch (e) {
      dev.log('Failed to persist theme preference', name: 'ThemeController', error: e);
    }
  }
}
