import 'package:flutter/material.dart';
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

  Color get currentAccent => blendedConfig.accent;

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
/// from rebuilding as the cinematic background moves.
final class SceneDirector extends Cubit<SceneState> {
  SceneDirector({required AppScrollController scrollController})
    : _scrollController = scrollController,
      super(const SceneState.initial()) {
    _scrollController.scrollController.addListener(_onScroll);
  }

  final AppScrollController _scrollController;

  int get _sceneCount => SceneConfigs.scenes.length;
  static const _transitionZone = 200.0;

  void _onScroll() {
    final scroll = _scrollController.scrollController;
    if (!scroll.hasClients) return;

    final offset = scroll.offset;
    final maxExtent = scroll.position.maxScrollExtent;
    if (maxExtent <= 0) return;

    final globalProgress = (offset / maxExtent).clamp(0.0, 1.0);
    final sceneSize = maxExtent / _sceneCount;
    final rawScene = offset / sceneSize;
    final sceneIndex = rawScene.floor().clamp(0, _sceneCount - 1);
    final sceneProgress = (rawScene - sceneIndex).clamp(0.0, 1.0);

    final sceneEndPixel = (sceneIndex + 1) * sceneSize;
    final distanceToEnd = sceneEndPixel - offset;
    var blendFactor = 0.0;
    if (distanceToEnd < _transitionZone && sceneIndex < _sceneCount - 1) {
      blendFactor = 1 - (distanceToEnd / _transitionZone);
    }
    blendFactor = blendFactor.clamp(0.0, 1.0);

    final current = SceneConfigs.scenes[sceneIndex];
    final blendedConfig = blendFactor > 0.001 && sceneIndex < _sceneCount - 1
        ? SceneConfig.lerp(
            current,
            SceneConfigs.scenes[sceneIndex + 1],
            blendFactor,
          )
        : current;

    emit(
      SceneState(
        currentSceneIndex: sceneIndex,
        sceneProgress: sceneProgress,
        globalProgress: globalProgress,
        blendFactor: blendFactor,
        blendedConfig: blendedConfig,
      ),
    );
  }

  void recalculate() => _onScroll();

  @override
  Future<void> close() {
    _scrollController.scrollController.removeListener(_onScroll);
    return super.close();
  }
}
