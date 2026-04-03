/// Centralized animation duration constants.
final class AppDurations {
  const AppDurations._();

  // Micro-interactions
  static const microFast = Duration(milliseconds: 100);
  static const veryFast = Duration(milliseconds: 150);
  static const fast = Duration(milliseconds: 200);
  static const buttonHover = Duration(milliseconds: 250);
  static const medium = Duration(milliseconds: 300);

  // Standard transitions
  static const normal = Duration(milliseconds: 400);
  static const crossfade = Duration(milliseconds: 400);

  // Slow / dramatic
  static const entrance = Duration(milliseconds: 600);
  static const slow = Duration(milliseconds: 800);
  static const sectionScroll = Duration(milliseconds: 800);
  static const fadeIn = Duration(milliseconds: 800);

  // Loading
  static const loadingPulse = Duration(milliseconds: 1500);

  // Hero sequence
  static const heroEntrance = Duration(milliseconds: 1800);
  static const heroInitialPause = Duration(milliseconds: 200);
  static const heroNameRevealDelay = Duration(milliseconds: 300);
  static const heroNameRevealDuration = Duration(milliseconds: 600);
  static const heroSubtitleDelay = Duration(milliseconds: 800);
  static const heroSubtitleDuration = Duration(milliseconds: 600);
  static const heroLocationDelay = Duration(milliseconds: 1000);
  static const heroLocationDuration = Duration(milliseconds: 400);
  static const heroCTADelay = Duration(milliseconds: 1200);
  static const heroScrollIndicator = Duration(milliseconds: 1600);

  // Stagger delays
  static const staggerShort = Duration(milliseconds: 100);
  static const staggerMedium = Duration(milliseconds: 200);
  static const staggerLong = Duration(milliseconds: 500);
  static const staggerXLong = Duration(milliseconds: 600);

  // Form
  static const formResetDelay = Duration(seconds: 3);

  // Debounce
  static const scrollDebounce = Duration(milliseconds: 100);
  static const heroDebounce = Duration(milliseconds: 500);
}
