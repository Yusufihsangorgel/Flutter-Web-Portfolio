import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';

/// Scroll direction relative to the viewport.
enum SmoothScrollDirection { idle, down, up }

/// GetX controller that manages smooth-scroll state globally.
///
/// Exposes reactive scroll velocity, progress (0-1), and direction so that
/// any widget in the tree can drive velocity-dependent effects (parallax,
/// skew, blur, etc.) without coupling to the widget layer.
class SmoothScrollController extends GetxController {
  SmoothScrollController({
    this.lerpFactor = 0.08,
    this.scrollMultiplier = 1.0,
    this.maxVelocity = 150.0,
  });

  static SmoothScrollController get to => Get.find();

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Linear interpolation factor per frame. Lower = smoother / more inertia.
  /// 0.08 gives a Lenis-like buttery feel at 60 fps.
  double lerpFactor;

  /// Multiplier applied to incoming scroll deltas (mouse wheel / trackpad).
  double scrollMultiplier;

  /// Maximum allowed velocity (pixels/frame). Prevents insane flick speeds.
  double maxVelocity;

  // ---------------------------------------------------------------------------
  // Observable state
  // ---------------------------------------------------------------------------

  /// Instantaneous scroll velocity in logical pixels per frame.
  final velocity = 0.0.obs;

  /// Normalized scroll progress: 0.0 at top, 1.0 at maxScrollExtent.
  final progress = 0.0.obs;

  /// Current scroll direction (idle when velocity ~ 0).
  final direction = SmoothScrollDirection.idle.obs;

  /// Whether smooth scrolling is actively running.
  final isScrolling = false.obs;

  /// When true the lerp loop is paused (e.g. during programmatic animateTo).
  final isPaused = false.obs;

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------

  /// The "desired" scroll position we are interpolating towards.
  double _targetOffset = 0.0;

  /// The last rendered scroll position (what the ScrollController is at).
  double _currentOffset = 0.0;

  /// Reference to the project's existing scroll controller.
  late final AppScrollController _appScrollCtrl;

  ScrollController get _scrollController => _appScrollCtrl.scrollController;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _appScrollCtrl = Get.find<AppScrollController>();

    // Sync internal offsets when the scroll controller already has a position.
    if (_scrollController.hasClients) {
      _currentOffset = _scrollController.offset;
      _targetOffset = _currentOffset;
    }

    // Keep in sync if something else drives the controller (e.g. scrollToSection).
    _scrollController.addListener(_onExternalScroll);
  }

  @override
  void onClose() {
    _scrollController.removeListener(_onExternalScroll);
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // External scroll listener
  // ---------------------------------------------------------------------------

  /// When the AppScrollController drives an animateTo (section navigation),
  /// we must keep our internal target in sync so we don't fight it.
  void _onExternalScroll() {
    if (isPaused.value && _scrollController.hasClients) {
      _currentOffset = _scrollController.offset;
      _targetOffset = _currentOffset;
      _updateProgress();
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Add a scroll delta (positive = scroll down). Called by the widget layer
  /// when it intercepts a pointer-scroll or keyboard event.
  void smoothScrollBy(double delta) {
    if (isPaused.value) return;
    if (!_scrollController.hasClients) return;

    final maxExtent = _scrollController.position.maxScrollExtent;
    _targetOffset += delta * scrollMultiplier;
    _targetOffset = _targetOffset.clamp(0.0, maxExtent);
  }

  /// Jump the target to a specific offset and let the lerp catch up.
  void scrollTo(double offset) {
    if (!_scrollController.hasClients) return;

    final maxExtent = _scrollController.position.maxScrollExtent;
    _targetOffset = offset.clamp(0.0, maxExtent);
  }

  /// Convenience: scroll to a named section via [AppScrollController].
  /// Pauses smooth scroll while the built-in animateTo runs, then resumes.
  void scrollToSection(String sectionId) {
    pause();
    _appScrollCtrl.scrollToSection(sectionId);

    // Resume after the section scroll finishes.
    Future.delayed(const Duration(milliseconds: 1000), resume);
  }

  /// Pause the lerp loop (e.g. while a programmatic animation is active).
  void pause() {
    isPaused.value = true;
  }

  /// Resume the lerp loop and re-sync offsets.
  void resume() {
    if (_scrollController.hasClients) {
      _currentOffset = _scrollController.offset;
      _targetOffset = _currentOffset;
    }
    isPaused.value = false;
  }

  /// Sync offsets to the current scroll position. Useful after layout changes.
  void syncOffsets() {
    if (!_scrollController.hasClients) return;
    _currentOffset = _scrollController.offset;
    _targetOffset = _currentOffset;
    _updateProgress();
  }

  // ---------------------------------------------------------------------------
  // Frame tick  (called by SmoothScrollWrapper's Ticker)
  // ---------------------------------------------------------------------------

  /// Advance the smooth scroll by one frame. Returns true if the scroll
  /// position was updated (so the caller knows whether to keep ticking).
  bool tick() {
    if (isPaused.value) return false;
    if (!_scrollController.hasClients) return false;

    final maxExtent = _scrollController.position.maxScrollExtent;
    _targetOffset = _targetOffset.clamp(0.0, maxExtent);

    // Lerp towards target.
    final diff = _targetOffset - _currentOffset;

    // Clamp velocity.
    final clampedDiff = diff.abs() > maxVelocity
        ? maxVelocity * diff.sign
        : diff;

    final step = clampedDiff * lerpFactor;

    // If the remaining distance is sub-pixel, snap and stop.
    if (step.abs() < 0.5) {
      if (diff.abs() > 0.5) {
        // Still a small gap; snap to target.
        _currentOffset = _targetOffset;
        _applyScroll();
      }
      velocity.value = 0.0;
      direction.value = SmoothScrollDirection.idle;
      isScrolling.value = false;
      return false;
    }

    _currentOffset += step;
    velocity.value = step;
    direction.value =
        step > 0 ? SmoothScrollDirection.down : SmoothScrollDirection.up;
    isScrolling.value = true;

    _applyScroll();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _applyScroll() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_currentOffset);
    _updateProgress();
  }

  void _updateProgress() {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    progress.value =
        maxExtent > 0 ? (_currentOffset / maxExtent).clamp(0.0, 1.0) : 0.0;
  }
}
