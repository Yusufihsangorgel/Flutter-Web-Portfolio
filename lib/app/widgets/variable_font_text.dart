import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

// ---------------------------------------------------------------------------
// 1. VariableFontText — per-character weight animation on hover / proximity
// ---------------------------------------------------------------------------

/// Text whose individual characters animate font weight on hover.
///
/// Each character reacts independently to cursor proximity, growing bolder as
/// the pointer approaches. A staggered spring animation drives the transition
/// from [defaultWeight] to [hoverWeight].
class VariableFontText extends StatefulWidget {
  const VariableFontText({
    super.key,
    required this.text,
    required this.style,
    this.defaultWeight = 300,
    this.hoverWeight = 700,
    this.proximityRadius = 80.0,
    this.staggerDelay = const Duration(milliseconds: 30),
    this.springDuration = const Duration(milliseconds: 500),
    this.springCurve = Curves.elasticOut,
  });

  final String text;
  final TextStyle style;

  /// Font weight when idle (100–900).
  final double defaultWeight;

  /// Font weight at full hover intensity (100–900).
  final double hoverWeight;

  /// Pixel radius around each character that triggers the proximity effect.
  final double proximityRadius;

  /// Delay between successive character animations.
  final Duration staggerDelay;

  /// Duration for the spring-based weight animation.
  final Duration springDuration;

  /// Curve applied to the spring animation.
  final Curve springCurve;

  @override
  State<VariableFontText> createState() => _VariableFontTextState();
}

class _VariableFontTextState extends State<VariableFontText>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  bool _hovering = false;
  Offset? _localPointer;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _controllers = List.generate(
      widget.text.length,
      (i) => AnimationController(
        vsync: this,
        duration: widget.springDuration,
      ),
    );
    _animations = _controllers
        .map((c) => Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: c, curve: widget.springCurve),
            ))
        .toList();
  }

  @override
  void didUpdateWidget(VariableFontText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text.length != widget.text.length) {
      for (final c in _controllers) {
        c.dispose();
      }
      _initControllers();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onEnter(PointerEvent event) {
    _hovering = true;
    _animateStaggered(forward: true);
  }

  void _onExit(PointerEvent event) {
    _hovering = false;
    _localPointer = null;
    _animateStaggered(forward: false);
  }

  void _onHover(PointerEvent event) {
    setState(() => _localPointer = event.localPosition);
  }

  void _animateStaggered({required bool forward}) {
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (!mounted) return;
        if (forward) {
          _controllers[i].forward();
        } else {
          _controllers[i].reverse();
        }
      });
    }
  }

  double _weightForIndex(int index) {
    final baseT = _animations[index].value;

    // Blend in proximity boost when cursor is nearby.
    double proximityT = 0;
    if (_hovering && _localPointer != null) {
      // Estimate character center X based on uniform spacing.
      final charWidth =
          (context.size?.width ?? 200) / max(widget.text.length, 1);
      final charCenter = Offset(
        charWidth * index + charWidth / 2,
        (context.size?.height ?? 20) / 2,
      );
      final distance = (charCenter - _localPointer!).distance;
      proximityT =
          (1 - (distance / widget.proximityRadius)).clamp(0.0, 1.0);
    }

    final t = (baseT + proximityT).clamp(0.0, 1.0);
    return ui.lerpDouble(widget.defaultWeight, widget.hoverWeight, t)!;
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: _onEnter,
        onExit: _onExit,
        onHover: _onHover,
        child: AnimatedBuilder(
          animation: Listenable.merge(_controllers),
          builder: (_, __) => Text.rich(
            TextSpan(
              children: List.generate(widget.text.length, (i) {
                final weight = _weightForIndex(i);
                return TextSpan(
                  text: widget.text[i],
                  style: widget.style.copyWith(
                    fontVariations: [
                      FontVariation('wght', weight),
                    ],
                    fontWeight: FontWeight.values[
                        ((weight - 100) / 100).round().clamp(0, 8)],
                  ),
                );
              }),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// 2. BreathingText — slow, continuous font-weight oscillation
// ---------------------------------------------------------------------------

/// Text that gently oscillates its font weight to simulate breathing.
///
/// The weight smoothly cycles between [minWeight] and [maxWeight] at a pace
/// set by [cycleDuration]. Ideal for hero text that should feel alive.
class BreathingText extends StatefulWidget {
  const BreathingText({
    super.key,
    required this.text,
    required this.style,
    this.minWeight = 300,
    this.maxWeight = 500,
    this.cycleDuration = const Duration(seconds: 4),
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final double minWeight;
  final double maxWeight;
  final Duration cycleDuration;
  final TextAlign? textAlign;

  @override
  State<BreathingText> createState() => _BreathingTextState();
}

class _BreathingTextState extends State<BreathingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.cycleDuration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          // Sinusoidal ease for a more organic breathing feel.
          final t = (sin(_controller.value * pi * 2 - pi / 2) + 1) / 2;
          final weight =
              ui.lerpDouble(widget.minWeight, widget.maxWeight, t)!;

          return Text(
            widget.text,
            textAlign: widget.textAlign,
            style: widget.style.copyWith(
              fontVariations: [FontVariation('wght', weight)],
            ),
          );
        },
      );
}

// ---------------------------------------------------------------------------
// 3. StrokeText — outlined text that fills on hover
// ---------------------------------------------------------------------------

/// Text rendered as an outline that fills with color from left to right on
/// hover.
///
/// Uses [TextPainter] with a stroke [Paint] for the outline and a second
/// clipped fill pass for the reveal animation.
class StrokeText extends StatefulWidget {
  const StrokeText({
    super.key,
    required this.text,
    required this.style,
    this.strokeWidth = 1.5,
    this.strokeColor,
    this.fillColor,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeInOut,
  });

  final String text;
  final TextStyle style;
  final double strokeWidth;

  /// Outline colour. Defaults to the style's color or white.
  final Color? strokeColor;

  /// Fill colour revealed on hover. Defaults to [strokeColor].
  final Color? fillColor;

  final Duration duration;
  final Curve curve;

  @override
  State<StrokeText> createState() => _StrokeTextState();
}

class _StrokeTextState extends State<StrokeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _progress = CurvedAnimation(parent: _controller, curve: widget.curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => _controller.forward(),
        onExit: (_) => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _progress,
          builder: (_, __) => CustomPaint(
            painter: _StrokeTextPainter(
              text: widget.text,
              style: widget.style,
              strokeWidth: widget.strokeWidth,
              strokeColor: widget.strokeColor ??
                  widget.style.color ??
                  Colors.white,
              fillColor: widget.fillColor ??
                  widget.strokeColor ??
                  widget.style.color ??
                  Colors.white,
              fillProgress: _progress.value,
            ),
            child: Opacity(
              opacity: 0,
              child: Text(widget.text, style: widget.style),
            ),
          ),
        ),
      );
}

class _StrokeTextPainter extends CustomPainter {
  _StrokeTextPainter({
    required this.text,
    required this.style,
    required this.strokeWidth,
    required this.strokeColor,
    required this.fillColor,
    required this.fillProgress,
  });

  final String text;
  final TextStyle style;
  final double strokeWidth;
  final Color strokeColor;
  final Color fillColor;
  final double fillProgress;

  @override
  void paint(Canvas canvas, Size size) {
    // --- stroke pass ---
    final strokeStyle = style.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = strokeColor,
    );
    final strokePainter = TextPainter(
      text: TextSpan(text: text, style: strokeStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    strokePainter.paint(canvas, Offset.zero);

    // --- fill pass (clipped left-to-right) ---
    if (fillProgress > 0) {
      final fillStyle = style.copyWith(color: fillColor);
      final fillPainter = TextPainter(
        text: TextSpan(text: text, style: fillStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);

      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(0, 0, size.width * fillProgress, size.height),
      );
      fillPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_StrokeTextPainter old) =>
      fillProgress != old.fillProgress ||
      text != old.text ||
      strokeColor != old.strokeColor ||
      fillColor != old.fillColor;
}

// ---------------------------------------------------------------------------
// 4. GradientAnimatedText — continuously shifting gradient
// ---------------------------------------------------------------------------

/// Text masked with a linear gradient that continuously shifts.
///
/// The gradient spans wider than the text and translates horizontally in a
/// seamless loop, giving the text a shimmering / flowing colour effect.
class GradientAnimatedText extends StatefulWidget {
  const GradientAnimatedText({
    super.key,
    required this.text,
    required this.style,
    this.colors,
    this.speed = const Duration(seconds: 3),
    this.gradientAngle = 0,
    this.textAlign,
  });

  final String text;
  final TextStyle style;

  /// Gradient colours. Defaults to a purple-to-cyan accent palette.
  final List<Color>? colors;

  /// Duration for one full gradient cycle.
  final Duration speed;

  /// Angle in radians for the gradient direction.
  final double gradientAngle;

  final TextAlign? textAlign;

  @override
  State<GradientAnimatedText> createState() => _GradientAnimatedTextState();
}

class _GradientAnimatedTextState extends State<GradientAnimatedText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const _defaultColors = [
    Color(0xFF6C63FF),
    Color(0xFF00BCD4),
    Color(0xFFE040FB),
    Color(0xFF6C63FF), // repeat first for seamless wrap
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.speed)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ?? _defaultColors;
    // Ensure seamless looping by appending the first colour if not already.
    final loopColors =
        (colors.last == colors.first) ? colors : [...colors, colors.first];

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        // Shift stops so the gradient slides across the text.
        final t = _controller.value;
        final count = loopColors.length;
        final stops = List<double>.generate(count, (i) {
          return ((i / (count - 1)) + t) % 1.0;
        })..sort();

        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final dx = cos(widget.gradientAngle);
            final dy = sin(widget.gradientAngle);
            return LinearGradient(
              begin: Alignment(dx, dy),
              end: Alignment(-dx, -dy),
              colors: loopColors,
              stops: stops,
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: widget.style,
            textAlign: widget.textAlign,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 5. CountingText — animated number with formatting, visibility-triggered
// ---------------------------------------------------------------------------

/// Animates a number from 0 to [value], triggered when scrolled into view.
///
/// Supports decimal precision, percentage / currency prefixes, and automatic
/// compact formatting (1.2K, 3.5M) for large numbers.
class CountingText extends StatefulWidget {
  const CountingText({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeInOutCubic,
    this.decimals = 0,
    this.prefix = '',
    this.suffix = '',
    this.compact = false,
  });

  final double value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  /// Number of decimal places to display.
  final int decimals;

  /// Text prepended to the number (e.g. '\$').
  final String prefix;

  /// Text appended to the number (e.g. '%', '+').
  final String suffix;

  /// If true, large numbers are compacted (1200 → 1.2K).
  final bool compact;

  @override
  State<CountingText> createState() => _CountingTextState();
}

class _CountingTextState extends State<CountingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
  }

  @override
  void didUpdateWidget(CountingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: 0, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: widget.curve),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!_triggered && info.visibleFraction > 0.3) {
      _triggered = true;
      _controller.forward();
    }
  }

  String _format(double v) {
    if (widget.compact) {
      if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
      if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
      if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    }
    return v.toStringAsFixed(widget.decimals);
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      onVisibilityChanged: _onVisibilityChanged,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (_, __) {
          return Text(
            '${widget.prefix}${_format(_animation.value)}${widget.suffix}',
            style: widget.style,
          );
        },
      ),
    );
  }
}

/// Lightweight visibility detector that fires once the widget is at least
/// partially visible in the viewport.
class VisibilityDetector extends SingleChildRenderObjectWidget {
  const VisibilityDetector({
    super.key,
    required this.onVisibilityChanged,
    required super.child,
  });

  final ValueChanged<VisibilityInfo> onVisibilityChanged;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderVisibilityDetector(onVisibilityChanged);

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderVisibilityDetector renderObject) {
    renderObject.onVisibilityChanged = onVisibilityChanged;
  }
}

class VisibilityInfo {
  const VisibilityInfo(this.visibleFraction);
  final double visibleFraction;
}

class _RenderVisibilityDetector extends RenderProxyBox {
  _RenderVisibilityDetector(this.onVisibilityChanged);

  ValueChanged<VisibilityInfo> onVisibilityChanged;
  double _lastFraction = -1;

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    _checkVisibility();
  }

  void _checkVisibility() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!attached) return;
      final viewport = RenderAbstractViewport.maybeOf(this);
      if (viewport == null) {
        // Not inside a scrollable — assume fully visible.
        _report(1.0);
        return;
      }

      final revealedOffset = viewport.getOffsetToReveal(this, 0.0);
      final viewportSize = viewport.paintBounds.height;
      final itemSize = size.height;

      if (itemSize == 0 || viewportSize == 0) {
        _report(0.0);
        return;
      }

      final top = revealedOffset.offset;
      final visibleTop = max(0.0, top);
      final visibleBottom = min(viewportSize, top + itemSize);
      final visible = max(0.0, visibleBottom - visibleTop);
      _report((visible / itemSize).clamp(0.0, 1.0));
    });
  }

  void _report(double fraction) {
    if (fraction != _lastFraction) {
      _lastFraction = fraction;
      onVisibilityChanged(VisibilityInfo(fraction));
    }
  }
}

// ---------------------------------------------------------------------------
// 6. SplitFlapText — mechanical departure-board character flip effect
// ---------------------------------------------------------------------------

/// Simulates a mechanical split-flap display (airport departure board).
///
/// Each character flips sequentially through the alphabet until it reaches
/// its target letter, with a 3D perspective transform on the flipping halves.
class SplitFlapText extends StatefulWidget {
  const SplitFlapText({
    super.key,
    required this.text,
    required this.style,
    this.flipDuration = const Duration(milliseconds: 60),
    this.staggerDelay = const Duration(milliseconds: 120),
    this.backgroundColor,
    this.autoStart = true,
  });

  final String text;
  final TextStyle style;

  /// Time for a single flap to flip one character forward.
  final Duration flipDuration;

  /// Delay before the next column starts resolving.
  final Duration staggerDelay;

  /// Background colour behind each flap cell.
  final Color? backgroundColor;

  /// Whether to begin the animation immediately on mount.
  final bool autoStart;

  @override
  State<SplitFlapText> createState() => SplitFlapTextState();
}

class SplitFlapTextState extends State<SplitFlapText>
    with TickerProviderStateMixin {
  static const _chars =
      ' ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:;!?@#\$%&*()-+=/';

  late List<_FlapColumn> _columns;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _buildColumns();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => start());
    }
  }

  @override
  void didUpdateWidget(SplitFlapText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      for (final col in _columns) {
        col.controller.dispose();
      }
      _buildColumns();
      start();
    }
  }

  void _buildColumns() {
    _columns = List.generate(widget.text.length, (i) {
      final controller = AnimationController(
        vsync: this,
        duration: widget.flipDuration,
      );
      final target = widget.text[i].toUpperCase();
      final targetIndex = _chars.indexOf(target).clamp(0, _chars.length - 1);
      return _FlapColumn(
        controller: controller,
        targetIndex: targetIndex,
        currentIndex: 0,
      );
    });
  }

  /// Start (or restart) the split-flap animation.
  void start() {
    if (_started) return;
    _started = true;
    _animateColumn(0);
  }

  void _animateColumn(int colIdx) {
    if (colIdx >= _columns.length || !mounted) return;

    final col = _columns[colIdx];

    // Start the next column after a stagger delay.
    if (colIdx + 1 < _columns.length) {
      Future.delayed(widget.staggerDelay, () {
        if (mounted) _animateColumn(colIdx + 1);
      });
    }

    _flipNext(col);
  }

  void _flipNext(_FlapColumn col) {
    if (!mounted) return;
    if (col.currentIndex >= col.targetIndex) {
      // Resolved.
      setState(() {});
      return;
    }

    col.controller.forward(from: 0).then((_) {
      if (!mounted) return;
      col.currentIndex++;
      setState(() {});
      _flipNext(col);
    });
  }

  @override
  void dispose() {
    for (final col in _columns) {
      col.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.style.fontSize ?? 24;
    final cellWidth = fontSize * 0.75;
    final cellHeight = fontSize * 1.3;
    final bg = widget.backgroundColor ??
        Theme.of(context).colorScheme.surfaceContainerHighest;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_columns.length, (i) {
        final col = _columns[i];
        final current = _chars[col.currentIndex.clamp(0, _chars.length - 1)];
        final next = _chars[
            (col.currentIndex + 1).clamp(0, _chars.length - 1)];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: AnimatedBuilder(
            animation: col.controller,
            builder: (_, __) {
              final t = col.controller.value;
              return SizedBox(
                width: cellWidth,
                height: cellHeight,
                child: Stack(
                  children: [
                    // Background
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // --- Bottom half (static: shows next char once flap passes midpoint) ---
                    Positioned(
                      left: 0,
                      right: 0,
                      top: cellHeight / 2,
                      height: cellHeight / 2,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            height: cellHeight,
                            child: Center(
                              child: Text(
                                t > 0.5 ? next : current,
                                style: widget.style,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // --- Top half (static current) ---
                    if (t <= 0.5)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: cellHeight / 2,
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              height: cellHeight,
                              child: Center(
                                child: Text(current, style: widget.style),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // --- Flipping top flap (rotates down from 0 to -90°) ---
                    if (t <= 0.5)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: cellHeight / 2,
                        child: Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.003) // perspective
                            ..rotateX(-t * pi),
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                height: cellHeight,
                                child: Center(
                                  child: Text(current, style: widget.style),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // --- Flipping bottom flap (rotates up from 90° to 0) ---
                    if (t > 0.5)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: cellHeight / 2,
                        height: cellHeight / 2,
                        child: Transform(
                          alignment: Alignment.topCenter,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.003)
                            ..rotateX((1 - t) * pi),
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: SizedBox(
                                height: cellHeight,
                                child: Center(
                                  child: Text(next, style: widget.style),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Centre divider line
                    Positioned(
                      left: 0,
                      right: 0,
                      top: cellHeight / 2 - 0.5,
                      height: 1,
                      child: const ColoredBox(color: Colors.black26),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class _FlapColumn {
  _FlapColumn({
    required this.controller,
    required this.targetIndex,
    required this.currentIndex,
  });

  final AnimationController controller;
  final int targetIndex;
  int currentIndex;
}
