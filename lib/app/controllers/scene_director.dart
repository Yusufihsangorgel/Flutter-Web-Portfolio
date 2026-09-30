import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/scene_configs.dart';
import 'package:flutter_web_portfolio/app/narrative/application/narrative_position.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/smooth_step.dart';

@immutable
final class SceneState {
  const SceneState({
    required this.currentSceneIndex,
    required this.blendedConfig,
  });

  const SceneState.initial()
    : currentSceneIndex = 0,
      blendedConfig = SceneConfigs.document;

  final int currentSceneIndex;
  final SceneConfig blendedConfig;

  /// Keeps content accents steady between chapter changes.
  Color get currentAccent => SceneConfigs.scenes[currentSceneIndex].accent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneState &&
          currentSceneIndex == other.currentSceneIndex &&
          blendedConfig == other.blendedConfig;

  @override
  int get hashCode => Object.hash(currentSceneIndex, blendedConfig);
}

/// Publishes the scene selected by the reading position.
final class SceneDirector extends Cubit<SceneState> {
  SceneDirector({required AppScrollController scrollController})
    : _scrollController = scrollController,
      _narrative = scrollController.narrative,
      super(const SceneState.initial()) {
    if (NarrativeMotif.values.length != SceneConfigs.scenes.length) {
      throw StateError(
        'Every narrative motif must have one scene configuration.',
      );
    }
    _scrollController.narrativePosition.addListener(_onPosition);
    _emitCurrentState();
  }

  final AppScrollController _scrollController;
  final NarrativeDocument _narrative;
  void _onPosition() => _emitCurrentState();

  void _emitCurrentState() {
    emit(
      calculateState(
        position: _scrollController.narrativePosition.value,
        narrative: _narrative,
      ),
    );
  }

  static SceneState calculateState({
    required NarrativePosition position,
    required NarrativeDocument narrative,
  }) {
    final currentChapter = narrative.chapterFor(
      SectionId(position.currentSectionId),
    );
    final nextChapter = narrative.chapterFor(SectionId(position.nextSectionId));
    final activeChapter = narrative.chapterFor(
      SectionId(position.activeSectionId),
    );
    final currentSceneIndex = _sceneIndexFor(currentChapter);
    final nextSceneIndex = _sceneIndexFor(nextChapter);
    final activeSceneIndex = _sceneIndexFor(activeChapter);
    final transition = currentChapter.id == nextChapter.id
        ? 0.0
        : smoothStep(position.boundaryProgress);

    return SceneState(
      currentSceneIndex: activeSceneIndex,
      blendedConfig: transition == 0
          ? SceneConfigs.scenes[currentSceneIndex]
          : SceneConfig.lerp(
              SceneConfigs.scenes[currentSceneIndex],
              SceneConfigs.scenes[nextSceneIndex],
              transition,
            ),
    );
  }

  static int _sceneIndexFor(NarrativeChapter chapter) =>
      switch (chapter.motif) {
        NarrativeMotif.origin => 0,
        NarrativeMotif.thread => 1,
        NarrativeMotif.timeline => 2,
        NarrativeMotif.branches => 3,
        NarrativeMotif.bracket => 4,
      };

  @override
  Future<void> close() {
    _scrollController.narrativePosition.removeListener(_onPosition);
    return super.close();
  }
}
