import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/scene_configs.dart';
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
  });

  const SceneState.initial()
    : currentSceneIndex = 0,
      globalProgress = 0,
      blendFactor = 0,
      blendedConfig = SceneConfigs.hero,
      currentMotif = NarrativeMotif.origin,
      nextMotif = NarrativeMotif.origin;

  final int currentSceneIndex;
  final double globalProgress;
  final double blendFactor;
  final SceneConfig blendedConfig;
  final NarrativeMotif currentMotif;
  final NarrativeMotif nextMotif;

  /// Stable chapter accent for content widgets.
  ///
  /// The painter consumes [blendedConfig] continuously, while headings and
  /// cards change accent only when the active chapter changes. This prevents
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
          nextMotif == other.nextMotif;

  @override
  int get hashCode => Object.hash(
    currentSceneIndex,
    globalProgress,
    blendFactor,
    blendedConfig,
    currentMotif,
    nextMotif,
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
    _scrollController.scrollController.addListener(_onScroll);
  }

  final AppScrollController _scrollController;
  final NarrativeDocument _narrative;
  bool _frameScheduled = false;

  void _onScroll() {
    if (_frameScheduled) return;
    _frameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _frameScheduled = false;
      if (isClosed) return;
      _emitCurrentState();
    });
  }

  void _emitCurrentState() {
    final scroll = _scrollController.scrollController;
    if (!scroll.hasClients) return;

    emit(
      calculateState(
        offset: scroll.offset,
        viewportDimension: scroll.position.viewportDimension,
        maxExtent: scroll.position.maxScrollExtent,
        sections: _scrollController.sectionGeometries,
        narrative: _narrative,
      ),
    );
  }

  /// Calculates scene state from measured chapter centres.
  ///
  /// The viewport focal point travels between adjacent chapter centres, and
  /// the palette follows that real journey. Uneven content no longer makes a
  /// scene change early or linger after its chapter has left the viewport.
  @visibleForTesting
  static SceneState calculateState({
    required double offset,
    required double viewportDimension,
    required double maxExtent,
    required List<SectionGeometry> sections,
    required NarrativeDocument narrative,
  }) {
    if (sections.isEmpty) return const SceneState.initial();

    final safeMaxExtent = maxExtent <= 0 ? 1.0 : maxExtent;
    final globalProgress = (offset / safeMaxExtent).clamp(0.0, 1.0);
    final focalPoint = offset + viewportDimension * 0.44;

    if (sections.length == 1 || focalPoint <= sections.first.center) {
      final chapter = narrative.chapterFor(SectionId(sections.first.id));
      final sceneIndex = _sceneIndexFor(chapter);
      return SceneState(
        currentSceneIndex: sceneIndex,
        globalProgress: globalProgress,
        blendFactor: 0,
        blendedConfig: SceneConfigs.scenes[sceneIndex],
        currentMotif: chapter.motif,
        nextMotif: chapter.motif,
      );
    }

    for (var index = 0; index < sections.length - 1; index++) {
      final currentSection = sections[index];
      final nextSection = sections[index + 1];
      if (focalPoint >= nextSection.center) continue;

      final distance = nextSection.center - currentSection.center;
      final progress = distance <= 0
          ? 1.0
          : ((focalPoint - currentSection.center) / distance).clamp(0.0, 1.0);
      final easedProgress = _smoothStep(progress);
      final currentChapter = narrative.chapterFor(SectionId(currentSection.id));
      final nextChapter = narrative.chapterFor(SectionId(nextSection.id));
      final sceneIndex = _sceneIndexFor(currentChapter);
      final nextSceneIndex = _sceneIndexFor(nextChapter);

      return SceneState(
        currentSceneIndex: sceneIndex,
        globalProgress: globalProgress,
        blendFactor: easedProgress,
        blendedConfig: easedProgress == 0
            ? SceneConfigs.scenes[sceneIndex]
            : SceneConfig.lerp(
                SceneConfigs.scenes[sceneIndex],
                SceneConfigs.scenes[nextSceneIndex],
                easedProgress,
              ),
        currentMotif: currentChapter.motif,
        nextMotif: nextChapter.motif,
      );
    }

    final lastSection = sections.last;
    final lastChapter = narrative.chapterFor(SectionId(lastSection.id));
    final lastSceneIndex = _sceneIndexFor(lastChapter);
    return SceneState(
      currentSceneIndex: lastSceneIndex,
      globalProgress: globalProgress,
      blendFactor: 0,
      blendedConfig: SceneConfigs.scenes[lastSceneIndex],
      currentMotif: lastChapter.motif,
      nextMotif: lastChapter.motif,
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

  void recalculate() => _onScroll();

  @override
  Future<void> close() {
    _scrollController.scrollController.removeListener(_onScroll);
    return super.close();
  }
}
