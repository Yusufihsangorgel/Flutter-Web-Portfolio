import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/scene_configs.dart';
import 'package:flutter_web_portfolio/app/narrative/application/narrative_position.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';

@immutable
final class SceneState {
  const SceneState({
    required this.currentSceneIndex,
    required this.globalProgress,
    required this.blendFactor,
    required this.blendedConfig,
    required this.currentMotif,
    required this.nextMotif,
    required this.activeMotif,
  });

  const SceneState.initial()
    : currentSceneIndex = 0,
      globalProgress = 0,
      blendFactor = 0,
      blendedConfig = SceneConfigs.hero,
      currentMotif = NarrativeMotif.origin,
      nextMotif = NarrativeMotif.origin,
      activeMotif = NarrativeMotif.origin;

  final int currentSceneIndex;
  final double globalProgress;
  final double blendFactor;
  final SceneConfig blendedConfig;
  final NarrativeMotif currentMotif;
  final NarrativeMotif nextMotif;
  final NarrativeMotif activeMotif;

  /// Stable chapter accent for content widgets.
  ///
  /// The painter consumes [blendedConfig] continuously, while headings and
  /// content changes accent only when the active chapter changes. This prevents
  /// scroll-frequency content rebuilds during palette crossfades.
  Color get currentAccent => SceneConfigs.scenes[currentSceneIndex].accent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneState &&
          currentSceneIndex == other.currentSceneIndex &&
          globalProgress == other.globalProgress &&
          blendFactor == other.blendFactor &&
          blendedConfig == other.blendedConfig &&
          currentMotif == other.currentMotif &&
          nextMotif == other.nextMotif &&
          activeMotif == other.activeMotif;

  @override
  int get hashCode => Object.hash(
    currentSceneIndex,
    globalProgress,
    blendFactor,
    blendedConfig,
    currentMotif,
    nextMotif,
    activeMotif,
  );
}

/// Scroll-driven scene state machine.
///
/// A single immutable snapshot is emitted per scroll tick. Consumers select
/// only the accent or progress field they paint, preventing unrelated widgets
/// from rebuilding while the background changes.
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

  /// Maps the shared reading position to one boundary-local scene blend.
  @visibleForTesting
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
        : _smoothStep(position.boundaryProgress);

    return SceneState(
      currentSceneIndex: activeSceneIndex,
      globalProgress: position.documentProgress,
      blendFactor: transition,
      blendedConfig: transition == 0
          ? SceneConfigs.scenes[currentSceneIndex]
          : SceneConfig.lerp(
              SceneConfigs.scenes[currentSceneIndex],
              SceneConfigs.scenes[nextSceneIndex],
              transition,
            ),
      currentMotif: currentChapter.motif,
      nextMotif: nextChapter.motif,
      activeMotif: activeChapter.motif,
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

  static double _smoothStep(double value) => value * value * (3 - 2 * value);

  void recalculate() => _emitCurrentState();

  @override
  Future<void> close() {
    _scrollController.narrativePosition.removeListener(_onPosition);
    return super.close();
  }
}
