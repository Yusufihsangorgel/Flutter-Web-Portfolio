import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/scene_configs.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import '../../helpers/narrative_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppScrollController scrollController;
  late SceneDirector director;

  setUp(() {
    scrollController = AppScrollController(narrative: loadNarrativeFixture());
    director = SceneDirector(scrollController: scrollController);
    addTearDown(() async {
      await director.close();
      await scrollController.close();
    });
  });

  group('SceneDirector', () {
    test('starts in the hero scene with zero progress', () {
      expect(director.state.currentSceneIndex, 0);
      expect(director.state.globalProgress, 0);
      expect(director.state.blendFactor, 0);
    });

    test('starts with the complete hero scene configuration', () {
      final config = director.state.blendedConfig;

      expect(config.gradient1, SceneConfigs.hero.gradient1);
      expect(config.gradient2, SceneConfigs.hero.gradient2);
      expect(config.gradient3, SceneConfigs.hero.gradient3);
      expect(config.accent, SceneConfigs.hero.accent);
      expect(config.vignetteIntensity, SceneConfigs.hero.vignetteIntensity);
    });

    test('derives the current accent from the immutable scene snapshot', () {
      expect(director.state.currentAccent, SceneConfigs.hero.accent);
      expect(director.state.currentMotif, NarrativeMotif.origin);
      expect(director.state.nextMotif, NarrativeMotif.origin);
    });

    test('recalculate is safe before a scroll position is attached', () {
      expect(director.recalculate, returnsNormally);
      expect(director.state, const SceneState.initial());
    });

    test('exposes typed scene snapshots through the Cubit stream', () {
      expect(director.stream, isA<Stream<SceneState>>());
    });

    test('uses measured chapter centres instead of equal document bands', () {
      const sections = [
        SectionGeometry(id: 'home', top: 0, height: 800),
        SectionGeometry(id: 'about', top: 900, height: 400),
        SectionGeometry(id: 'experience', top: 1500, height: 1400),
        SectionGeometry(id: 'proof', top: 3000, height: 500),
        SectionGeometry(id: 'projects', top: 3600, height: 2400),
      ];

      final state = SceneDirector.calculateState(
        offset: 660,
        viewportDimension: 1000,
        maxExtent: 5200,
        sections: sections,
        narrative: loadNarrativeFixture(),
      );

      expect(state.currentSceneIndex, 1);
      expect(state.blendedConfig, SceneConfigs.about);
      expect(state.currentMotif, NarrativeMotif.thread);
    });

    test('smoothly blends between adjacent measured chapters', () {
      const sections = [
        SectionGeometry(id: 'home', top: 0, height: 800),
        SectionGeometry(id: 'about', top: 900, height: 400),
        SectionGeometry(id: 'experience', top: 1500, height: 1400),
      ];

      final state = SceneDirector.calculateState(
        offset: 1210,
        viewportDimension: 1000,
        maxExtent: 2400,
        sections: sections,
        narrative: loadNarrativeFixture(),
      );

      expect(state.currentSceneIndex, 1);
      expect(state.blendFactor, closeTo(0.5, 0.001));
      expect(
        state.blendedConfig.accent,
        SceneConfig.lerp(
          SceneConfigs.about,
          SceneConfigs.experience,
          0.5,
        ).accent,
      );
      expect(state.currentAccent, SceneConfigs.about.accent);
      expect(state.currentMotif, NarrativeMotif.thread);
      expect(state.nextMotif, NarrativeMotif.timeline);
    });
  });
}
