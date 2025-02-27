import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';

/// Uygulama başlangıcında tüm controller'ları bağlayan sınıf
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Dil ve tema controllerları kalıcı olarak kaydedilir
    Get.put(ThemeController(), permanent: true);
    Get.put(LanguageController(), permanent: true);
    Get.put(AppScrollController(), permanent: true);
  }
}
