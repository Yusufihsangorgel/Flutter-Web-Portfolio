import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:flutter_web_portfolio/app/controllers/smooth_scroll_controller.dart';

/// A widget that intercepts scroll input and applies Lenis-style lerp-based
/// smooth scrolling on desktop / web, while preserving native momentum
/// scrolling on touch devices.
///
/// Wrap this around the root scrollable content of a page. It uses a [Ticker]
/// to drive a frame-perfect interpolation loop (equivalent to
/// `requestAnimationFrame` on the web).
///
/// ```dart
/// SmoothScrollWrapper(
///   child: CustomScrollView(
///     controller: scrollController,
///     slivers: [ ... ],
///   ),
/// )
/// ```
class SmoothScrollWrapper extends StatefulWidget {
  const SmoothScrollWrapper({
    super.key,
    required this.child,
    this.lerpFactor = 0.08,
    this.scrollMultiplier = 1.0,
    this.maxVelocity = 150.0,
    this.enableKeyboard = true,
    this.keyboardScrollAmount = 100.0,
    this.pageScrollMultiplier = 5.0,
  });

  /// The scrollable content to wrap.
  final Widget child;

  /// Interpolation factor per frame. Lower = smoother. 0.08 is buttery.
  final double lerpFactor;

  /// Multiplier applied to raw scroll deltas.
  final double scrollMultiplier;

  /// Maximum velocity cap in logical pixels per frame.
  final double maxVelocity;

  /// Whether to handle keyboard scroll events (arrows, Page Up/Down, Home/End).
  final bool enableKeyboard;

  /// Pixels scrolled per arrow-key press.
  final double keyboardScrollAmount;

  /// Multiplier on [keyboardScrollAmount] for Page Up / Page Down.
  final double pageScrollMultiplier;

  @override
  State<SmoothScrollWrapper> createState() => _SmoothScrollWrapperState();
}

class _SmoothScrollWrapperState extends State<SmoothScrollWrapper>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final SmoothScrollController _ctrl;
  final FocusNode _focusNode = FocusNode();

  /// True when the ticker is currently active (ticking).
  bool _isTicking = false;

  /// Whether the current platform should use smooth scrolling.
  /// Touch-primary devices (phones, tablets) keep native scroll.
  bool get _useSmoothScroll => kIsWeb && !_isTouchDevice;

  /// Simple heuristic: treat narrow viewports as touch devices.
  /// On web, window.navigator.maxTouchPoints is not easily accessible from
  /// Dart, so we fall back to a width breakpoint. This also covers the
  /// Chrome DevTools mobile emulator.
  bool get _isTouchDevice {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide < 600;
  }

  @override
  void initState() {
    super.initState();

    // Ensure the SmoothScrollController is registered and configured.
    if (!Get.isRegistered<SmoothScrollController>()) {
      Get.put(
        SmoothScrollController(
          lerpFactor: widget.lerpFactor,
          scrollMultiplier: widget.scrollMultiplier,
          maxVelocity: widget.maxVelocity,
        ),
        permanent: true,
      );
    }
    _ctrl = Get.find<SmoothScrollController>();

    // Apply configuration (in case the controller was already registered with
    // different defaults).
    _ctrl
      ..lerpFactor = widget.lerpFactor
      ..scrollMultiplier = widget.scrollMultiplier
      ..maxVelocity = widget.maxVelocity;

    // The ticker drives our per-frame lerp loop.
    _ticker = createTicker(_onTick);

    // Sync after first layout so _currentOffset matches reality.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.syncOffsets();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Ticker
  // ---------------------------------------------------------------------------

  void _ensureTicking() {
    if (!_isTicking && _useSmoothScroll) {
      _isTicking = true;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final needsMore = _ctrl.tick();
    if (!needsMore) {
      _ticker.stop();
      _isTicking = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Pointer / scroll events
  // ---------------------------------------------------------------------------

  void _onPointerSignal(PointerSignalEvent event) {
    if (!_useSmoothScroll) return;

    if (event is PointerScrollEvent) {
      // Consume the event so the default Flutter scroll handler doesn't fire.
      // On web, Listener receives the raw event before the Scrollable.
      _ctrl.smoothScrollBy(event.scrollDelta.dy);
      _ensureTicking();
    }
  }

  // ---------------------------------------------------------------------------
  // Keyboard navigation
  // ---------------------------------------------------------------------------

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (!_useSmoothScroll) return KeyEventResult.ignored;
    if (!widget.enableKeyboard) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    double? delta;

    if (key == LogicalKeyboardKey.arrowDown) {
      delta = widget.keyboardScrollAmount;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      delta = -widget.keyboardScrollAmount;
    } else if (key == LogicalKeyboardKey.pageDown) {
      delta = widget.keyboardScrollAmount * widget.pageScrollMultiplier;
    } else if (key == LogicalKeyboardKey.pageUp) {
      delta = -widget.keyboardScrollAmount * widget.pageScrollMultiplier;
    } else if (key == LogicalKeyboardKey.home) {
      _ctrl.scrollTo(0);
      _ensureTicking();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.end) {
      // Scroll to the very end.
      _ctrl.scrollTo(double.maxFinite); // clamped inside controller
      _ensureTicking();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.space) {
      // Space scrolls down by roughly one viewport height.
      final height = MediaQuery.of(context).size.height;
      final isShift = HardwareKeyboard.instance.isShiftPressed;
      delta = isShift ? -height * 0.85 : height * 0.85;
    }

    if (delta != null) {
      _ctrl.smoothScrollBy(delta);
      _ensureTicking();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // On touch / mobile: just render the child with native scroll.
    if (!_useSmoothScroll) {
      return widget.child;
    }

    // Desktop / web: intercept pointer signals and keyboard, drive lerp loop.
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Listener(
        onPointerSignal: _onPointerSignal,
        // We use behavior opaque so the Listener captures events even over
        // child hit-test areas (buttons, links, etc.).
        behavior: HitTestBehavior.opaque,
        child: _ScrollPhysicsOverride(
          child: widget.child,
        ),
      ),
    );
  }
}

/// Overrides the scroll physics of any descendant [Scrollable] to
/// [NeverScrollableScrollPhysics] so that the default scroll handler
/// doesn't compete with our manual `jumpTo` calls.
///
/// This keeps the [ScrollController] functional (we can still jumpTo / animateTo)
/// while preventing Flutter from processing the same pointer-scroll events
/// that we already handle in [Listener.onPointerSignal].
class _ScrollPhysicsOverride extends StatelessWidget {
  const _ScrollPhysicsOverride({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ScrollConfiguration(
        behavior: _NoScrollBehavior(),
        child: child,
      );
}

/// A [ScrollBehavior] that disables default scroll-event handling by applying
/// [NeverScrollableScrollPhysics], but preserves platform-appropriate
/// decorations (scrollbars, overscroll indicators, etc.).
class _NoScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const NeverScrollableScrollPhysics();

  // Remove the default drag devices so trackpad two-finger gestures don't
  // trigger Flutter's built-in scroll. Our Listener handles them.
  @override
  Set<PointerDeviceKind> get dragDevices => const {};
}
