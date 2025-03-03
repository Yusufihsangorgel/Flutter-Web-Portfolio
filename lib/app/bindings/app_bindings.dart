import 'package:get/get.dart';
import '../data/providers/assets_provider.dart';
import '../data/providers/local_storage_provider.dart';
import '../data/repositories/language_repository_impl.dart';
import '../domain/repositories/i_language_repository.dart';
import '../controllers/language_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/scroll_controller.dart';
import '../controllers/shared_background_controller.dart';
import 'package:flutter/foundation.dart';

/// Uygulama başlangıcında gereken bağımlılıkları enjekte eden binding sınıfı
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // AŞAMA 1: Temel bağımlılıkları senkron olarak kaydet
    _registerSyncDependencies();

    // AŞAMA 2: LocalStorageProvider'ı bağımsız olarak kaydet ve yükle
    _registerAndInitLocalStorage();
  }

  /// Temel ve senkron bağımlılıkları kaydeder
  void _registerSyncDependencies() {
    // Provider'lar
    Get.put<AssetsProvider>(AssetsProvider(), permanent: true);

    // Controller'lar
    Get.put(ThemeController(), permanent: true);
    Get.put(AppScrollController(), permanent: true);
    Get.put(SharedBackgroundController(), permanent: true);

    // Basit bir fallback language controller - gerçek controller yüklenene kadar
    if (!Get.isRegistered<LanguageController>()) {
      // Dummy repository oluştur
      final dummyRepository = LanguageRepositoryImpl(
        assetsProvider: Get.find<AssetsProvider>(),
        localStorageProvider: LocalStorageProvider(), // Geçici instance
      );

      // Geçici controller oluştur - sonra gerçeğiyle değiştirilecek
      Get.put(
        LanguageController(languageRepository: dummyRepository),
        permanent: false, // Geçici olduğu için false
        tag: 'temp',
      );
    }
  }

  /// LocalStorageProvider'ı bağımsız olarak kaydeder ve başlatır
  void _registerAndInitLocalStorage() {
    Get.putAsync<LocalStorageProvider>(() async {
      try {
        debugPrint('📦 LocalStorageProvider başlatılıyor...');
        final provider = LocalStorageProvider();
        final initialized = await provider.init();

        // LocalStorage başarıyla yüklendi, şimdi gerçek bağımlılıkları kaydedebiliriz
        _registerDependenciesAfterStorage(
          useLocalStorage: initialized.isInitialized,
        );

        return initialized;
      } catch (e) {
        debugPrint('❌ LocalStorageProvider başlatma hatası: $e');
        // Hata durumunda yine de bağımlılık zincirini başlat
        _registerDependenciesAfterStorage(useLocalStorage: false);

        // Başarısız olsa bile provider'ı geri döndür
        return LocalStorageProvider();
      }
    }, permanent: true);
  }

  /// LocalStorage başlatıldıktan sonra ilgili bağımlılıkları kaydeder
  void _registerDependenciesAfterStorage({bool useLocalStorage = true}) {
    debugPrint('🔄 Language bağımlılıkları kaydediliyor...');

    try {
      // 1. Repository oluştur
      final repository = _createLanguageRepository(useLocalStorage);
      Get.lazyPut<ILanguageRepository>(() => repository, fenix: true);

      // 2. Gerçek LanguageController'ı oluştur
      _createAndRegisterLanguageController(repository);
    } catch (e) {
      debugPrint('❌ Language bağımlılıkları kaydedilirken hata: $e');
    }
  }

  /// LanguageRepository oluşturur
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
        } else {
          debugPrint(
            '⚠️ LocalStorage başlatılmamış, alternatif repository kullanılıyor',
          );
        }
      } catch (e) {
        debugPrint(
          '⚠️ LocalStorage bulunamadı, alternatif repository kullanılıyor',
        );
      }
    }

    // LocalStorage bulunamadı veya kullanılmaması istendi - fallback repository
    final emptyProvider = LocalStorageProvider();
    return LanguageRepositoryImpl(
      assetsProvider: assetsProvider,
      localStorageProvider: emptyProvider,
    );
  }

  /// LanguageController oluşturur ve kaydeder
  void _createAndRegisterLanguageController(ILanguageRepository repository) {
    // Geçici controller'ı kaldır
    if (Get.isRegistered<LanguageController>(tag: 'temp')) {
      Get.delete<LanguageController>(tag: 'temp');
    }

    // Gerçek controller'ı oluştur ve kaydet
    if (!Get.isRegistered<LanguageController>()) {
      final controller = LanguageController(languageRepository: repository);
      Get.put<LanguageController>(controller, permanent: true);
      debugPrint('✅ LanguageController başarıyla oluşturuldu ve kaydedildi');
    }
  }
}
