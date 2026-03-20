import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

void main() {
  group('AppDurations — positivity', () {
    test('all duration values are positive', () {
      final durations = [
        AppDurations.microFast,
        AppDurations.veryFast,
        AppDurations.fast,
        AppDurations.buttonHover,
        AppDurations.medium,
        AppDurations.normal,
        AppDurations.crossfade,
        AppDurations.entrance,
        AppDurations.slow,
        AppDurations.sectionScroll,
        AppDurations.fadeIn,
        AppDurations.loadingPulse,
        AppDurations.heroEntrance,
        AppDurations.heroInitialPause,
        AppDurations.heroNameRevealDelay,
        AppDurations.heroNameRevealDuration,
        AppDurations.heroSubtitleDelay,
        AppDurations.heroSubtitleDuration,
        AppDurations.heroLocationDelay,
        AppDurations.heroLocationDuration,
        AppDurations.heroCTADelay,
        AppDurations.heroScrollIndicator,
        AppDurations.staggerShort,
        AppDurations.staggerMedium,
        AppDurations.scrollDebounce,
        AppDurations.heroDebounce,
      ];

      for (final d in durations) {
        expect(d.inMilliseconds, greaterThan(0),
            reason: '$d must be positive');
      }
    });
  });

  group('AppDurations — micro-interaction ordering', () {
    test('microFast < veryFast < fast < medium < normal < slow', () {
      expect(AppDurations.microFast, lessThan(AppDurations.veryFast));
      expect(AppDurations.veryFast, lessThan(AppDurations.fast));
      expect(AppDurations.fast, lessThan(AppDurations.medium));
      expect(AppDurations.medium, lessThan(AppDurations.normal));
      expect(AppDurations.normal, lessThan(AppDurations.slow));
    });

    test('buttonHover sits between fast and medium', () {
      expect(AppDurations.buttonHover.inMilliseconds,
          greaterThanOrEqualTo(AppDurations.fast.inMilliseconds));
      expect(AppDurations.buttonHover.inMilliseconds,
          lessThanOrEqualTo(AppDurations.medium.inMilliseconds));
    });
  });

  group('AppDurations — hero sequence ordering', () {
    test('hero delays are in chronological order', () {
      expect(AppDurations.heroInitialPause, lessThan(AppDurations.heroNameRevealDelay));
      expect(
          AppDurations.heroNameRevealDelay, lessThan(AppDurations.heroSubtitleDelay));
      expect(AppDurations.heroSubtitleDelay, lessThan(AppDurations.heroLocationDelay));
      expect(AppDurations.heroLocationDelay, lessThan(AppDurations.heroCTADelay));
      expect(AppDurations.heroCTADelay, lessThan(AppDurations.heroScrollIndicator));
    });

    test('heroEntrance encompasses the full sequence', () {
      expect(AppDurations.heroEntrance.inMilliseconds,
          greaterThanOrEqualTo(AppDurations.heroScrollIndicator.inMilliseconds));
    });

    test('hero reveal durations are positive and shorter than total entrance', () {
      final reveals = [
        AppDurations.heroNameRevealDuration,
        AppDurations.heroSubtitleDuration,
        AppDurations.heroLocationDuration,
      ];
      for (final d in reveals) {
        expect(d.inMilliseconds, greaterThan(0));
        expect(d, lessThan(AppDurations.heroEntrance));
      }
    });
  });

  group('AppDurations — stagger delays', () {
    test('stagger delays are shorter than standard animation durations', () {
      expect(AppDurations.staggerShort, lessThan(AppDurations.normal));
      expect(AppDurations.staggerMedium, lessThan(AppDurations.normal));
    });

    test('staggerShort < staggerMedium', () {
      expect(AppDurations.staggerShort, lessThan(AppDurations.staggerMedium));
    });
  });

  group('AppDurations — debounce', () {
    test('scrollDebounce is shorter than heroDebounce', () {
      expect(AppDurations.scrollDebounce, lessThan(AppDurations.heroDebounce));
    });
  });
}
