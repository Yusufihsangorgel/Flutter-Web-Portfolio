part of 'app_pages.dart';

/// Application route constants.
///
/// The portfolio is a single-page scroll, but each section has its own URL
/// so that deep-linking and browser back/forward work correctly.
abstract final class Routes {
  static const home = '/';
  static const about = '/about';
  static const experience = '/experience';
  static const testimonials = '/testimonials';
  static const blog = '/blog';
  static const projects = '/projects';
  static const contact = '/contact';

  /// All valid section IDs in display order.
  static const sectionIds = ['home', 'about', 'experience', 'testimonials', 'blog', 'projects', 'contact'];

  /// Maps a URL path to its section ID.
  static String sectionFromRoute(String route) => switch (route) {
        about => 'about',
        experience => 'experience',
        testimonials => 'testimonials',
        blog => 'blog',
        projects => 'projects',
        contact => 'contact',
        _ => 'home',
      };

  /// Maps a section ID to its URL path.
  static String routeFromSection(String section) => switch (section) {
        'about' => about,
        'experience' => experience,
        'testimonials' => testimonials,
        'blog' => blog,
        'projects' => projects,
        'contact' => contact,
        _ => home,
      };
}
