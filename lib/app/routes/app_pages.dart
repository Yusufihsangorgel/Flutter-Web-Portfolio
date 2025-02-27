import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/modules/home/home_view.dart';
import 'package:flutter_web_portfolio/app/routes/app_routes.dart';

/// Uygulama içindeki tüm sayfaları ve rotaları tanımlayan sınıf
class AppPages {
  /// Rota sayfaları oluşturulurken başvurulacak sabit değerler
  static const initial = Routes.HOME;

  /// Rota tanımları
  static final routes = [
    GetPage(
      name: Routes.HOME,
      page: () => HomeView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),

    // Diğer sayfalar uygulamaya eklendikçe buraya eklenecek
    /*
    GetPage(
      name: Routes.ABOUT,
      page: () => const AboutView(),
      transition: Transition.rightToLeft,
    ),
    
    GetPage(
      name: Routes.PROJECTS,
      page: () => const ProjectsView(),
      transition: Transition.rightToLeft,
    ),
    
    GetPage(
      name: Routes.SKILLS,
      page: () => const SkillsView(),
      transition: Transition.rightToLeft,
    ),
    
    GetPage(
      name: Routes.CONTACT,
      page: () => const ContactView(),
      transition: Transition.rightToLeft,
    ),
    
    GetPage(
      name: Routes.BLOG,
      page: () => const BlogView(),
      transition: Transition.rightToLeft,
    ),
    
    // Alt sayfalar
    GetPage(
      name: Routes.PROJECT_DETAILS,
      page: () => const ProjectDetailsView(),
      transition: Transition.zoom,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    
    GetPage(
      name: Routes.BLOG_POST,
      page: () => const BlogPostView(),
      transition: Transition.zoom,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    */
  ];
}
