import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../../data/providers/assets_provider.dart';
import '../../../data/providers/local_storage_provider.dart';
import '../../../data/repositories/project_repository_impl.dart';
import '../../../domain/repositories/i_project_repository.dart';
import '../../../controllers/scroll_controller.dart';
import '../../../controllers/shared_background_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AssetsProvider>()) {
      Get.lazyPut<AssetsProvider>(AssetsProvider.new);
    }

    if (!Get.isRegistered<LocalStorageProvider>()) {
      Get.putAsync<LocalStorageProvider>(() async {
        final provider = LocalStorageProvider();
        return provider.init();
      });
    }

    Get.lazyPut<IProjectRepository>(
      () => ProjectRepositoryImpl(assetsProvider: Get.find<AssetsProvider>()),
    );

    Get.lazyPut<HomeController>(
      () => HomeController(projectRepository: Get.find<IProjectRepository>()),
    );

    if (!Get.isRegistered<AppScrollController>()) {
      Get.put(AppScrollController());
    }

    if (!Get.isRegistered<SharedBackgroundController>()) {
      Get.put(SharedBackgroundController());
    }
  }
}
