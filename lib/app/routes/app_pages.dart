import 'package:flutter_web_portfolio/app/modules/home/bindings/home_binding.dart';
import 'package:flutter_web_portfolio/app/modules/home/home_view.dart';
import 'package:get/get.dart';

part 'app_routes.dart';

/// GetX route table — single-page portfolio with home route.
class AppPages {
  static const initial = Routes.home;

  static final routes = [
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
  ];
}
