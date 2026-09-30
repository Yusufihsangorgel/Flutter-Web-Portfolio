import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/scene_configs.dart';
import 'package:flutter_web_portfolio/app/narrative/application/narrative_position.dart';
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
    test('starts in the document scene', () {
      expect(director.state.currentSceneIndex, 0);
    });

    test('starts with the complete document scene configuration', () {
      final config = director.state.blendedConfig;

      expect(config.gradient1, SceneConfigs.document.gradient1);
      expect(config.gradient2, SceneConfigs.document.gradient2);
      expect(config.gradient3, SceneConfigs.document.gradient3);
      expect(config.accent, SceneConfigs.document.accent);
      expect(config.vignetteIntensity, SceneConfigs.document.vignetteIntensity);
    });

    test('derives the current accent from the immutable scene snapshot', () {
      expect(director.state.currentAccent, SceneConfigs.document.accent);
    });

    test('keeps the initial scene before a scroll position is attached', () {
      expect(director.state, const SceneState.initial());
    });

    test('maps a stable shared position to one chapter scene', () {
      final state = SceneDirector.calculateState(
        position: const NarrativePosition(
          activeSectionId: 'experience',
          currentSectionId: 'experience',
          nextSectionId: 'experience',
          focalPoint: 1800,
          boundaryProgress: 0,
          documentProgress: 0.32,
        ),
        narrative: loadNarrativeFixture(),
      );

      expect(state.currentSceneIndex, 2);
      expect(state.blendedConfig, SceneConfigs.document);
    });

    test('smoothly blends only the boundary described by the resolver', () {
      final state = SceneDirector.calculateState(
        position: const NarrativePosition(
          activeSectionId: 'proof',
          currentSectionId: 'experience',
          nextSectionId: 'proof',
          focalPoint: 3000,
          boundaryProgress: 0.5,
          documentProgress: 0.5,
        ),
        narrative: loadNarrativeFixture(),
      );

      expect(state.currentSceneIndex, 3);
      expect(
        state.blendedConfig.accent,
        SceneConfig.lerp(SceneConfigs.document, SceneConfigs.proof, 0.5).accent,
      );
      expect(state.currentAccent, SceneConfigs.proof.accent);
    });
  });
}
