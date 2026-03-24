import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

/// A particle text effect that assembles characters from scattered particles.
///
/// Each character is sampled as pixel positions, then particles fly from random
/// positions to form the text. On completion, the text resolves to full clarity.
///
/// Usage:
/// ```dart
/// ParticleText(
///   text: 'HELLO WORLD',
///   style: TextStyle(fontSize: 72, fontWeight: FontWeight.w800),
///   duration: Duration(seconds: 2),
/// )
/// ```
class ParticleText extends StatefulWidget {
  const ParticleText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 2500),
    this.particleColor,
    this.particlesPerChar = 40,
    this.autoStart = true,
    this.delay = Duration.zero,
    this.onComplete,
  });

  final String text;
  final TextStyle style;
  final Duration duration;
  final Color? particleColor;
  final int particlesPerChar;
  final bool autoStart;
  final Duration delay;
  final VoidCallback? onComplete;

  @override
  State<ParticleText> createState() => _ParticleTextState();
}

class _ParticleTextState extends State<ParticleText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _assembleAnimation;
  late Animation<double> _resolveAnimation;

  List<_Particle> _particles = [];
  Size _textSize = Size.zero;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _assembleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
    );

    _resolveAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.autoStart) {
      Future.delayed(widget.delay, () {
        if (mounted) _start();
      });
    }
  }

  void _start() {
    _initializeParticles();
    _controller.forward();
  }

  void _initializeParticles() {
    final rng = math.Random(42);
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: TextDirection.ltr,
    )..layout();

    _textSize = Size(textPainter.width, textPainter.height);

    // Sample positions along the text outline by creating a grid and checking
    // which points fall inside the rendered text
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    textPainter.paint(canvas, Offset.zero);
    recorder.endRecording();

    // Generate particles from grid sampling
    _particles = [];
    final gridSpacing = math.max(2.0, _textSize.width / (widget.text.length * widget.particlesPerChar / 3));

    for (double x = 0; x < _textSize.width; x += gridSpacing) {
      for (double y = 0; y < _textSize.height; y += gridSpacing) {
        // Probabilistically place particles along likely text areas
        // Use character bounds as a heuristic
        final charIndex = (x / _textSize.width * widget.text.length).floor().clamp(0, widget.text.length - 1);
        if (widget.text[charIndex] == ' ') continue;

        if (rng.nextDouble() < 0.6) {
          final target = Offset(x, y);
          final spreadRadius = math.max(_textSize.width, _textSize.height) * 1.5;
          final startX = target.dx + (rng.nextDouble() - 0.5) * spreadRadius;
          final startY = target.dy + (rng.nextDouble() - 0.5) * spreadRadius;

          _particles.add(_Particle(
            startPosition: Offset(startX, startY),
            targetPosition: target,
            size: 1.0 + rng.nextDouble() * 2.0,
            delay: rng.nextDouble() * 0.3,
          ));
        }
      }
    }

    setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      // Invisible placeholder with same size
      return Opacity(
        opacity: 0,
        child: Text(widget.text, style: widget.style),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final resolveProgress = _resolveAnimation.value;

        return SizedBox(
          width: _textSize.width,
          height: _textSize.height,
          child: Stack(
            children: [
              // Particles layer
              if (resolveProgress < 1.0)
                Opacity(
                  opacity: 1.0 - resolveProgress,
                  child: CustomPaint(
                    size: _textSize,
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: _assembleAnimation.value,
                      color: widget.particleColor ??
                          widget.style.color ??
                          AppColors.accent,
                    ),
                  ),
                ),

              // Resolved text layer
              Opacity(
                opacity: resolveProgress,
                child: Text(widget.text, style: widget.style),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Particle {
  _Particle({
    required this.startPosition,
    required this.targetPosition,
    required this.size,
    required this.delay,
  });

  final Offset startPosition;
  final Offset targetPosition;
  final double size;
  final double delay;

  Offset positionAt(double t) {
    final adjustedT = ((t - delay) / (1.0 - delay)).clamp(0.0, 1.0);
    return Offset.lerp(startPosition, targetPosition, adjustedT)!;
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  final List<_Particle> particles;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      final pos = particle.positionAt(progress);
      final opacity = progress < particle.delay
          ? 0.0
          : ((progress - particle.delay) / (1.0 - particle.delay)).clamp(0.0, 1.0);

      if (opacity <= 0) continue;

      paint.color = color.withValues(alpha: opacity * 0.8);
      canvas.drawCircle(pos, particle.size * (0.5 + 0.5 * opacity), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => progress != old.progress;
}
