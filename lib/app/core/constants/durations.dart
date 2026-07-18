/// Timings shared by more than one interaction or navigation surface.
final class AppDurations {
  const AppDurations._();

  static const microFast = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 200);
  static const buttonHover = Duration(milliseconds: 250);
  static const medium = Duration(milliseconds: 300);
  static const sectionScroll = Duration(milliseconds: 800);
  static const fadeIn = Duration(milliseconds: 800);
  static const heroDebounce = Duration(milliseconds: 500);
}
