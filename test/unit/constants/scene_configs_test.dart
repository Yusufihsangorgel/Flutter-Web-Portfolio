import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/constants/scene_configs.dart';

void main() {
  group('SceneConfigs', () {
    test('chapter order matches the five scene identities', () {
      expect(
        SceneConfigs.scenes,
        orderedEquals(const [
          SceneConfigs.hero,
          SceneConfigs.about,
          SceneConfigs.experience,
          SceneConfigs.proof,
          SceneConfigs.projects,
        ]),
      );
    });

    test('every vignette remains a valid opacity', () {
      for (final scene in SceneConfigs.scenes) {
        expect(scene.vignetteIntensity, inInclusiveRange(0, 1));
      }
    });
  });

  group('SceneConfig.lerp', () {
    const start = SceneConfig(
      gradient1: Color(0xFF000000),
      gradient2: Color(0xFF202020),
      gradient3: Color(0xFF404040),
      accent: Color(0xFF606060),
      vignetteIntensity: 0.2,
    );
    const end = SceneConfig(
      gradient1: Color(0xFFFFFFFF),
      gradient2: Color(0xFFE0E0E0),
      gradient3: Color(0xFFC0C0C0),
      accent: Color(0xFFA0A0A0),
      vignetteIntensity: 0.8,
    );

    test(
      'preserves endpoints and interpolates every field at the midpoint',
      () {
        final atStart = SceneConfig.lerp(start, end, 0);
        final midpoint = SceneConfig.lerp(start, end, 0.5);
        final atEnd = SceneConfig.lerp(start, end, 1);

        expect(atStart.gradient1, start.gradient1);
        expect(atStart.vignetteIntensity, start.vignetteIntensity);
        expect(atEnd.gradient1, end.gradient1);
        expect(atEnd.vignetteIntensity, end.vignetteIntensity);
        expect(
          midpoint.gradient1,
          Color.lerp(start.gradient1, end.gradient1, 0.5),
        );
        expect(
          midpoint.gradient2,
          Color.lerp(start.gradient2, end.gradient2, 0.5),
        );
        expect(
          midpoint.gradient3,
          Color.lerp(start.gradient3, end.gradient3, 0.5),
        );
        expect(midpoint.accent, Color.lerp(start.accent, end.accent, 0.5));
        expect(midpoint.vignetteIntensity, closeTo(0.5, 0.0001));
      },
    );
  });
}
