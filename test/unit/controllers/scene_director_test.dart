import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/scene_configs.dart';
import 'package:flutter_web_portfolio/app/narrative/application/narrative_position.dart';
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
      expect(state.globalProgress, 0.32);
      expect(state.blendedConfig, SceneConfigs.experience);
      expect(state.currentMotif, NarrativeMotif.timeline);
      expect(state.nextMotif, NarrativeMotif.timeline);
      expect(state.activeMotif, NarrativeMotif.timeline);
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
      expect(state.blendFactor, closeTo(0.5, 0.001));
      expect(
        state.blendedConfig.accent,
        SceneConfig.lerp(
          SceneConfigs.experience,
          SceneConfigs.proof,
          0.5,
        ).accent,
      );
      expect(state.currentAccent, SceneConfigs.proof.accent);
      expect(state.currentMotif, NarrativeMotif.timeline);
      expect(state.nextMotif, NarrativeMotif.branches);
      expect(state.activeMotif, NarrativeMotif.branches);
    });
  });
}
