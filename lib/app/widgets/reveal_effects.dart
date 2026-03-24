import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

// ---------------------------------------------------------------------------
// 1. SpotlightReveal — cursor-following spotlight over dark overlay
// ---------------------------------------------------------------------------

/// Covers [child] with a dark overlay and cuts a circular spotlight that
/// follows the mouse cursor, revealing the content beneath.
///
/// The spotlight smoothly tracks the pointer with a lerp-based delay and
/// expands on hover / contracts on exit.
class SpotlightReveal extends StatefulWidget {
  const SpotlightReveal({
    super.key,
    required this.child,
    this.spotlightRadius = 150.0,
    this.overlayOpacity = 0.80,
    this.overlayColor = Colors.black,
    this.featherWidth = 40.0,
    this.followSpeed = 0.08,
    this.expandDuration = AppDurations.normal,
    this.expandCurve = CinematicCurves.revealDecel,
  });

  final Widget child;

  /// Radius of the clear spotlight circle in logical pixels.
  final double spotlightRadius;

  /// Opacity of the dark overlay surrounding the spotlight.
  final double overlayOpacity;

  /// Color of the overlay (typically black).
  final Color overlayColor;

  /// Width of the feathered gradient edge from clear to dark.
  final double featherWidth;

  /// Lerp speed per frame for smooth follow (0–1, lower = more lag).
  final double followSpeed;

  /// Duration of the expand / contract animation.
  final Duration expandDuration;

  /// Curve for the expand / contract animation.
  final Curve expandCurve;

  @override
  State<SpotlightReveal> createState() => _SpotlightRevealState();
}

class _SpotlightRevealState extends State<SpotlightReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _radiusController;
  late Animation<double> _radiusAnim;

  Offset _targetPos = Offset.zero;
  Offset _currentPos = Offset.zero;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _radiusController = AnimationController(
      vsync: this,
      duration: widget.expandDuration,
    );
    _radiusAnim = Tween<double>(begin: 0.0, end: widget.spotlightRadius)
        .animate(CurvedAnimation(
      parent: _radiusController,
      curve: widget.expandCurve,
    ));
    _radiusController.addListener(_markDirty);
  }

  void _markDirty() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _radiusController
      ..removeListener(_markDirty)
      ..dispose();
    super.dispose();
  }

  void _onHover(PointerEvent event) {
    _targetPos = event.localPosition;
    if (!_hovering) {
      _hovering = true;
      _currentPos = _targetPos;
      _radiusController.forward();
    }
    _scheduleFollow();
  }

  void _onExit(PointerEvent _) {
    _hovering = false;
    _radiusController.reverse();
  }

  bool _followScheduled = false;

  void _scheduleFollow() {
    if (_followScheduled) return;
    _followScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _followScheduled = false;
      if (!mounted || !_hovering) return;
      setState(() {
        _currentPos = Offset.lerp(_currentPos, _targetPos, widget.followSpeed)!;
      });
      if ((_currentPos - _targetPos).distance > 0.5) {
        _scheduleFollow();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onHover,
      onExit: _onExit,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SpotlightPainter(
                  center: _currentPos,
                  radius: _radiusAnim.value,
                  featherWidth: widget.featherWidth,
                  overlayColor:
                      widget.overlayColor.withValues(alpha: widget.overlayOpacity),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.center,
    required this.radius,
    required this.featherWidth,
    required this.overlayColor,
  });

  final Offset center;
  final double radius;
  final double featherWidth;
  final Color overlayColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = overlayColor,
      );
      return;
    }

    // Save layer so we can punch a hole with BlendMode.dstOut.
    canvas.saveLayer(Offset.zero & size, Paint());

    // Draw the full overlay.
    canvas.drawRect(Offset.zero & size, Paint()..color = overlayColor);

    // Punch a feathered circular hole.
    final holePaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..shader = ui.Gradient.radial(
        center,
        radius + featherWidth,
        [
          Colors.white,
          Colors.white,
          Colors.white.withValues(alpha: 0.0),
        ],
        [
          0.0,
          radius / (radius + featherWidth),
          1.0,
        ],
      );
    canvas.drawCircle(center, radius + featherWidth, holePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      center != old.center ||
      radius != old.radius ||
      featherWidth != old.featherWidth ||
      overlayColor != old.overlayColor;
}

// ---------------------------------------------------------------------------
// 2. ScrollRevealMask — content revealed by scroll progress
// ---------------------------------------------------------------------------

/// The direction in which the mask wipes away to reveal content.
enum RevealDirection { leftToRight, rightToLeft, topToBottom, bottomToTop }

/// The shape used for the reveal mask.
enum RevealShape { rectangle, circle, polygon }

/// Masks [child] and reveals it as the user scrolls the widget into view.
///
/// The mask slides away in the configured [direction] using a clip path of
/// the chosen [shape]. By default the reveal only happens once; set
/// [reHideOnScrollBack] to `true` to reverse when scrolling away.
class ScrollRevealMask extends StatefulWidget {
  const ScrollRevealMask({
    super.key,
    required this.child,
    this.direction = RevealDirection.leftToRight,
    this.shape = RevealShape.rectangle,
    this.revealSpeed = 1.0,
    this.reHideOnScrollBack = false,
    this.visibilityThreshold = 0.85,
    this.duration = AppDurations.slow,
    this.curve = CinematicCurves.revealDecel,
  });

  final Widget child;

  /// Direction of the wipe.
  final RevealDirection direction;

  /// Shape of the clip mask.
  final RevealShape shape;

  /// Multiplier applied to scroll-driven reveal speed.
  final double revealSpeed;

  /// When `true`, content re-hides when scrolled back out of view.
  final bool reHideOnScrollBack;

  /// Fraction of viewport height at which reveal triggers (0–1).
  final double visibilityThreshold;

  /// Duration of the reveal animation.
  final Duration duration;

  /// Curve of the reveal animation.
  final Curve curve;

  @override
  State<ScrollRevealMask> createState() => _ScrollRevealMaskState();
}

class _ScrollRevealMaskState extends State<ScrollRevealMask>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;
  bool _revealed = false;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _progress = CurvedAnimation(parent: _controller, curve: widget.curve);

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_checkVisibility);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_checkVisibility);
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_checkVisibility);
    _controller.dispose();
    super.dispose();
  }

  void _checkVisibility() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final pos = box.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final visible = pos.dy < screenHeight * widget.visibilityThreshold &&
        pos.dy > -box.size.height;

    if (visible && !_revealed) {
      _revealed = true;
      _controller.forward();
    } else if (!visible && _revealed && widget.reHideOnScrollBack) {
      _revealed = false;
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (_, child) => ClipPath(
        clipper: _RevealClipper(
          progress: _progress.value,
          direction: widget.direction,
          shape: widget.shape,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _RevealClipper extends CustomClipper<Path> {
  _RevealClipper({
    required this.progress,
    required this.direction,
    required this.shape,
  });

  final double progress;
  final RevealDirection direction;
  final RevealShape shape;

  @override
  Path getClip(Size size) {
    if (progress >= 1.0) {
      return Path()..addRect(Offset.zero & size);
    }
    if (progress <= 0.0) {
      return Path();
    }

    switch (shape) {
      case RevealShape.rectangle:
        return _rectClip(size);
      case RevealShape.circle:
        return _circleClip(size);
      case RevealShape.polygon:
        return _polygonClip(size);
    }
  }

  Path _rectClip(Size size) {
    switch (direction) {
      case RevealDirection.leftToRight:
        return Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
      case RevealDirection.rightToLeft:
        final x = size.width * (1 - progress);
        return Path()
          ..addRect(Rect.fromLTWH(x, 0, size.width * progress, size.height));
      case RevealDirection.topToBottom:
        return Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height * progress));
      case RevealDirection.bottomToTop:
        final y = size.height * (1 - progress);
        return Path()
          ..addRect(Rect.fromLTWH(0, y, size.width, size.height * progress));
    }
  }

  Path _circleClip(Size size) {
    final center = size.center(Offset.zero);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;
    return Path()..addOval(Rect.fromCircle(
      center: center,
      radius: maxRadius * progress,
    ));
  }

  Path _polygonClip(Size size) {
    // Diamond / rhombus expanding from center.
    final cx = size.width / 2;
    final cy = size.height / 2;
    final dx = cx * progress;
    final dy = cy * progress;
    return Path()
      ..moveTo(cx, cy - dy)
      ..lineTo(cx + dx, cy)
      ..lineTo(cx, cy + dy)
      ..lineTo(cx - dx, cy)
      ..close();
  }

  @override
  bool shouldReclip(_RevealClipper old) =>
      progress != old.progress ||
      direction != old.direction ||
      shape != old.shape;
}

// ---------------------------------------------------------------------------
// 3. TextHighlightReveal — animated marker highlight behind text
// ---------------------------------------------------------------------------

/// Renders [text] and on scroll-into-view sweeps a coloured highlight
/// rectangle behind each line from left to right, like a marker pen.
///
/// Each line is staggered by [lineStaggerDelay].
class TextHighlightReveal extends StatefulWidget {
  const TextHighlightReveal({
    super.key,
    required this.text,
    required this.style,
    this.highlightColor = const Color(0xFFFDE68A), // warm yellow
    this.highlightOpacity = 0.55,
    this.highlightHeightFactor = 0.40,
    this.highlightVerticalAlign = 0.85,
    this.lineStaggerDelay = AppDurations.staggerShort,
    this.sweepDuration = AppDurations.entrance,
    this.curve = CinematicCurves.revealDecel,
    this.textAlign = TextAlign.left,
    this.visibilityThreshold = 0.85,
  });

  final String text;
  final TextStyle style;

  /// The highlight color drawn behind each text line.
  final Color highlightColor;

  /// Opacity of the highlight rectangles.
  final double highlightOpacity;

  /// Height of the highlight as a fraction of line height.
  final double highlightHeightFactor;

  /// Vertical position of the highlight within the line (0 = top, 1 = bottom).
  final double highlightVerticalAlign;

  /// Delay between each successive line's highlight animation.
  final Duration lineStaggerDelay;

  /// Duration of each line's sweep animation.
  final Duration sweepDuration;

  /// Curve applied to each line's sweep.
  final Curve curve;

  /// Text alignment.
  final TextAlign textAlign;

  /// Fraction of viewport height at which animation triggers.
  final double visibilityThreshold;

  @override
  State<TextHighlightReveal> createState() => _TextHighlightRevealState();
}

class _TextHighlightRevealState extends State<TextHighlightReveal>
    with TickerProviderStateMixin {
  final GlobalKey _textKey = GlobalKey();
  List<AnimationController> _controllers = [];
  List<Animation<double>> _sweeps = [];
  bool _triggered = false;
  ScrollPosition? _scrollPosition;
  int _lineCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_checkVisibility);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_checkVisibility);
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_checkVisibility);
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _checkVisibility() {
    if (_triggered || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final pos = box.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.sizeOf(context).height;

    if (pos.dy < screenHeight * widget.visibilityThreshold &&
        pos.dy > -box.size.height) {
      _triggered = true;
      _scrollPosition?.removeListener(_checkVisibility);
      _initAnimations();
    }
  }

  void _initAnimations() {
    // Measure the text to determine line count.
    final renderBox =
        _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textAlign: widget.textAlign,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: renderBox.size.width);

    _lineCount = textPainter.computeLineMetrics().length;
    if (_lineCount == 0) return;

    // Create staggered controllers.
    _controllers = List.generate(_lineCount, (i) {
      return AnimationController(vsync: this, duration: widget.sweepDuration);
    });
    _sweeps = _controllers.map((c) {
      return CurvedAnimation(parent: c, curve: widget.curve);
    }).toList();

    for (var i = 0; i < _lineCount; i++) {
      Future.delayed(widget.lineStaggerDelay * i, () {
        if (mounted) _controllers[i].forward();
      });
    }

    // Force rebuild to show highlights.
    for (final c in _controllers) {
      c.addListener(_markDirty);
    }
    setState(() {});
  }

  void _markDirty() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkVisibility());

    return CustomPaint(
      foregroundPainter: _lineCount > 0
          ? _HighlightPainter(
              text: widget.text,
              style: widget.style,
              textAlign: widget.textAlign,
              sweeps: _sweeps.map((a) => a.value).toList(),
              color: widget.highlightColor
                  .withValues(alpha: widget.highlightOpacity),
              heightFactor: widget.highlightHeightFactor,
              verticalAlign: widget.highlightVerticalAlign,
            )
          : null,
      child: Text(
        widget.text,
        key: _textKey,
        style: widget.style,
        textAlign: widget.textAlign,
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter({
    required this.text,
    required this.style,
    required this.textAlign,
    required this.sweeps,
    required this.color,
    required this.heightFactor,
    required this.verticalAlign,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final List<double> sweeps;
  final Color color;
  final double heightFactor;
  final double verticalAlign;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    final metrics = tp.computeLineMetrics();
    final paint = Paint()..color = color;

    for (var i = 0; i < metrics.length && i < sweeps.length; i++) {
      final line = metrics[i];
      final progress = sweeps[i];
      if (progress <= 0) continue;

      final lineHeight = line.height;
      final highlightH = lineHeight * heightFactor;
      final top =
          line.baseline - lineHeight + (lineHeight - highlightH) * verticalAlign;
      final left = line.left;
      final width = line.width * progress;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, width, highlightH),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HighlightPainter old) => true;
}

// ---------------------------------------------------------------------------
// 4. ImageReveal — image with sliding overlay reveal + zoom
// ---------------------------------------------------------------------------

/// The direction from which the overlay slides away.
enum ImageRevealDirection { leftToRight, rightToLeft, topToBottom, bottomToTop }

/// Trigger mechanism for the image reveal.
enum ImageRevealTrigger { scroll, hover }

/// Hides [child] (typically an image) behind a coloured overlay that slides
/// away on scroll or hover, revealing the image with a subtle zoom.
class ImageReveal extends StatefulWidget {
  const ImageReveal({
    super.key,
    required this.child,
    this.overlayColor = const Color(0xFF1A1A2E),
    this.direction = ImageRevealDirection.leftToRight,
    this.trigger = ImageRevealTrigger.scroll,
    this.duration = AppDurations.slow,
    this.curve = CinematicCurves.dramaticEntrance,
    this.zoomScale = 1.08,
    this.visibilityThreshold = 0.85,
  });

  final Widget child;

  /// Color of the overlay that hides the image.
  final Color overlayColor;

  /// Direction the overlay slides away.
  final ImageRevealDirection direction;

  /// Whether the reveal is triggered by scroll or hover.
  final ImageRevealTrigger trigger;

  /// Duration of the reveal animation.
  final Duration duration;

  /// Curve of the reveal animation.
  final Curve curve;

  /// Scale the image zooms from during reveal (1.0 = no zoom).
  final double zoomScale;

  /// Fraction of viewport at which scroll trigger fires.
  final double visibilityThreshold;

  @override
  State<ImageReveal> createState() => _ImageRevealState();
}

class _ImageRevealState extends State<ImageReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;
  late Animation<double> _zoom;
  bool _triggered = false;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _progress = CurvedAnimation(parent: _controller, curve: widget.curve);
    _zoom = Tween<double>(begin: widget.zoomScale, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: CinematicCurves.revealDecel),
    );

    if (widget.trigger == ImageRevealTrigger.scroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.trigger == ImageRevealTrigger.scroll) {
      _scrollPosition?.removeListener(_checkVisibility);
      _scrollPosition = Scrollable.maybeOf(context)?.position;
      _scrollPosition?.addListener(_checkVisibility);
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_checkVisibility);
    _controller.dispose();
    super.dispose();
  }

  void _checkVisibility() {
    if (_triggered || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final pos = box.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.sizeOf(context).height;

    if (pos.dy < screenHeight * widget.visibilityThreshold &&
        pos.dy > -box.size.height) {
      _triggered = true;
      _scrollPosition?.removeListener(_checkVisibility);
      _controller.forward();
    }
  }

  void _onEnter(PointerEvent _) {
    if (widget.trigger == ImageRevealTrigger.hover && !_triggered) {
      _triggered = true;
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return ClipRect(
            child: Stack(
              children: [
                // Zooming image layer.
                Transform.scale(
                  scale: _zoom.value,
                  child: child,
                ),
                // Sliding overlay.
                _buildOverlay(),
              ],
            ),
          );
        },
        child: widget.child,
      ),
    );
  }

  Widget _buildOverlay() {
    final p = _progress.value;

    // Slide the overlay out of the frame.
    final isHorizontal =
        widget.direction == ImageRevealDirection.leftToRight ||
        widget.direction == ImageRevealDirection.rightToLeft;

    final offset = isHorizontal
        ? Offset(
            widget.direction == ImageRevealDirection.leftToRight ? -p : p, 0)
        : Offset(
            0, widget.direction == ImageRevealDirection.topToBottom ? -p : p);

    return FractionalTranslation(
      translation: offset,
      child: Container(color: widget.overlayColor),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. BlindsReveal — venetian blinds opening effect
// ---------------------------------------------------------------------------

/// Splits [child] into horizontal strips that rotate open like venetian blinds
/// when scrolled into view, with staggered timing from top to bottom.
class BlindsReveal extends StatefulWidget {
  const BlindsReveal({
    super.key,
    required this.child,
    this.stripCount = 8,
    this.staggerDelay = AppDurations.staggerShort,
    this.stripDuration = AppDurations.entrance,
    this.curve = CinematicCurves.dramaticEntrance,
    this.visibilityThreshold = 0.85,
    this.perspective = 0.003,
  });

  final Widget child;

  /// Number of horizontal strips.
  final int stripCount;

  /// Delay between each successive strip's rotation.
  final Duration staggerDelay;

  /// Duration of each strip's rotation animation.
  final Duration stripDuration;

  /// Curve for the rotation animation.
  final Curve curve;

  /// Fraction of viewport at which the animation triggers.
  final double visibilityThreshold;

  /// Perspective value for the 3D rotation transform.
  final double perspective;

  @override
  State<BlindsReveal> createState() => _BlindsRevealState();
}

class _BlindsRevealState extends State<BlindsReveal>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _rotations;
  bool _triggered = false;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.stripCount, (i) {
      return AnimationController(vsync: this, duration: widget.stripDuration);
    });
    _rotations = _controllers.map((c) {
      // Rotate from 90° (edge-on) to 0° (flat).
      return Tween<double>(begin: math.pi / 2, end: 0.0).animate(
        CurvedAnimation(parent: c, curve: widget.curve),
      );
    }).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_checkVisibility);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_checkVisibility);
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_checkVisibility);
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _checkVisibility() {
    if (_triggered || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final pos = box.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.sizeOf(context).height;

    if (pos.dy < screenHeight * widget.visibilityThreshold &&
        pos.dy > -box.size.height) {
      _triggered = true;
      _scrollPosition?.removeListener(_checkVisibility);
      _startStaggered();
    }
  }

  void _startStaggered() {
    for (var i = 0; i < widget.stripCount; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final stripHeight = totalHeight / widget.stripCount;

        return Stack(
          children: List.generate(widget.stripCount, (i) {
            final top = i * stripHeight;
            return Positioned(
              top: top,
              left: 0,
              right: 0,
              height: stripHeight,
              child: AnimatedBuilder(
                animation: _rotations[i],
                builder: (_, __) {
                  return Transform(
                    alignment: Alignment.topCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, widget.perspective)
                      ..rotateX(_rotations[i].value),
                    child: ClipRect(
                      child: OverflowBox(
                        maxHeight: totalHeight,
                        alignment: Alignment(0, -1 + (2 * i / (widget.stripCount - 1))),
                        child: SizedBox(
                          height: totalHeight,
                          child: widget.child,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        );
      },
    );
  }
}
