import 'package:get/get.dart';

/// Uygulama içindeki rota adlarını tanımlayan sınıf
abstract class Routes {
  // Sabit rota isimleri
  static const HOME = '/';
  static const ABOUT = '/about';
  static const PROJECTS = '/projects';
  static const SKILLS = '/skills';
  static const CONTACT = '/contact';
  static const BLOG = '/blog';

  // Alt sayfalar
  static const PROJECT_DETAILS = '/project-details';
  static const BLOG_POST = '/blog-post';
}
