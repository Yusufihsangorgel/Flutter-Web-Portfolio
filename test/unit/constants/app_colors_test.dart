import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

void main() {
  group('AppColors — scene accents', () {
    test('all sections share one coherent accent', () {
      final accents = [
        AppColors.heroAccent,
        AppColors.aboutAccent,
        AppColors.expAccent,
        AppColors.projAccent,
        AppColors.contactAccent,
      ];
      expect(
        accents.every((accent) => accent == AppColors.heroAccent),
        isTrue,
        reason:
            'Section accents should not turn the portfolio into five themes',
      );
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

  group('AppColors — editorial document base', () {
    test('paper background sits between the light and dark surfaces', () {
      final bgLuminance = AppColors.background.computeLuminance();
      final bgLightLuminance = AppColors.backgroundLight.computeLuminance();
      expect(bgLuminance, lessThan(bgLightLuminance));
      final bgDarkLum = AppColors.backgroundDark.computeLuminance();
      expect(bgDarkLum, lessThan(bgLuminance));
    });

    test('all base colors are non-null', () {
      expect(AppColors.background, isA<Color>());
      expect(AppColors.backgroundDark, isA<Color>());
      expect(AppColors.backgroundLight, isA<Color>());
      expect(AppColors.backgroundHover, isA<Color>());
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
        [
          AppColors.heroGradient1,
          AppColors.heroGradient2,
          AppColors.heroGradient3,
        ],
        [
          AppColors.aboutGradient1,
          AppColors.aboutGradient2,
          AppColors.aboutGradient3,
        ],
        [
          AppColors.expGradient1,
          AppColors.expGradient2,
          AppColors.expGradient3,
        ],
        [
          AppColors.projGradient1,
          AppColors.projGradient2,
          AppColors.projGradient3,
        ],
        [
          AppColors.contactGradient1,
          AppColors.contactGradient2,
          AppColors.contactGradient3,
        ],
      ];

      for (final gradients in sceneGradients) {
        final unique = gradients.toSet();
        expect(
          unique.length,
          3,
          reason: 'Each scene should have 3 distinct gradients',
        );
      }
    });
  });
}
