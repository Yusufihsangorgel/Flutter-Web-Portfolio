import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/scene_configs.dart';

@immutable
final class SceneState {
  const SceneState({
    required this.currentSceneIndex,
    required this.sceneProgress,
    required this.globalProgress,
    required this.blendFactor,
    required this.blendedConfig,
  });

  const SceneState.initial()
    : currentSceneIndex = 0,
      sceneProgress = 0,
      globalProgress = 0,
      blendFactor = 0,
      blendedConfig = SceneConfigs.hero;

  final int currentSceneIndex;
  final double sceneProgress;
  final double globalProgress;
  final double blendFactor;
  final SceneConfig blendedConfig;

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
          sceneProgress == other.sceneProgress &&
          globalProgress == other.globalProgress &&
          blendFactor == other.blendFactor &&
          blendedConfig == other.blendedConfig;

  @override
  int get hashCode => Object.hash(
    currentSceneIndex,
    sceneProgress,
    globalProgress,
    blendFactor,
    blendedConfig,
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
      super(const SceneState.initial()) {
    _scrollController.scrollController.addListener(_onScroll);
  }

  final AppScrollController _scrollController;
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
  }) {
    if (sections.isEmpty) return const SceneState.initial();

    final safeMaxExtent = maxExtent <= 0 ? 1.0 : maxExtent;
    final globalProgress = (offset / safeMaxExtent).clamp(0.0, 1.0);
    final focalPoint = offset + viewportDimension * 0.44;

    if (sections.length == 1 || focalPoint <= sections.first.center) {
      final sceneIndex = _sceneIndexFor(sections.first.id);
      return SceneState(
        currentSceneIndex: sceneIndex,
        sceneProgress: 0,
        globalProgress: globalProgress,
        blendFactor: 0,
        blendedConfig: SceneConfigs.scenes[sceneIndex],
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
      final sceneIndex = _sceneIndexFor(currentSection.id);
      final nextSceneIndex = _sceneIndexFor(nextSection.id);

      return SceneState(
        currentSceneIndex: sceneIndex,
        sceneProgress: progress,
        globalProgress: globalProgress,
        blendFactor: easedProgress,
        blendedConfig: easedProgress == 0
            ? SceneConfigs.scenes[sceneIndex]
            : SceneConfig.lerp(
                SceneConfigs.scenes[sceneIndex],
                SceneConfigs.scenes[nextSceneIndex],
                easedProgress,
              ),
      );
    }

    final lastSection = sections.last;
    final lastSceneIndex = _sceneIndexFor(lastSection.id);
    final documentEnd = maxExtent + viewportDimension;
    final remainingDistance = documentEnd - lastSection.center;
    final tailProgress = remainingDistance <= 0
        ? 1.0
        : ((focalPoint - lastSection.center) / remainingDistance).clamp(
            0.0,
            1.0,
          );
    return SceneState(
      currentSceneIndex: lastSceneIndex,
      sceneProgress: tailProgress,
      globalProgress: globalProgress,
      blendFactor: 0,
      blendedConfig: SceneConfigs.scenes[lastSceneIndex],
    );
  }

  static int _sceneIndexFor(String sectionId) => switch (sectionId) {
    'about' => 1,
    'experience' => 2,
    'proof' => 3,
    'projects' => 4,
    _ => 0,
  };

  static double _smoothStep(double value) => value * value * (3 - 2 * value);

  void recalculate() => _onScroll();

  @override
  Future<void> close() {
    _scrollController.scrollController.removeListener(_onScroll);
    return super.close();
  }
}
