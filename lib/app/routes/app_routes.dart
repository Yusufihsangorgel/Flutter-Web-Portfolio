/// Application route constants.
///
/// The portfolio is a single-page scroll, but each section has its own URL
/// so that deep-linking and browser back/forward work correctly.
abstract final class Routes {
  static const home = '/';
  static const about = '/about';
  static const experience = '/experience';
  static const proof = '/proof';
  static const projects = '/projects';

  /// All valid section IDs in display order.
  static const sectionIds = [
    'home',
    'about',
    'experience',
    'proof',
    'projects',
  ];

  /// Maps a URL path to its section ID.
  static String sectionFromRoute(String route) => switch (route) {
    about => 'about',
    experience => 'experience',
    proof => 'proof',
    projects => 'projects',
    _ => 'home',
  };

  /// Maps a section ID to its URL path.
  static String routeFromSection(String section) => switch (section) {
    'about' => about,
    'experience' => experience,
    'proof' => proof,
    'projects' => projects,
    _ => home,
  };
}
