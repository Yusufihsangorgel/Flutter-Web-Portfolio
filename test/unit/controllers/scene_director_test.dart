import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/scene_configs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppScrollController scrollController;
  late SceneDirector director;

  setUp(() {
    scrollController = AppScrollController();
    director = SceneDirector(scrollController: scrollController);
    addTearDown(() async {
      await director.close();
      await scrollController.close();
    });
  });

  group('SceneDirector', () {
    test('starts in the hero scene with zero progress', () {
      expect(director.state.currentSceneIndex, 0);
      expect(director.state.sceneProgress, 0);
      expect(director.state.globalProgress, 0);
      expect(director.state.blendFactor, 0);
    });

    test('starts with the complete hero scene configuration', () {
      final config = director.state.blendedConfig;

      expect(config.gradient1, SceneConfigs.hero.gradient1);
      expect(config.gradient2, SceneConfigs.hero.gradient2);
      expect(config.gradient3, SceneConfigs.hero.gradient3);
      expect(config.accent, SceneConfigs.hero.accent);
      expect(config.particleDensity, SceneConfigs.hero.particleDensity);
      expect(config.particleSpeed, SceneConfigs.hero.particleSpeed);
      expect(config.vignetteIntensity, SceneConfigs.hero.vignetteIntensity);
    });

    test('derives the current accent from the immutable scene snapshot', () {
      expect(director.state.currentAccent, SceneConfigs.hero.accent);
    });

    test('recalculate is safe before a scroll position is attached', () {
      expect(director.recalculate, returnsNormally);
      expect(director.state, const SceneState.initial());
    });

    test('exposes typed scene snapshots through the Cubit stream', () {
      expect(director.stream, isA<Stream<SceneState>>());
    });
  });
}
