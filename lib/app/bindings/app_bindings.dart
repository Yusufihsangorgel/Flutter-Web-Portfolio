import 'dart:developer' as dev;

import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/cursor_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/personalization_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/sound_controller.dart';
import 'package:flutter_web_portfolio/app/data/providers/assets_provider.dart';
import 'package:flutter_web_portfolio/app/data/providers/local_storage_provider.dart';
import 'package:flutter_web_portfolio/app/data/providers/github_provider.dart';
import 'package:flutter_web_portfolio/app/data/providers/medium_provider.dart';
import 'package:flutter_web_portfolio/app/data/repositories/language_repository_impl.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_assets_provider.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_local_storage_provider.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/i_language_repository.dart';

/// Wires up global DI — providers, controllers, repos.
class AppBindings extends Bindings {
  @override
  void dependencies() {
    _registerSyncDependencies();
    _registerAndInitLocalStorage();
  }

  void _registerSyncDependencies() {
    Get
      ..put<IAssetsProvider>(AssetsProvider(), permanent: true)
      ..put(AppScrollController(), permanent: true)
      ..put(SceneDirector(), permanent: true)
      ..put(CursorController(), permanent: true)
      ..put(MediumProvider(), permanent: true)
      ..put(GitHubProvider(), permanent: true)
      ..put(SoundController(), permanent: true)
      ..put(PersonalizationController(), permanent: true);
    if (!Get.isRegistered<LanguageController>()) {
      final dummyRepository = LanguageRepositoryImpl(
        assetsProvider: Get.find<IAssetsProvider>(),
        localStorageProvider: LocalStorageProvider(),
      );
      Get.put(
        LanguageController(languageRepository: dummyRepository),
        permanent: false,
        tag: 'temp',
      );
    }
  }

  void _registerAndInitLocalStorage() {
    Get.putAsync<ILocalStorageProvider>(() async {
      try {
        final provider = LocalStorageProvider();
        final initialized = await provider.init();
        _registerDependenciesAfterStorage(
          useLocalStorage: initialized.isInitialized,
        );
        return initialized;
      } catch (e) {
        dev.log('LocalStorageProvider init failed', name: 'AppBindings', error: e);
        _registerDependenciesAfterStorage(useLocalStorage: false);
        return LocalStorageProvider();
      }
    }, permanent: true);
  }

  void _registerDependenciesAfterStorage({bool useLocalStorage = true}) {
    try {
      final repository = _createLanguageRepository(useLocalStorage);
      Get.lazyPut<ILanguageRepository>(() => repository, fenix: true);
      _createAndRegisterLanguageController(repository);

    } catch (e) {
      dev.log('Language dependency registration failed', name: 'AppBindings', error: e);
    }
  }

  ILanguageRepository _createLanguageRepository(bool useLocalStorage) {
    final assetsProvider = Get.find<IAssetsProvider>();

    if (useLocalStorage) {
      try {
        final storageProvider = Get.find<ILocalStorageProvider>();
        if (storageProvider.isInitialized) {
          return LanguageRepositoryImpl(
            assetsProvider: assetsProvider,
            localStorageProvider: storageProvider,
          );
        }
      } catch (e) {
        dev.log('Storage provider access failed', name: 'AppBindings', error: e);
      }
    }

    return LanguageRepositoryImpl(
      assetsProvider: assetsProvider,
      localStorageProvider: LocalStorageProvider(),
    );
  }

  void _createAndRegisterLanguageController(ILanguageRepository repository) {
    if (Get.isRegistered<LanguageController>(tag: 'temp')) {
      Get.delete<LanguageController>(tag: 'temp');
    }

    if (!Get.isRegistered<LanguageController>()) {
      Get.put<LanguageController>(
        LanguageController(languageRepository: repository),
        permanent: true,
      );
    }
  }
}
