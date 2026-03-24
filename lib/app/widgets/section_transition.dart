import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

// ---------------------------------------------------------------------------
// Shared mixin: scroll-triggered visibility detection
// ---------------------------------------------------------------------------

/// Controls whether a transition replays every time the section scrolls
/// into view or only fires once.
enum TransitionReplayMode {
  /// Animate only on the first scroll-in (default).
  once,

  /// Replay every time the widget enters the viewport.
  everyScroll,
}

/// Reusable mixin that detects when a widget scrolls into the viewport and
/// drives an [AnimationController] accordingly.
///
/// Concrete widgets mix this in and override [buildTransition] to apply their
/// specific visual effect.
mixin _ScrollTriggeredTransition<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late AnimationController transitionController;

  bool _hasTriggered = false;
  ScrollPosition? _scrollPosition;

  // Subclasses must supply these via their widget fields.
  Duration get transitionDuration;
  Duration get transitionDelay;
  Curve get transitionCurve;
  TransitionReplayMode get replayMode;

  /// Fraction of the screen height at which the widget is considered visible.
  double get visibilityThreshold => 0.85;

  @override
  void initState() {
    super.initState();
    transitionController = AnimationController(
      vsync: this,
      duration: transitionDuration,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_onScroll);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);
    transitionController.dispose();
    super.dispose();
  }

  void _onScroll() => _checkVisibility();

  void _checkVisibility() {
    if (!mounted) return;
    if (replayMode == TransitionReplayMode.once && _hasTriggered) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final widgetHeight = renderBox.size.height;

    final isVisible = position.dy < screenHeight * visibilityThreshold &&
        position.dy > -widgetHeight;

    if (isVisible && !transitionController.isAnimating) {
      _hasTriggered = true;
      if (replayMode == TransitionReplayMode.once) {
        _scrollPosition?.removeListener(_onScroll);
      }
      _forward();
    } else if (!isVisible &&
        replayMode == TransitionReplayMode.everyScroll &&
        _hasTriggered) {
      _hasTriggered = false;
      transitionController.reset();
    }
  }

  void _forward() {
    if (transitionDelay == Duration.zero) {
      transitionController.forward();
    } else {
      Future.delayed(transitionDelay, () {
        if (mounted) transitionController.forward();
      });
    }
  }

  /// Compute a 0..1 scroll progress value representing how far the widget
  /// has entered the viewport.  Useful for parallax effects.
  double get scrollProgress {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return 0;
    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.sizeOf(context).height;
    // 1 when fully on screen, 0 when just entering from the bottom.
    final raw = 1.0 - (position.dy / screenHeight);
    return raw.clamp(0.0, 1.0);
  }
}

// ---------------------------------------------------------------------------
// 1. FadeSlideTransition
// ---------------------------------------------------------------------------

/// Section fades in while sliding upward.  The default section reveal.
class FadeSlideTransition extends StatefulWidget {
  const FadeSlideTransition({
    super.key,
    required this.child,
    this.offset = 40.0,
    this.duration = AppDurations.entrance,
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.replayMode = TransitionReplayMode.once,
  });

  final Widget child;

  /// Vertical pixel offset the child starts from (positive = below).
  final double offset;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final TransitionReplayMode replayMode;

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
    with SingleTickerProviderStateMixin, _ScrollTriggeredTransition {
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  Duration get transitionDuration => widget.duration;

  @override
  Duration get transitionDelay => widget.delay;

  @override
  Curve get transitionCurve => widget.curve;

  @override
  TransitionReplayMode get replayMode => widget.replayMode;

  @override
  void initState() {
    super.initState();
    final curved = CurvedAnimation(
      parent: transitionController,
      curve: transitionCurve,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: transitionController,
        builder: (_, child) => Opacity(
          opacity: _opacity.value,
          child: Transform.translate(offset: _slide.value, child: child),
        ),
        child: widget.child,
      );
}

// ---------------------------------------------------------------------------
// 2. ClipRevealTransition
// ---------------------------------------------------------------------------

/// The clip shape used by [ClipRevealTransition].
enum ClipRevealShape {
  /// Circle expanding from the center.
  circleFromCenter,

  /// Horizontal wipe from left to right.
  horizontalWipe,

  /// Horizontal wipe from the center outward.
  horizontalCenterWipe,
}

/// Section reveals via an expanding clip path.
class ClipRevealTransition extends StatefulWidget {
  const ClipRevealTransition({
    super.key,
    required this.child,
    this.shape = ClipRevealShape.circleFromCenter,
    this.duration = AppDurations.slow,
    this.delay = Duration.zero,
    this.curve = Curves.easeInOutCubic,
    this.replayMode = TransitionReplayMode.once,
  });

  final Widget child;
  final ClipRevealShape shape;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final TransitionReplayMode replayMode;

  @override
  State<ClipRevealTransition> createState() => _ClipRevealTransitionState();
}

class _ClipRevealTransitionState extends State<ClipRevealTransition>
    with SingleTickerProviderStateMixin, _ScrollTriggeredTransition {
  late Animation<double> _progress;

  @override
  Duration get transitionDuration => widget.duration;

  @override
  Duration get transitionDelay => widget.delay;

  @override
  Curve get transitionCurve => widget.curve;

  @override
  TransitionReplayMode get replayMode => widget.replayMode;

  @override
  void initState() {
    super.initState();
    _progress = CurvedAnimation(
      parent: transitionController,
      curve: transitionCurve,
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _progress,
        builder: (_, child) => ClipPath(
          clipper: _RevealClipper(
            progress: _progress.value,
            shape: widget.shape,
          ),
          child: child,
        ),
        child: widget.child,
      );
}

class _RevealClipper extends CustomClipper<Path> {
  _RevealClipper({required this.progress, required this.shape});

  final double progress;
  final ClipRevealShape shape;

  @override
  Path getClip(Size size) {
    switch (shape) {
      case ClipRevealShape.circleFromCenter:
        final center = Offset(size.width / 2, size.height / 2);
        final maxRadius =
            math.sqrt(size.width * size.width + size.height * size.height) / 2;
        return Path()
          ..addOval(
            Rect.fromCircle(center: center, radius: maxRadius * progress),
          );

      case ClipRevealShape.horizontalWipe:
        return Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

      case ClipRevealShape.horizontalCenterWipe:
        final halfWidth = size.width / 2 * progress;
        final center = size.width / 2;
        return Path()
          ..addRect(Rect.fromLTRB(
            center - halfWidth,
            0,
            center + halfWidth,
            size.height,
          ));
    }
  }

  @override
  bool shouldReclip(_RevealClipper oldClipper) =>
      progress != oldClipper.progress;
}

// ---------------------------------------------------------------------------
// 3. StaggeredRevealTransition
// ---------------------------------------------------------------------------

/// Wraps a column/row of children so each appears sequentially with a
/// configurable stagger delay.
///
/// Usage:
/// ```dart
/// StaggeredRevealTransition(
///   staggerDelay: AppDurations.staggerShort,
///   children: [WidgetA(), WidgetB(), WidgetC()],
/// )
/// ```
class StaggeredRevealTransition extends StatefulWidget {
  const StaggeredRevealTransition({
    super.key,
    required this.children,
    this.staggerDelay = AppDurations.staggerMedium,
    this.itemDuration = AppDurations.entrance,
    this.initialDelay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.offset = 30.0,
    this.axis = Axis.vertical,
    this.replayMode = TransitionReplayMode.once,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.min,
  });

  final List<Widget> children;
  final Duration staggerDelay;
  final Duration itemDuration;
  final Duration initialDelay;
  final Curve curve;

  /// Slide offset in logical pixels along the main axis.
  final double offset;
  final Axis axis;
  final TransitionReplayMode replayMode;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  State<StaggeredRevealTransition> createState() =>
      _StaggeredRevealTransitionState();
}

class _StaggeredRevealTransitionState extends State<StaggeredRevealTransition>
    with SingleTickerProviderStateMixin, _ScrollTriggeredTransition {
  @override
  Duration get transitionDuration =>
      widget.itemDuration +
      widget.staggerDelay * (widget.children.length - 1).clamp(0, 999);

  @override
  Duration get transitionDelay => widget.initialDelay;

  @override
  Curve get transitionCurve => widget.curve;

  @override
  TransitionReplayMode get replayMode => widget.replayMode;

  @override
  Widget build(BuildContext context) {
    final totalMs = transitionDuration.inMilliseconds;
    final itemMs = widget.itemDuration.inMilliseconds;
    final staggerMs = widget.staggerDelay.inMilliseconds;

    final items = <Widget>[];
    for (var i = 0; i < widget.children.length; i++) {
      final startFraction = (staggerMs * i) / totalMs;
      final endFraction =
          ((staggerMs * i) + itemMs).clamp(0, totalMs) / totalMs;

      final interval = Interval(startFraction, endFraction, curve: widget.curve);

      items.add(
        AnimatedBuilder(
          animation: transitionController,
          builder: (_, child) {
            final t = interval.transform(transitionController.value);
            final slideOffset = widget.axis == Axis.vertical
                ? Offset(0, widget.offset * (1 - t))
                : Offset(widget.offset * (1 - t), 0);
            return Opacity(
              opacity: t,
              child: Transform.translate(offset: slideOffset, child: child),
            );
          },
          child: widget.children[i],
        ),
      );
    }

    return widget.axis == Axis.vertical
        ? Column(
            mainAxisAlignment: widget.mainAxisAlignment,
            crossAxisAlignment: widget.crossAxisAlignment,
            mainAxisSize: widget.mainAxisSize,
            children: items,
          )
        : Row(
            mainAxisAlignment: widget.mainAxisAlignment,
            crossAxisAlignment: widget.crossAxisAlignment,
            mainAxisSize: widget.mainAxisSize,
            children: items,
          );
  }
}

// ---------------------------------------------------------------------------
// 4. ParallaxRevealTransition
// ---------------------------------------------------------------------------

/// Section content has a parallax vertical offset based on scroll position,
/// combined with a fade-in on first appearance.
class ParallaxRevealTransition extends StatefulWidget {
  const ParallaxRevealTransition({
    super.key,
    required this.child,
    this.parallaxFactor = 0.15,
    this.maxParallaxOffset = 60.0,
    this.duration = AppDurations.entrance,
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.replayMode = TransitionReplayMode.once,
  });

  final Widget child;

  /// How strongly the parallax effect is applied (0 = none, 1 = full scroll).
  final double parallaxFactor;

  /// Maximum pixel offset for the parallax shift.
  final double maxParallaxOffset;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final TransitionReplayMode replayMode;

  @override
  State<ParallaxRevealTransition> createState() =>
      _ParallaxRevealTransitionState();
}

class _ParallaxRevealTransitionState extends State<ParallaxRevealTransition>
    with SingleTickerProviderStateMixin, _ScrollTriggeredTransition {
  late Animation<double> _opacity;
  ScrollPosition? _parallaxScrollPosition;

  @override
  Duration get transitionDuration => widget.duration;

  @override
  Duration get transitionDelay => widget.delay;

  @override
  Curve get transitionCurve => widget.curve;

  @override
  TransitionReplayMode get replayMode => widget.replayMode;

  @override
  void initState() {
    super.initState();
    _opacity = CurvedAnimation(
      parent: transitionController,
      curve: transitionCurve,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parallaxScrollPosition?.removeListener(_onParallaxScroll);
    _parallaxScrollPosition = Scrollable.maybeOf(context)?.position;
    _parallaxScrollPosition?.addListener(_onParallaxScroll);
  }

  @override
  void dispose() {
    _parallaxScrollPosition?.removeListener(_onParallaxScroll);
    super.dispose();
  }

  void _onParallaxScroll() {
    if (mounted) setState(() {});
  }

  double get _parallaxOffset {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return 0;

    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.sizeOf(context).height;
    // Center-relative position: 0 at screen center, negative above, positive below.
    final centerRelative =
        (position.dy + renderBox.size.height / 2 - screenHeight / 2) /
            screenHeight;

    return (centerRelative * widget.maxParallaxOffset * widget.parallaxFactor)
        .clamp(-widget.maxParallaxOffset, widget.maxParallaxOffset);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: transitionController,
        builder: (_, child) => Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _parallaxOffset),
            child: child,
          ),
        ),
        child: widget.child,
      );
}

// ---------------------------------------------------------------------------
// 5. BlurRevealTransition
// ---------------------------------------------------------------------------

/// Section starts blurred and sharpens as it enters the viewport, with a
/// simultaneous fade-in.
class BlurRevealTransition extends StatefulWidget {
  const BlurRevealTransition({
    super.key,
    required this.child,
    this.maxBlur = 12.0,
    this.duration = AppDurations.slow,
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.replayMode = TransitionReplayMode.once,
  });

  final Widget child;

  /// Maximum blur sigma when fully hidden.
  final double maxBlur;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final TransitionReplayMode replayMode;

  @override
  State<BlurRevealTransition> createState() => _BlurRevealTransitionState();
}

class _BlurRevealTransitionState extends State<BlurRevealTransition>
    with SingleTickerProviderStateMixin, _ScrollTriggeredTransition {
  late Animation<double> _progress;

  @override
  Duration get transitionDuration => widget.duration;

  @override
  Duration get transitionDelay => widget.delay;

  @override
  Curve get transitionCurve => widget.curve;

  @override
  TransitionReplayMode get replayMode => widget.replayMode;

  @override
  void initState() {
    super.initState();
    _progress = CurvedAnimation(
      parent: transitionController,
      curve: transitionCurve,
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _progress,
        builder: (_, child) {
          final blur = widget.maxBlur * (1 - _progress.value);
          return Opacity(
            opacity: _progress.value,
            child: blur > 0.5
                ? ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: blur,
                      sigmaY: blur,
                      tileMode: TileMode.decal,
                    ),
                    child: child,
                  )
                : child,
          );
        },
        child: widget.child,
      );
}
