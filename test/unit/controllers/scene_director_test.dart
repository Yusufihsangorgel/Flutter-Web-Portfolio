import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/scene_configs.dart';

void main() {
  group('SceneDirector', () {
    setUp(() {
      Get.testMode = true;
    });

    tearDown(Get.reset);

    test('initial currentSceneIndex is 0', () {
      final director = SceneDirector();
      expect(director.currentSceneIndex.value, 0);
    });

    test('initial sceneProgress is 0.0', () {
      final director = SceneDirector();
      expect(director.sceneProgress.value, 0.0);
    });

    test('initial globalProgress is 0.0', () {
      final director = SceneDirector();
      expect(director.globalProgress.value, 0.0);
    });

    test('initial blendFactor is 0.0', () {
      final director = SceneDirector();
      expect(director.blendFactor.value, 0.0);
    });

    test('blendedConfig starts as SceneConfigs.hero', () {
      final director = SceneDirector();
      final config = director.blendedConfig.value;
      expect(config.gradient1, equals(SceneConfigs.hero.gradient1));
      expect(config.gradient2, equals(SceneConfigs.hero.gradient2));
      expect(config.gradient3, equals(SceneConfigs.hero.gradient3));
      expect(config.accent, equals(SceneConfigs.hero.accent));
      expect(config.particleDensity, equals(SceneConfigs.hero.particleDensity));
      expect(config.particleSpeed, equals(SceneConfigs.hero.particleSpeed));
      expect(config.vignetteIntensity, equals(SceneConfigs.hero.vignetteIntensity));
    });

    test('currentAccent starts as SceneConfigs.hero.accent', () {
      final director = SceneDirector();
      expect(director.currentAccent.value, equals(SceneConfigs.hero.accent));
    });

    test('currentAccent is reactive (Rx<Color>)', () {
      final director = SceneDirector();
      expect(director.currentAccent, isA<Rx<Color>>());
    });

    test('currentSceneIndex is reactive (RxInt)', () {
      final director = SceneDirector();
      expect(director.currentSceneIndex, isA<RxInt>());
    });

    test('sceneProgress is reactive (RxDouble)', () {
      final director = SceneDirector();
      expect(director.sceneProgress, isA<RxDouble>());
    });

    test('globalProgress is reactive (RxDouble)', () {
      final director = SceneDirector();
      expect(director.globalProgress, isA<RxDouble>());
    });

    test('blendFactor is reactive (RxDouble)', () {
      final director = SceneDirector();
      expect(director.blendFactor, isA<RxDouble>());
    });

    test('blendedConfig is reactive (Rx<SceneConfig>)', () {
      final director = SceneDirector();
      expect(director.blendedConfig, isA<Rx<SceneConfig>>());
    });
  });
}
