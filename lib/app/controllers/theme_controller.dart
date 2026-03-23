import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_local_storage_provider.dart';

/// Dark/light mode toggle — persists preference to localStorage.
/// Auto-detects system theme on first visit; respects manual override.
class ThemeController extends GetxController with WidgetsBindingObserver {
  static const _storageKey = 'isDarkMode';

  final RxBool isDarkMode = true.obs;

  /// Current brightness derived from [isDarkMode].
  Brightness get brightness => isDarkMode.value ? Brightness.dark : Brightness.light;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedTheme();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Called when the OS theme changes (e.g. user toggles system dark mode).
  @override
  void didChangePlatformBrightness() {
    // Only follow system if user hasn't manually chosen a theme.
    if (!_hasManualOverride) {
      final systemDark =
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark;
      isDarkMode.value = systemDark;
    }
  }

  bool get _hasManualOverride {
    try {
      if (Get.isRegistered<ILocalStorageProvider>()) {
        final storage = Get.find<ILocalStorageProvider>();
        if (storage.isInitialized) {
          return storage.getBool(_storageKey) != null;
        }
      }
    } catch (_) {}
    return false;
  }

  void _loadSavedTheme() {
    try {
      if (Get.isRegistered<ILocalStorageProvider>()) {
        final storage = Get.find<ILocalStorageProvider>();
        if (storage.isInitialized) {
          final saved = storage.getBool(_storageKey);
          if (saved != null) {
            isDarkMode.value = saved;
            return;
          }
        }
      }
      // No saved preference — use system brightness.
      final systemDark =
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark;
      isDarkMode.value = systemDark;
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
