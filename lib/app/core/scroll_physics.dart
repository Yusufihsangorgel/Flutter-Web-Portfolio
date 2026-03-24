import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

// =============================================================================
// ElasticScrollPhysics
// =============================================================================

/// Rubber-band overscroll physics that stretches content at scroll boundaries
/// and springs back when released.
///
/// On web the default [ClampingScrollPhysics] hard-stops at the edge.  This
/// replaces that behaviour with an iOS-like elastic overscroll that feels more
/// satisfying for a portfolio site.
class ElasticScrollPhysics extends ScrollPhysics {
  const ElasticScrollPhysics({
    super.parent,
    this.elasticity = 0.5,
    this.springStiffness = 200.0,
    this.springDamping = 1.2,
  });

  /// How far the content can stretch beyond the boundary, expressed as a
  /// fraction of the viewport dimension.  A value of 0.5 means the rubber-band
  /// can stretch up to 50 % of the viewport before fully resisting.
  final double elasticity;

  /// Stiffness of the spring that pulls the content back into bounds.
  /// Higher values → snappier return, lower values → more gentle.
  final double springStiffness;

  /// Damping ratio for the spring-back animation.
  /// 1.0 = critically damped (no oscillation), < 1.0 = some bounce.
  final double springDamping;

  @override
  ElasticScrollPhysics applyTo(ScrollPhysics? ancestor) => ElasticScrollPhysics(
        parent: buildParent(ancestor),
        elasticity: elasticity,
        springStiffness: springStiffness,
        springDamping: springDamping,
      );

  @override
  bool get allowImplicitScrolling => false;

  /// Allow overscroll so the rubber-band effect is visible.
  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) => 0.0;

  /// Apply a diminishing-return curve to overscroll so it feels like stretching
  /// a rubber band: quick at first, progressively harder.
  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // Inside valid bounds → pass through unmodified.
    if (!_isOverscrolled(position)) return offset;

    final overscroll = _overscrollAmount(position);
    final viewportDimension = position.viewportDimension;
    final maxStretch = viewportDimension * elasticity;

    // Resistance factor: starts at 1.0 (no resistance) and asymptotically
    // approaches 0.0 as the overscroll nears maxStretch.
    final resistance = 1.0 - math.min(1.0, overscroll / maxStretch);

    // Only dampen the offset that pushes further into overscroll territory.
    final pushingFurther =
        (position.pixels <= position.minScrollExtent && offset > 0) ||
        (position.pixels >= position.maxScrollExtent && offset < 0);

    if (pushingFurther) return offset;

    // Pulling back toward content → no damping needed.
    final pullingBack =
        (position.pixels < position.minScrollExtent && offset < 0) ||
        (position.pixels > position.maxScrollExtent && offset > 0);

    if (pullingBack) return offset;

    return offset * resistance;
  }

  @override
  SpringDescription get spring => SpringDescription(
        mass: 1.0,
        stiffness: springStiffness,
        damping: springDamping *
            2.0 *
            math.sqrt(springStiffness), // convert ratio → absolute damping
      );

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // If overscrolled, return a spring simulation that pulls back to the edge.
    if (position.pixels < position.minScrollExtent) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        position.minScrollExtent,
        velocity,
      );
    }
    if (position.pixels > position.maxScrollExtent) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        position.maxScrollExtent,
        velocity,
      );
    }

    // Otherwise delegate to default clamping / ballistic behaviour.
    return super.createBallisticSimulation(position, velocity);
  }

  bool _isOverscrolled(ScrollMetrics position) =>
      position.pixels < position.minScrollExtent ||
      position.pixels > position.maxScrollExtent;

  double _overscrollAmount(ScrollMetrics position) {
    if (position.pixels < position.minScrollExtent) {
      return position.minScrollExtent - position.pixels;
    }
    if (position.pixels > position.maxScrollExtent) {
      return position.pixels - position.maxScrollExtent;
    }
    return 0.0;
  }
}

// =============================================================================
// SnapScrollPhysics
// =============================================================================

/// Scroll physics that snap to the nearest section boundary after scroll
/// momentum settles.
///
/// Provide either a list of absolute [snapOffsets] or [sectionKeys] whose
/// render-box positions are resolved dynamically.  The snap only triggers when
/// the resting position falls within [snapThreshold] of a snap point (measured
/// as a fraction of the distance between two adjacent snap points).
class SnapScrollPhysics extends ScrollPhysics {
  const SnapScrollPhysics({
    super.parent,
    this.snapOffsets,
    this.sectionKeys,
    this.snapThreshold = 0.30,
    this.snapSpring = const SpringDescription(
      mass: 1.0,
      stiffness: 120.0,
      damping: 20.0,
    ),
  }) : assert(
          snapOffsets != null || sectionKeys != null,
          'Provide either snapOffsets or sectionKeys.',
        );

  /// Absolute pixel offsets to snap to.
  final List<double>? snapOffsets;

  /// Section GlobalKeys whose positions are resolved at snap time.
  final List<GlobalKey>? sectionKeys;

  /// Fraction (0–1) of the inter-section distance within which a snap is
  /// triggered.  0.3 → snaps if within 30 % of section height.
  final double snapThreshold;

  /// Spring used for the snap animation.
  final SpringDescription snapSpring;

  @override
  SnapScrollPhysics applyTo(ScrollPhysics? ancestor) => SnapScrollPhysics(
        parent: buildParent(ancestor),
        snapOffsets: snapOffsets,
        sectionKeys: sectionKeys,
        snapThreshold: snapThreshold,
        snapSpring: snapSpring,
      );

  /// Resolve the effective snap offsets at call time.
  List<double> _resolveOffsets() {
    if (snapOffsets != null && snapOffsets!.isNotEmpty) {
      return List<double>.from(snapOffsets!)..sort();
    }

    if (sectionKeys != null) {
      final offsets = <double>[];
      for (final key in sectionKeys!) {
        final ctx = key.currentContext;
        if (ctx == null) continue;
        final box = ctx.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) continue;
        final position = box.localToGlobal(Offset.zero);
        offsets.add(position.dy);
      }
      offsets.sort();
      return offsets;
    }

    return const [];
  }

  /// Find the snap offset closest to [pixels] and determine whether it is
  /// within the snap threshold.
  double? _closestSnap(double pixels, List<double> offsets) {
    if (offsets.isEmpty) return null;

    var closest = offsets.first;
    var minDistance = (pixels - closest).abs();

    for (var i = 1; i < offsets.length; i++) {
      final distance = (pixels - offsets[i]).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closest = offsets[i];
      }
    }

    // Determine the "section height" context for threshold calculation.
    // Use the distance to the next-nearest snap point as a reference.
    final idx = offsets.indexOf(closest);
    double sectionHeight;
    if (offsets.length == 1) {
      sectionHeight = pixels.abs() + 1; // fallback
    } else if (idx == 0) {
      sectionHeight = offsets[1] - offsets[0];
    } else if (idx == offsets.length - 1) {
      sectionHeight = offsets[idx] - offsets[idx - 1];
    } else {
      sectionHeight = math.min(
        offsets[idx] - offsets[idx - 1],
        offsets[idx + 1] - offsets[idx],
      );
    }

    if (minDistance <= sectionHeight * snapThreshold) {
      return closest;
    }
    return null;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Let the default physics handle out-of-bounds first.
    if (position.pixels < position.minScrollExtent ||
        position.pixels > position.maxScrollExtent) {
      return super.createBallisticSimulation(position, velocity);
    }

    final offsets = _resolveOffsets();
    if (offsets.isEmpty) {
      return super.createBallisticSimulation(position, velocity);
    }

    // Predict where default momentum would settle.
    final defaultSim = super.createBallisticSimulation(position, velocity);
    final predictedEnd = defaultSim != null
        ? _predictEnd(defaultSim, position.pixels)
        : position.pixels;

    final snapTarget = _closestSnap(predictedEnd, offsets);
    if (snapTarget == null) {
      return defaultSim;
    }

    return ScrollSpringSimulation(
      snapSpring,
      position.pixels,
      snapTarget.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
      velocity,
    );
  }

  /// Predict where a simulation would end by stepping a bounded number of
  /// iterations.  This avoids running the sim to completion on infinite
  /// bouncing springs.
  double _predictEnd(Simulation sim, double fallback) {
    var t = 0.0;
    const dt = 1.0 / 60.0;
    const maxSteps = 600; // ~10 s at 60 fps
    for (var i = 0; i < maxSteps; i++) {
      if (sim.isDone(t)) return sim.x(t);
      t += dt;
    }
    return sim.x(t).isFinite ? sim.x(t) : fallback;
  }
}

// =============================================================================
// MomentumScrollPhysics
// =============================================================================

/// Enhanced momentum physics tuned for web.
///
/// The default [ClampingScrollPhysics] uses Android-style deceleration which
/// can feel abrupt on web, especially with trackpad gestures.  This provides:
/// - Configurable friction / deceleration for a more deliberate feel.
/// - Velocity-based duration so flick speed maps to scroll distance naturally.
class MomentumScrollPhysics extends ScrollPhysics {
  const MomentumScrollPhysics({
    super.parent,
    this.friction = 0.025,
    this.minFlingVelocity = 50.0,
    this.maxFlingVelocity = 6000.0,
  });

  /// Friction coefficient applied to the ballistic simulation.
  /// Higher → quicker deceleration.  Default is slightly higher than Flutter's
  /// 0.015 for a more controlled web feel.
  final double friction;

  /// Minimum velocity (px/s) required to trigger a ballistic fling.
  /// Velocities below this are treated as intentional stops.
  @override
  final double minFlingVelocity;

  /// Maximum velocity (px/s) that will be used for the fling.
  /// Caps extremely fast swipes.
  @override
  final double maxFlingVelocity;

  @override
  MomentumScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      MomentumScrollPhysics(
        parent: buildParent(ancestor),
        friction: friction,
        minFlingVelocity: minFlingVelocity,
        maxFlingVelocity: maxFlingVelocity,
      );

  @override
  double get minFlingDistance => 0.0;

  @override
  double get dragStartDistanceMotionThreshold => 3.5;

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Clamp to bounds.
    if (position.pixels <= position.minScrollExtent && velocity <= 0) {
      return null;
    }
    if (position.pixels >= position.maxScrollExtent && velocity >= 0) {
      return null;
    }

    final effectiveVelocity =
        velocity.clamp(-maxFlingVelocity, maxFlingVelocity);

    if (effectiveVelocity.abs() < minFlingVelocity) return null;

    return ClampingScrollSimulation(
      position: position.pixels,
      velocity: effectiveVelocity,
      friction: friction,
    );
  }
}

// =============================================================================
// ScrollVelocityTracker  (GetX-based)
// =============================================================================

/// A GetX service that tracks scroll velocity in real-time and exposes
/// smoothed values for velocity-dependent effects (parallax intensity,
/// motion blur, etc.).
///
/// Usage:
/// ```dart
/// // Register once (e.g. in your bindings):
/// Get.put(ScrollVelocityTracker());
///
/// // Attach to a ScrollController:
/// ScrollVelocityTracker.to.attach(myScrollController);
///
/// // Read reactive values:
/// Obx(() => Text('${ScrollVelocityTracker.to.velocity.value}'));
/// ```
class ScrollVelocityTracker extends GetxController {
  ScrollVelocityTracker({
    this.smoothingFactor = 0.15,
    this.idleThreshold = 5.0,
  });

  static ScrollVelocityTracker get to => Get.find();

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Smoothing factor for the exponential moving average.
  /// 0.0 = no smoothing (raw), 1.0 = fully smoothed (never changes).
  /// 0.15 provides a good balance between responsiveness and noise reduction.
  final double smoothingFactor;

  /// Velocity below this threshold (px/s) is considered idle.
  final double idleThreshold;

  // ---------------------------------------------------------------------------
  // Reactive state
  // ---------------------------------------------------------------------------

  /// Smoothed scroll velocity in logical pixels per second.
  /// Positive = scrolling down, negative = scrolling up.
  final velocity = 0.0.obs;

  /// Absolute (unsigned) smoothed velocity.
  final speed = 0.0.obs;

  /// Current scroll direction.
  final direction = ScrollDirection.idle.obs;

  /// Whether any tracked controller is actively scrolling.
  final isScrolling = false.obs;

  /// Scroll progress of the primary tracked controller: 0.0 at the top,
  /// 1.0 at the bottom.
  final scrollProgress = 0.0.obs;

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  ScrollController? _controller;
  double _lastOffset = 0.0;
  DateTime _lastTimestamp = DateTime.now();
  double _rawVelocity = 0.0;

  /// Attach a [ScrollController] to start tracking.
  void attach(ScrollController controller) {
    detach();
    _controller = controller;
    _lastOffset = controller.hasClients ? controller.offset : 0.0;
    _lastTimestamp = DateTime.now();
    controller.addListener(_onScroll);
  }

  /// Detach the currently tracked controller.
  void detach() {
    _controller?.removeListener(_onScroll);
    _controller = null;
    _reset();
  }

  @override
  void onClose() {
    detach();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Scroll handler
  // ---------------------------------------------------------------------------

  void _onScroll() {
    final controller = _controller;
    if (controller == null || !controller.hasClients) return;

    final now = DateTime.now();
    final dt = now.difference(_lastTimestamp).inMicroseconds / 1e6; // seconds
    if (dt <= 0) return;

    final currentOffset = controller.offset;
    final delta = currentOffset - _lastOffset;

    _rawVelocity = delta / dt;

    // Exponential moving average.
    final smoothed =
        velocity.value * (1.0 - smoothingFactor) + _rawVelocity * smoothingFactor;

    velocity.value = smoothed;
    speed.value = smoothed.abs();

    // Direction.
    if (smoothed.abs() < idleThreshold) {
      direction.value = ScrollDirection.idle;
      isScrolling.value = false;
    } else if (smoothed > 0) {
      direction.value = ScrollDirection.forward; // scrolling down
      isScrolling.value = true;
    } else {
      direction.value = ScrollDirection.reverse; // scrolling up
      isScrolling.value = true;
    }

    // Progress.
    final maxExtent = controller.position.maxScrollExtent;
    if (maxExtent > 0) {
      scrollProgress.value = (currentOffset / maxExtent).clamp(0.0, 1.0);
    }

    _lastOffset = currentOffset;
    _lastTimestamp = now;
  }

  void _reset() {
    velocity.value = 0.0;
    speed.value = 0.0;
    direction.value = ScrollDirection.idle;
    isScrolling.value = false;
    _rawVelocity = 0.0;
  }
}

/// Scroll direction of a tracked controller.
enum ScrollDirection {
  /// Not scrolling or velocity below idle threshold.
  idle,

  /// Scrolling toward higher offsets (downward in a vertical list).
  forward,

  /// Scrolling toward lower offsets (upward in a vertical list).
  reverse,
}
