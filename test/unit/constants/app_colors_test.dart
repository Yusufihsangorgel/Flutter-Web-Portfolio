import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

void main() {
  group('AppColors — scene accents', () {
    test('all scene accents are distinct colors', () {
      final accents = {
        AppColors.heroAccent,
        AppColors.aboutAccent,
        AppColors.expAccent,
        AppColors.projAccent,
        AppColors.contactAccent,
      };
      expect(accents.length, 5, reason: 'All 5 scene accent colors must be unique');
    });

    test('all scene accents are non-null Color instances', () {
      final accents = [
        AppColors.heroAccent,
        AppColors.aboutAccent,
        AppColors.expAccent,
        AppColors.projAccent,
        AppColors.contactAccent,
      ];
      for (final accent in accents) {
        expect(accent, isA<Color>());
      }
    });
  });

  group('AppColors — dark mode base', () {
    test('background is darker than backgroundLight', () {
      // A darker color has a lower luminance
      final bgLuminance = AppColors.background.computeLuminance();
      final bgLightLuminance = AppColors.backgroundLight.computeLuminance();
      expect(bgLuminance, lessThan(bgLightLuminance));
    });

    test('backgroundDark is darker than background', () {
      final bgDarkLum = AppColors.backgroundDark.computeLuminance();
      final bgLum = AppColors.background.computeLuminance();
      expect(bgDarkLum, lessThanOrEqualTo(bgLum));
    });

    test('all base colors are non-null', () {
      expect(AppColors.background, isA<Color>());
      expect(AppColors.backgroundDark, isA<Color>());
      expect(AppColors.backgroundLight, isA<Color>());
      expect(AppColors.backgroundHover, isA<Color>());
    });
  });

  group('AppColors — light mode', () {
    test('light mode colors exist and are Color instances', () {
      expect(AppColors.lightBackground, isA<Color>());
      expect(AppColors.lightBackgroundDark, isA<Color>());
      expect(AppColors.lightSurface, isA<Color>());
      expect(AppColors.lightSurfaceVariant, isA<Color>());
      expect(AppColors.lightBackgroundHover, isA<Color>());
      expect(AppColors.lightTextBright, isA<Color>());
      expect(AppColors.lightTextPrimary, isA<Color>());
      expect(AppColors.lightTextSecondary, isA<Color>());
    });

    test('light mode background differs from dark mode background', () {
      expect(AppColors.lightBackground, isNot(equals(AppColors.background)));
    });

    test('light mode text differs from dark mode text', () {
      expect(AppColors.lightTextBright, isNot(equals(AppColors.textBright)));
      expect(AppColors.lightTextPrimary, isNot(equals(AppColors.textPrimary)));
    });

    test('light background is lighter than dark background', () {
      final lightLum = AppColors.lightBackground.computeLuminance();
      final darkLum = AppColors.background.computeLuminance();
      expect(lightLum, greaterThan(darkLum));
    });
  });

  group('AppColors — semantic aliases', () {
    test('accent matches heroAccent', () {
      expect(AppColors.accent, equals(AppColors.heroAccent));
    });

    test('primary matches accent', () {
      expect(AppColors.primary, equals(AppColors.accent));
    });

    test('surface matches backgroundLight', () {
      expect(AppColors.surface, equals(AppColors.backgroundLight));
    });

    test('surfaceVariant matches backgroundLight', () {
      expect(AppColors.surfaceVariant, equals(AppColors.backgroundLight));
    });
  });

  group('AppColors — scene gradients', () {
    test('each scene has three distinct gradient colors', () {
      final sceneGradients = [
        [AppColors.heroGradient1, AppColors.heroGradient2, AppColors.heroGradient3],
        [AppColors.aboutGradient1, AppColors.aboutGradient2, AppColors.aboutGradient3],
        [AppColors.expGradient1, AppColors.expGradient2, AppColors.expGradient3],
        [AppColors.projGradient1, AppColors.projGradient2, AppColors.projGradient3],
        [
          AppColors.contactGradient1,
          AppColors.contactGradient2,
          AppColors.contactGradient3,
        ],
      ];

      for (final gradients in sceneGradients) {
        final unique = gradients.toSet();
        expect(unique.length, 3, reason: 'Each scene should have 3 distinct gradients');
      }
    });
  });
}
