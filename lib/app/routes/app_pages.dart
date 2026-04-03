import 'package:flutter_web_portfolio/app/modules/home/bindings/home_binding.dart';
import 'package:flutter_web_portfolio/app/modules/home/home_view.dart';
import 'package:flutter_web_portfolio/app/modules/not_found/not_found_view.dart';
import 'package:get/get.dart';

part 'app_routes.dart';

/// GetX route table — single-page portfolio with section deep-link routes.
///
/// Every route renders the same [HomeView]; the [AppScrollController] reads
/// the initial route and scrolls to the matching section on first frame.
final class AppPages {
  static const initial = Routes.home;

  static final routes = [
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.about,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.experience,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.projects,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.testimonials,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.blog,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.contact,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
  ];

  static final unknownRoute = GetPage(
    name: '/not-found',
    page: () => const NotFoundView(),
    transition: Transition.fadeIn,
  );
}
