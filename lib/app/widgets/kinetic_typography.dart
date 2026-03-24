import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// WaveText
// ---------------------------------------------------------------------------

/// Letters animate in a continuous sine-wave pattern.
///
/// Each character oscillates vertically with a phase offset, creating a
/// rippling wave across the text. Can run continuously or be triggered
/// externally via [animate].
class WaveText extends StatefulWidget {
  const WaveText({
    super.key,
    required this.text,
    required this.style,
    this.amplitude = 8.0,
    this.frequency = 2.0,
    this.speed = 3.0,
    this.animate = true,
  });

  final String text;
  final TextStyle style;

  /// Peak vertical displacement in logical pixels.
  final double amplitude;

  /// Number of full sine cycles across the entire text.
  final double frequency;

  /// Wave scroll speed — higher values move faster.
  final double speed;

  /// Whether the wave is currently animating.
  final bool animate;

  @override
  State<WaveText> createState() => _WaveTextState();
}

class _WaveTextState extends State<WaveText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(WaveText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final characters = widget.text.characters.toList();
    final charCount = characters.length;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(charCount, (i) {
          final phase =
              (i / charCount) * widget.frequency * 2 * pi;
          final offset = sin(
                  phase + _controller.value * 2 * pi * widget.speed) *
              widget.amplitude;

          return Transform.translate(
            offset: Offset(0, offset),
            child: Text(
              characters[i],
              style: widget.style,
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GlitchText
// ---------------------------------------------------------------------------

/// Digital glitch effect on text.
///
/// Randomly replaces characters with block glyphs, applies colour-channel
/// splitting offsets, and occasionally displaces horizontal text slices.
/// Can trigger on hover or at regular intervals.
class GlitchText extends StatefulWidget {
  const GlitchText({
    super.key,
    required this.text,
    required this.style,
    this.triggerOnHover = true,
    this.autoInterval,
    this.glitchDuration = const Duration(milliseconds: 200),
    this.intensity = 0.3,
  });

  final String text;
  final TextStyle style;

  /// When true the effect triggers on mouse enter.
  final bool triggerOnHover;

  /// If non-null, glitch fires automatically at this interval.
  final Duration? autoInterval;

  /// How long a single glitch burst lasts.
  final Duration glitchDuration;

  /// 0-1 — fraction of characters that may glitch at once.
  final double intensity;

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText> {
  static const _glyphs = '█▓░/\\|#@&%';
  static final _rng = Random();

  late String _display;
  Timer? _burstTimer;
  Timer? _autoTimer;

  // Colour-channel split offsets during glitch.
  double _redDx = 0;
  double _blueDx = 0;

  // Horizontal slice displacement.
  double _sliceOffset = 0;
  double _sliceTop = 0; // fraction 0-1
  double _sliceHeight = 0; // fraction 0-1

  bool _glitching = false;

  @override
  void initState() {
    super.initState();
    _display = widget.text;
    _setupAutoTimer();
  }

  @override
  void didUpdateWidget(GlitchText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _display = widget.text;
    }
    if (oldWidget.autoInterval != widget.autoInterval) {
      _autoTimer?.cancel();
      _setupAutoTimer();
    }
  }

  @override
  void dispose() {
    _burstTimer?.cancel();
    _autoTimer?.cancel();
    super.dispose();
  }

  void _setupAutoTimer() {
    final interval = widget.autoInterval;
    if (interval == null) return;
    _autoTimer = Timer.periodic(interval, (_) => _startGlitch());
  }

  void _startGlitch() {
    if (_glitching) return;
    _glitching = true;

    var ticks = 0;
    final totalTicks =
        (widget.glitchDuration.inMilliseconds / 33).round().clamp(1, 100);

    _burstTimer?.cancel();
    _burstTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      ticks++;

      // Scramble a subset of characters.
      final buf = StringBuffer();
      for (var i = 0; i < widget.text.length; i++) {
        if (widget.text[i] == ' ') {
          buf.write(' ');
        } else if (_rng.nextDouble() < widget.intensity) {
          buf.write(_glyphs[_rng.nextInt(_glyphs.length)]);
        } else {
          buf.write(widget.text[i]);
        }
      }

      setState(() {
        _display = buf.toString();
        _redDx = (_rng.nextDouble() - 0.5) * 4;
        _blueDx = (_rng.nextDouble() - 0.5) * 4;

        // Occasional slice displacement.
        if (_rng.nextDouble() < 0.3) {
          _sliceOffset = (_rng.nextDouble() - 0.5) * 12;
          _sliceTop = _rng.nextDouble() * 0.6;
          _sliceHeight = 0.1 + _rng.nextDouble() * 0.3;
        } else {
          _sliceOffset = 0;
        }
      });

      if (ticks >= totalTicks) {
        timer.cancel();
        _endGlitch();
      }
    });
  }

  void _endGlitch() {
    if (!mounted) return;
    _glitching = false;
    setState(() {
      _display = widget.text;
      _redDx = 0;
      _blueDx = 0;
      _sliceOffset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget textWidget = Text(_display, style: widget.style);

    if (_glitching) {
      // Layer colour-channel split.
      textWidget = ClipRect(
        child: Stack(
          children: [
            // Red channel offset.
            Transform.translate(
              offset: Offset(_redDx, 0),
              child: Text(
                _display,
                style: widget.style.copyWith(
                  color: widget.style.color?.withValues(
                        red: 1.0,
                        green: 0,
                        blue: 0,
                        alpha: 0.6,
                      ) ??
                      const Color.fromRGBO(255, 0, 0, 0.6),
                ),
              ),
            ),
            // Blue channel offset.
            Transform.translate(
              offset: Offset(_blueDx, 0),
              child: Text(
                _display,
                style: widget.style.copyWith(
                  color: widget.style.color?.withValues(
                        red: 0,
                        green: 0,
                        blue: 1.0,
                        alpha: 0.6,
                      ) ??
                      const Color.fromRGBO(0, 0, 255, 0.6),
                ),
              ),
            ),
            // Main text on top.
            Text(_display, style: widget.style),
          ],
        ),
      );

      // Horizontal slice displacement.
      if (_sliceOffset != 0) {
        textWidget = _SliceDisplace(
          offset: _sliceOffset,
          sliceTop: _sliceTop,
          sliceHeight: _sliceHeight,
          child: textWidget,
        );
      }
    }

    if (widget.triggerOnHover) {
      return MouseRegion(
        onEnter: (_) => _startGlitch(),
        child: textWidget,
      );
    }

    return textWidget;
  }
}

/// Clips and displaces a horizontal slice of its child.
class _SliceDisplace extends StatelessWidget {
  const _SliceDisplace({
    required this.offset,
    required this.sliceTop,
    required this.sliceHeight,
    required this.child,
  });

  final double offset;
  final double sliceTop;
  final double sliceHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight > 0 ? constraints.maxHeight : 40.0;
        final top = sliceTop * h;
        final height = sliceHeight * h;

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            child,
            Positioned(
              left: offset,
              top: top,
              height: height,
              right: -offset.abs(),
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  maxHeight: h,
                  child: Transform.translate(
                    offset: Offset(0, -top),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
}

// ---------------------------------------------------------------------------
// MorphText
// ---------------------------------------------------------------------------

/// Smoothly morphs between two strings.
///
/// Characters cross-fade and slide into their new positions. Handles strings
/// of different lengths by fading surplus characters in or out.
class MorphText extends StatefulWidget {
  const MorphText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeInOutCubic,
  });

  /// The target text to morph towards. When this changes, the morph animates.
  final String text;
  final TextStyle style;
  final Duration duration;
  final Curve curve;

  @override
  State<MorphText> createState() => _MorphTextState();
}

class _MorphTextState extends State<MorphText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  String _oldText = '';
  String _newText = '';

  @override
  void initState() {
    super.initState();
    _oldText = widget.text;
    _newText = widget.text;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
  }

  @override
  void didUpdateWidget(MorphText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _oldText = oldWidget.text;
      _newText = widget.text;
      _controller.duration = widget.duration;
      _animation = CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    builder: (_, __) {
      final t = _animation.value;
      final maxLen = max(_oldText.length, _newText.length);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(maxLen, (i) {
          final hasOld = i < _oldText.length;
          final hasNew = i < _newText.length;

          if (hasOld && hasNew) {
            // Both exist — cross-fade.
            if (_oldText[i] == _newText[i]) {
              return Text(_newText[i], style: widget.style);
            }
            return _CrossFadeChar(
              oldChar: _oldText[i],
              newChar: _newText[i],
              progress: t,
              style: widget.style,
            );
          } else if (hasNew) {
            // New character fading in.
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - t)),
                child: Text(_newText[i], style: widget.style),
              ),
            );
          } else {
            // Old character fading out.
            return Opacity(
              opacity: 1 - t,
              child: Transform.translate(
                offset: Offset(0, -8 * t),
                child: Text(_oldText[i], style: widget.style),
              ),
            );
          }
        }),
      );
    },
  );
}

class _CrossFadeChar extends StatelessWidget {
  const _CrossFadeChar({
    required this.oldChar,
    required this.newChar,
    required this.progress,
    required this.style,
  });

  final String oldChar;
  final String newChar;
  final double progress;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      // Old character slides up and fades out.
      Opacity(
        opacity: (1 - progress).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, -12 * progress),
          child: Text(oldChar, style: style),
        ),
      ),
      // New character slides up from below and fades in.
      Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - progress)),
          child: Text(newChar, style: style),
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// ScatterText
// ---------------------------------------------------------------------------

/// Letters scatter outward on trigger, then reassemble.
///
/// Each letter is given a random velocity and rotation. A simple physics
/// model applies gravity. On reverse, letters fly back to their home
/// positions with spring-like easing.
class ScatterText extends StatefulWidget {
  const ScatterText({
    super.key,
    required this.text,
    required this.style,
    this.scatterDuration = const Duration(milliseconds: 800),
    this.assembleDuration = const Duration(milliseconds: 600),
    this.maxVelocity = 300.0,
    this.gravity = 400.0,
    this.triggerOnHover = true,
  });

  final String text;
  final TextStyle style;

  /// Duration of the scatter-out phase.
  final Duration scatterDuration;

  /// Duration of the reassembly phase.
  final Duration assembleDuration;

  /// Maximum initial velocity (pixels/sec) per letter.
  final double maxVelocity;

  /// Downward acceleration in pixels/sec^2.
  final double gravity;

  /// Whether scatter triggers on hover (scatter on exit, assemble on enter).
  final bool triggerOnHover;

  @override
  State<ScatterText> createState() => ScatterTextState();
}

class ScatterTextState extends State<ScatterText>
    with SingleTickerProviderStateMixin {
  static final _rng = Random();

  late AnimationController _controller;
  late List<_LetterPhysics> _physics;
  bool _scattered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.scatterDuration,
    );
    _buildPhysics();
    _controller.addStatusListener(_onStatus);
  }

  void _buildPhysics() {
    _physics = List.generate(widget.text.length, (_) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = widget.maxVelocity * (0.5 + _rng.nextDouble() * 0.5);
      return _LetterPhysics(
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - widget.maxVelocity * 0.5,
        rotation: (_rng.nextDouble() - 0.5) * 4 * pi,
        gravity: widget.gravity,
      );
    });
  }

  @override
  void didUpdateWidget(ScatterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _buildPhysics();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_scattered) {
      _scattered = true;
    } else if (status == AnimationStatus.dismissed && _scattered) {
      _scattered = false;
      _buildPhysics(); // Fresh random values for next scatter.
    }
  }

  /// Programmatic trigger: scatter the letters.
  void scatter() {
    if (_scattered) return;
    _controller.duration = widget.scatterDuration;
    _controller.forward();
  }

  /// Programmatic trigger: reassemble the letters.
  void assemble() {
    if (!_scattered) return;
    _controller.duration = widget.assembleDuration;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final characters = widget.text.characters.toList();

    Widget content = AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(characters.length, (i) {
            if (characters[i] == ' ') {
              return Text(' ', style: widget.style);
            }

            final p = _physics[i];
            final dx = p.vx * t;
            final dy = p.vy * t + 0.5 * p.gravity * t * t;
            final angle = p.rotation * t;
            final opacity = (1 - t * 1.2).clamp(0.0, 1.0);

            return Opacity(
              opacity: opacity,
              child: Transform(
                transform: Matrix4.identity()
                  ..translateByDouble(dx, dy, 0.0, 1.0)
                  ..rotateZ(angle),
                alignment: Alignment.center,
                child: Text(characters[i], style: widget.style),
              ),
            );
          }),
        );
      },
    );

    if (widget.triggerOnHover) {
      content = MouseRegion(
        onExit: (_) => scatter(),
        onEnter: (_) => assemble(),
        child: content,
      );
    }

    return content;
  }
}

class _LetterPhysics {
  const _LetterPhysics({
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.gravity,
  });

  final double vx;
  final double vy;
  final double rotation;
  final double gravity;
}

// ---------------------------------------------------------------------------
// ElasticText
// ---------------------------------------------------------------------------

/// Text with rubber-band physics — letters stretch and bounce on hover.
///
/// Each letter responds independently to cursor proximity using a spring
/// simulation for a natural elastic feel.
class ElasticText extends StatefulWidget {
  const ElasticText({
    super.key,
    required this.text,
    required this.style,
    this.maxDisplacement = 16.0,
    this.influenceRadius = 80.0,
    this.stiffness = 300.0,
    this.damping = 12.0,
  });

  final String text;
  final TextStyle style;

  /// Maximum upward displacement when cursor is directly over a letter.
  final double maxDisplacement;

  /// Radius of cursor influence in logical pixels.
  final double influenceRadius;

  /// Spring stiffness for the bounce-back.
  final double stiffness;

  /// Spring damping ratio.
  final double damping;

  @override
  State<ElasticText> createState() => _ElasticTextState();
}

class _ElasticTextState extends State<ElasticText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final List<_SpringLetter> _springs = [];
  final List<GlobalKey> _letterKeys = [];
  Offset? _cursorLocal;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // not used; we tick manually
    )
      ..addListener(_tick)
      ..repeat();
    _buildSprings();
  }

  void _buildSprings() {
    _springs.clear();
    _letterKeys.clear();
    for (var i = 0; i < widget.text.length; i++) {
      _springs.add(_SpringLetter());
      _letterKeys.add(GlobalKey());
    }
  }

  @override
  void didUpdateWidget(ElasticText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _buildSprings();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  DateTime _lastTick = DateTime.now();

  void _tick() {
    final now = DateTime.now();
    final dt =
        (now.difference(_lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTick = now;

    var needsRebuild = false;

    for (var i = 0; i < _springs.length; i++) {
      if (widget.text[i] == ' ') continue;

      var target = 0.0;
      if (_cursorLocal != null) {
        final key = _letterKeys[i];
        final box = key.currentContext?.findRenderObject() as RenderBox?;
        if (box != null && box.attached) {
          final letterCenter = box.localToGlobal(
            box.size.center(Offset.zero),
            ancestor: context.findRenderObject(),
          );
          final distance = (letterCenter.dx - _cursorLocal!.dx).abs();
          if (distance < widget.influenceRadius) {
            final factor = 1 - (distance / widget.influenceRadius);
            target = -widget.maxDisplacement * factor * factor;
          }
        }
      }

      final spring = _springs[i];
      // Simple damped spring: F = -k*(x - target) - d*v
      final force =
          -widget.stiffness * (spring.y - target) - widget.damping * spring.vy;
      spring
        ..vy += force * dt
        ..y += spring.vy * dt;

      if ((spring.y - target).abs() > 0.1 || spring.vy.abs() > 0.1) {
        needsRebuild = true;
      }
    }

    if (needsRebuild) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final characters = widget.text.characters.toList();

    return MouseRegion(
      onHover: (event) => _cursorLocal = event.localPosition,
      onExit: (_) => _cursorLocal = null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(characters.length, (i) {
          if (characters[i] == ' ') {
            return Text(' ', key: _letterKeys[i], style: widget.style);
          }

          final yOffset = _springs[i].y;
          final scaleY = 1 + (yOffset.abs() / widget.maxDisplacement) * 0.15;

          return Transform(
            transform: Matrix4.identity()
              ..translateByDouble(0.0, yOffset, 0.0, 1.0)
              ..scaleByDouble(1.0, scaleY, 1.0, 1.0),
            alignment: Alignment.bottomCenter,
            child: Text(
              characters[i],
              key: _letterKeys[i],
              style: widget.style,
            ),
          );
        }),
      ),
    );
  }
}

class _SpringLetter {
  double y = 0;
  double vy = 0;
}

// ---------------------------------------------------------------------------
// RevealText
// ---------------------------------------------------------------------------

/// Scroll-driven character / word / line reveal.
///
/// Each unit fades in from opacity 0 + translateY to full opacity as its
/// parent section scrolls into view. A stagger delay spreads the reveal
/// across units.
enum RevealUnit { character, word, line }

class RevealText extends StatefulWidget {
  const RevealText({
    super.key,
    required this.text,
    required this.style,
    this.revealUnit = RevealUnit.character,
    this.staggerDelay = const Duration(milliseconds: 30),
    this.unitDuration = const Duration(milliseconds: 400),
    this.translateY = 20.0,
    this.curve = Curves.easeOut,
    this.trigger = true,
  });

  final String text;
  final TextStyle style;

  /// Granularity of the reveal effect.
  final RevealUnit revealUnit;

  /// Delay between successive units beginning their animation.
  final Duration staggerDelay;

  /// Duration of each individual unit's fade + slide.
  final Duration unitDuration;

  /// Vertical offset (in logical pixels) at the start of the reveal.
  final double translateY;

  final Curve curve;

  /// Set to true to start the reveal. Useful for binding to a scroll
  /// visibility controller.
  final bool trigger;

  @override
  State<RevealText> createState() => _RevealTextState();
}

class _RevealTextState extends State<RevealText>
    with TickerProviderStateMixin {
  late List<String> _units;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  bool _hasTriggered = false;

  @override
  void initState() {
    super.initState();
    _buildUnits();
    if (widget.trigger) _startReveal();
  }

  void _buildUnits() {
    switch (widget.revealUnit) {
      case RevealUnit.character:
        _units = widget.text.characters.toList();
      case RevealUnit.word:
        _units = _splitKeepingSeparators(widget.text, ' ');
      case RevealUnit.line:
        _units = _splitKeepingSeparators(widget.text, '\n');
    }

    _controllers = List.generate(
      _units.length,
      (_) => AnimationController(vsync: this, duration: widget.unitDuration),
    );

    _animations = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: widget.curve))
        .toList();
  }

  /// Splits [source] by [separator] but keeps the separators attached to
  /// the preceding segment so spacing is preserved during rendering.
  List<String> _splitKeepingSeparators(String source, String separator) {
    final result = <String>[];
    final parts = source.split(separator);
    for (var i = 0; i < parts.length; i++) {
      if (i < parts.length - 1) {
        result.add('${parts[i]}$separator');
      } else {
        result.add(parts[i]);
      }
    }
    return result.where((s) => s.isNotEmpty).toList();
  }

  @override
  void didUpdateWidget(RevealText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text) {
      _disposeControllers();
      _buildUnits();
      if (widget.trigger) _startReveal();
    } else if (widget.trigger && !_hasTriggered) {
      _startReveal();
    }
  }

  void _startReveal() {
    _hasTriggered = true;
    for (var i = 0; i < _controllers.length; i++) {
      final delay = widget.staggerDelay * i;
      if (delay == Duration.zero) {
        _controllers[i].forward();
      } else {
        Future.delayed(delay, () {
          if (mounted) _controllers[i].forward();
        });
      }
    }
  }

  void _disposeControllers() {
    for (final c in _controllers) {
      c.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Widget _buildRevealUnit(int i) => AnimatedBuilder(
    animation: _animations[i],
    builder: (_, __) {
      final t = _animations[i].value;
      return Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, widget.translateY * (1 - t)),
          child: Text(_units[i], style: widget.style),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final isInline = widget.revealUnit != RevealUnit.line;

    if (isInline) {
      return Wrap(
        children: List.generate(_units.length, _buildRevealUnit),
      );
    }

    // Line-by-line reveal.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_units.length, _buildRevealUnit),
    );
  }
}
