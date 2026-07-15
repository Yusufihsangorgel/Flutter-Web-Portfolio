import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/constants/scene_configs.dart';

void main() {
  group('SceneConfigs', () {
    test('scenes list has 5 entries', () {
      expect(SceneConfigs.scenes.length, 5);
    });

    test('constant values exist for all scenes', () {
      expect(SceneConfigs.hero, isA<SceneConfig>());
      expect(SceneConfigs.about, isA<SceneConfig>());
      expect(SceneConfigs.experience, isA<SceneConfig>());
      expect(SceneConfigs.proof, isA<SceneConfig>());
      expect(SceneConfigs.projects, isA<SceneConfig>());
    });

    test('scenes list contains all named configs in order', () {
      expect(SceneConfigs.scenes[0], same(SceneConfigs.hero));
      expect(SceneConfigs.scenes[1], same(SceneConfigs.about));
      expect(SceneConfigs.scenes[2], same(SceneConfigs.experience));
      expect(SceneConfigs.scenes[3], same(SceneConfigs.proof));
      expect(SceneConfigs.scenes[4], same(SceneConfigs.projects));
    });

    test('each scene has non-null accent color', () {
      for (final scene in SceneConfigs.scenes) {
        expect(scene.accent, isNotNull);
        expect(scene.accent, isA<Color>());
      }
    });

    test('each scene has non-null gradient colors', () {
      for (final scene in SceneConfigs.scenes) {
        expect(scene.gradient1, isNotNull);
        expect(scene.gradient2, isNotNull);
        expect(scene.gradient3, isNotNull);
      }
    });

    test('atlas morph advances once per chapter', () {
      expect(
        SceneConfigs.scenes.map((scene) => scene.atlasMorph),
        orderedEquals(const [0, 1, 2, 3, 4]),
      );
    });

    test('vignetteIntensity is between 0 and 1 for all scenes', () {
      for (final scene in SceneConfigs.scenes) {
        expect(scene.vignetteIntensity, greaterThan(0.0));
        expect(scene.vignetteIntensity, lessThanOrEqualTo(1.0));
      }
    });
  });

  group('SceneConfig.lerp', () {
    const a = SceneConfigs.hero;
    const b = SceneConfigs.about;

    test('t=0 returns config a', () {
      final result = SceneConfig.lerp(a, b, 0.0);

      expect(result.gradient1, equals(a.gradient1));
      expect(result.gradient2, equals(a.gradient2));
      expect(result.gradient3, equals(a.gradient3));
      expect(result.accent, equals(a.accent));
      expect(result.atlasMorph, equals(a.atlasMorph));
      expect(result.vignetteIntensity, equals(a.vignetteIntensity));
    });

    test('t=1 returns config b', () {
      final result = SceneConfig.lerp(a, b, 1.0);

      expect(result.gradient1, equals(b.gradient1));
      expect(result.gradient2, equals(b.gradient2));
      expect(result.gradient3, equals(b.gradient3));
      expect(result.accent, equals(b.accent));
      expect(result.atlasMorph, equals(b.atlasMorph));
      expect(result.vignetteIntensity, equals(b.vignetteIntensity));
    });

    test('t=0.5 interpolates colors to midpoint', () {
      final result = SceneConfig.lerp(a, b, 0.5);

      expect(
        result.gradient1,
        equals(Color.lerp(a.gradient1, b.gradient1, 0.5)),
      );
      expect(
        result.gradient2,
        equals(Color.lerp(a.gradient2, b.gradient2, 0.5)),
      );
      expect(
        result.gradient3,
        equals(Color.lerp(a.gradient3, b.gradient3, 0.5)),
      );
      expect(result.accent, equals(Color.lerp(a.accent, b.accent, 0.5)));
    });

    test('t=0.5 interpolates numeric values to midpoint', () {
      final result = SceneConfig.lerp(a, b, 0.5);
      final expectedMorph = a.atlasMorph + (b.atlasMorph - a.atlasMorph) * 0.5;
      final expectedVignette =
          a.vignetteIntensity +
          (b.vignetteIntensity - a.vignetteIntensity) * 0.5;

      expect(result.atlasMorph, closeTo(expectedMorph, 0.001));
      expect(result.vignetteIntensity, closeTo(expectedVignette, 0.001));
    });

    test('lerp with same config returns identical values', () {
      final result = SceneConfig.lerp(a, a, 0.5);

      expect(result.gradient1, equals(a.gradient1));
      expect(result.accent, equals(a.accent));
      expect(result.atlasMorph, equals(a.atlasMorph));
    });
  });
}
