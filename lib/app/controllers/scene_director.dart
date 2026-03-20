import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/scene_configs.dart';

/// Scroll-driven scene state machine.
/// Reads scroll offset from AppScrollController and computes:
/// - currentSceneIndex, sceneProgress, globalProgress, blendFactor
/// - blendedConfig (crossfaded SceneConfig between two adjacent scenes)
class SceneDirector extends GetxController {
  static SceneDirector get to => Get.find();

  late final AppScrollController _scrollCtrl;

  // Observable state
  final currentSceneIndex = 0.obs;
  final sceneProgress = 0.0.obs;
  final globalProgress = 0.0.obs;
  final blendFactor = 0.0.obs;
  final Rx<SceneConfig> blendedConfig = SceneConfigs.hero.obs;
  final Rx<Color> currentAccent = SceneConfigs.hero.accent.obs;

  int get _sceneCount => SceneConfigs.scenes.length;
  // Transition zone in pixels where two scenes crossfade
  static const _transitionZone = 200.0;

  @override
  void onInit() {
    super.onInit();
    _scrollCtrl = Get.find<AppScrollController>();
    _scrollCtrl.scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
    _scrollCtrl.scrollController.removeListener(_onScroll);
    super.onClose();
  }

  void _onScroll() {
    final sc = _scrollCtrl.scrollController;
    if (!sc.hasClients) return;

    final offset = sc.offset;
    final maxExtent = sc.position.maxScrollExtent;
    if (maxExtent <= 0) return;

    // Global progress 0.0–1.0
    final gp = (offset / maxExtent).clamp(0.0, 1.0);
    globalProgress.value = gp;

    // Each scene occupies 1/sceneCount of the total scroll
    final sceneSize = maxExtent / _sceneCount;
    final rawScene = offset / sceneSize;
    final sceneIdx = rawScene.floor().clamp(0, _sceneCount - 1);
    final sp = (rawScene - sceneIdx).clamp(0.0, 1.0);

    currentSceneIndex.value = sceneIdx;
    sceneProgress.value = sp;

    // Blend factor: how much of the *next* scene is showing
    // Calculated based on position within transition zone
    final sceneEndPixel = (sceneIdx + 1) * sceneSize;
    final distToEnd = sceneEndPixel - offset;

    var bf = 0.0;
    if (distToEnd < _transitionZone && sceneIdx < _sceneCount - 1) {
      bf = 1.0 - (distToEnd / _transitionZone);
    }
    blendFactor.value = bf.clamp(0.0, 1.0);

    // Compute blended config
    final current = SceneConfigs.scenes[sceneIdx];
    if (bf > 0.001 && sceneIdx < _sceneCount - 1) {
      final next = SceneConfigs.scenes[sceneIdx + 1];
      blendedConfig.value = SceneConfig.lerp(current, next, bf);
    } else {
      blendedConfig.value = current;
    }
    currentAccent.value = blendedConfig.value.accent;
  }

  /// Force recalculate (e.g. after layout)
  void recalculate() => _onScroll();
}
