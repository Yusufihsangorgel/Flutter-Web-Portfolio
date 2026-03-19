import 'dart:developer' as dev;

import 'package:get/get.dart';
import '../data/providers/assets_provider.dart';
import '../data/providers/local_storage_provider.dart';
import '../data/repositories/language_repository_impl.dart';
import '../domain/repositories/i_language_repository.dart';
import '../controllers/language_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/scroll_controller.dart';
import '../controllers/shared_background_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    _registerSyncDependencies();
    _registerAndInitLocalStorage();
  }

  void _registerSyncDependencies() {
    Get.put<AssetsProvider>(AssetsProvider(), permanent: true);
    Get.put(ThemeController(), permanent: true);
    Get.put(AppScrollController(), permanent: true);
    Get.put(SharedBackgroundController(), permanent: true);

    if (!Get.isRegistered<LanguageController>()) {
      final dummyRepository = LanguageRepositoryImpl(
        assetsProvider: Get.find<AssetsProvider>(),
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
    Get.putAsync<LocalStorageProvider>(() async {
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
    final assetsProvider = Get.find<AssetsProvider>();

    if (useLocalStorage) {
      try {
        final storageProvider = Get.find<LocalStorageProvider>();
        if (storageProvider.isInitialized) {
          return LanguageRepositoryImpl(
            assetsProvider: assetsProvider,
            localStorageProvider: storageProvider,
          );
        }
      } catch (_) {
        // Fall through to fallback
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
