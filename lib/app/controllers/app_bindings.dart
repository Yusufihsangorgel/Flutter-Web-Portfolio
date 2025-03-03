import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/data/providers/assets_provider.dart';
import 'package:flutter_web_portfolio/app/data/providers/local_storage_provider.dart';
import 'package:flutter_web_portfolio/app/data/repositories/language_repository_impl.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/i_language_repository.dart';

/// Uygulama başlangıcında tüm controller'ları bağlayan sınıf
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Provider'ları kaydet
    Get.put<AssetsProvider>(AssetsProvider(), permanent: true);

    Get.putAsync<LocalStorageProvider>(() async {
      final provider = LocalStorageProvider();
      return await provider.init();
    }, permanent: true);

    // Repository'leri kaydet
    Get.lazyPut<ILanguageRepository>(
      () => LanguageRepositoryImpl(
        assetsProvider: Get.find<AssetsProvider>(),
        localStorageProvider: Get.find<LocalStorageProvider>(),
      ),
      fenix: true,
    );

    // Dil ve tema controllerları kalıcı olarak kaydedilir
    Get.put(ThemeController(), permanent: true);
    Get.put(
      LanguageController(languageRepository: Get.find<ILanguageRepository>()),
      permanent: true,
    );
    Get.put(AppScrollController(), permanent: true);
  }
}
