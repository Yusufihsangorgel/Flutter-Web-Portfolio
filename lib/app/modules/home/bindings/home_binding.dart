import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../../data/providers/assets_provider.dart';
import '../../../data/providers/local_storage_provider.dart';
import '../../../data/repositories/project_repository_impl.dart';
import '../../../domain/repositories/i_project_repository.dart';
import '../../../controllers/scroll_controller.dart';
import '../../../controllers/shared_background_controller.dart';

/// Ana sayfa için gerekli bağımlılıkları enjekte eden binding sınıfı
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Provider enjeksiyonu
    if (!Get.isRegistered<AssetsProvider>()) {
      Get.lazyPut<AssetsProvider>(() => AssetsProvider());
    }

    // LocalStorageProvider'ı asenkron olarak başlat ve kaydet
    if (!Get.isRegistered<LocalStorageProvider>()) {
      Get.putAsync<LocalStorageProvider>(() async {
        final provider = LocalStorageProvider();
        return await provider.init();
      });
    }

    // Repository enjeksiyonu
    Get.lazyPut<IProjectRepository>(
      () => ProjectRepositoryImpl(assetsProvider: Get.find<AssetsProvider>()),
    );

    // Controller enjeksiyonu
    Get.lazyPut<HomeController>(
      () => HomeController(projectRepository: Get.find<IProjectRepository>()),
    );

    // Scroll ve SharedBackground controller'ı kontrol et
    if (!Get.isRegistered<AppScrollController>()) {
      Get.put(AppScrollController());
    }

    if (!Get.isRegistered<SharedBackgroundController>()) {
      Get.put(SharedBackgroundController());
    }
  }
}
