import 'package:flutter_web_portfolio/app/modules/home/bindings/home_binding.dart';
import 'package:flutter_web_portfolio/app/modules/home/home_view.dart';
import 'package:get/get.dart';

part 'app_routes.dart';

/// Class defining application routes
class AppPages {
  /// Initial route for application launch
  static const INITIAL = Routes.HOME;

  /// All application routes
  static final routes = [
    GetPage(
      name: Routes.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    // Additional routes can be added here in the future
  ];
}
