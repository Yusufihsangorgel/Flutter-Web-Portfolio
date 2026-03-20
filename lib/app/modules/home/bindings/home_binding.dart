import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/data/repositories/project_repository_impl.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_assets_provider.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/i_project_repository.dart';
import 'package:flutter_web_portfolio/app/modules/home/controllers/home_controller.dart';

/// Page-level DI for HomeController + project repo.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..lazyPut<IProjectRepository>(
        () => ProjectRepositoryImpl(assetsProvider: Get.find<IAssetsProvider>()),
      )
      ..lazyPut<HomeController>(
        () => HomeController(projectRepository: Get.find<IProjectRepository>()),
      );
  }
}
