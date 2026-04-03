import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';

// ---------------------------------------------------------------------------
// LetterStaggerAnimation
// ---------------------------------------------------------------------------

/// Renders each letter of [text] with a staggered fade+slide entrance.
///
/// Each letter animates within its own sub-interval of the parent
/// [animation], producing a smooth left-to-right reveal.
class LetterStaggerAnimation extends StatelessWidget {
  const LetterStaggerAnimation({
    super.key,
    required this.text,
    required this.animation,
    this.style,
    this.staggerFraction = 0.06,
  });

  /// The string to reveal letter-by-letter.
  final String text;

  /// Driving animation (0 -> 1).
  final Animation<double> animation;

  /// Text style applied to every letter.
  final TextStyle? style;

  /// Fraction of the total duration allocated per-letter stagger offset.
  final double staggerFraction;

  @override
  Widget build(BuildContext context) {
    final letters = text.split('');
    final totalLetters = letters.length;
    if (totalLetters == 0) return const SizedBox.shrink();

    // Each letter occupies a window within [0..1].
    // The window start is staggered; the window length is the remainder.
    final windowLength =
        1.0 - (totalLetters - 1) * staggerFraction;
    final clampedWindow = windowLength.clamp(0.2, 1.0);

    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(totalLetters, (i) {
          final start = (i * staggerFraction).clamp(0.0, 1.0 - clampedWindow);
          final end = (start + clampedWindow).clamp(0.0, 1.0);

          final t = Interval(start, end, curve: CinematicCurves.dramaticEntrance)
              .transform(animation.value);

          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - t)),
              child: Text(
                letters[i] == ' ' ? '\u00A0' : letters[i],
                style: style,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GlowProgressBar
// ---------------------------------------------------------------------------

/// A thin, elegant progress bar with an animated glow halo.
class GlowProgressBar extends StatelessWidget {
  const GlowProgressBar({
    super.key,
    required this.progress,
    this.width = 240,
    this.height = 2.0,
    this.color,
    this.glowColor,
    this.trackColor,
  });

  final double progress;
  final double width;
  final double height;
  final Color? color;
  final Color? glowColor;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? AppColors.accent;
    final glow = glowColor ?? barColor.withValues(alpha: 0.5);
    final track = trackColor ?? barColor.withValues(alpha: 0.08);

    return SizedBox(
      width: width,
      height: height + 12, // extra space for glow
      child: CustomPaint(
        painter: _GlowBarPainter(
          progress: progress,
          barColor: barColor,
          glowColor: glow,
          trackColor: track,
          barHeight: height,
        ),
      ),
    );
  }
}

class _GlowBarPainter extends CustomPainter {
  _GlowBarPainter({
    required this.progress,
    required this.barColor,
    required this.glowColor,
    required this.trackColor,
    required this.barHeight,
  });

  final double progress;
  final Color barColor;
  final Color glowColor;
  final Color trackColor;
  final double barHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, cy - barHeight / 2, size.width, barHeight),
      Radius.circular(barHeight / 2),
    );
    canvas.drawRRect(trackRect, Paint()..color = trackColor);

    if (progress <= 0) return;

    final fillWidth = size.width * progress.clamp(0.0, 1.0);

    // Glow layer
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = glowColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, cy - barHeight, fillWidth, barHeight * 2),
        Radius.circular(barHeight),
      ),
      glowPaint,
    );

    // Fill
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, cy - barHeight / 2, fillWidth, barHeight),
      Radius.circular(barHeight / 2),
    );

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(fillWidth, 0),
        [barColor.withValues(alpha: 0.7), barColor],
      );
    canvas.drawRRect(fillRect, fillPaint);

    // Leading dot glow
    if (fillWidth > 2) {
      final dotPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas
        ..drawCircle(Offset(fillWidth, cy), barHeight * 1.5, dotPaint)
        ..drawCircle(
          Offset(fillWidth, cy),
          barHeight * 0.8,
          Paint()..color = Colors.white,
        );
    }
  }

  @override
  bool shouldRepaint(_GlowBarPainter old) =>
      progress != old.progress || barColor != old.barColor;
}

// ---------------------------------------------------------------------------
// PercentageCounter
// ---------------------------------------------------------------------------

/// Displays an animated percentage from 0 to [value] (0-100).
///
/// Drives its own implicit animation via [AnimatedBuilder] on the
/// provided [animation] controller.
class PercentageCounter extends StatelessWidget {
  const PercentageCounter({
    super.key,
    required this.animation,
    this.style,
  });

  /// Driving animation (0 -> 1 maps to 0% -> 100%).
  final Animation<double> animation;

  /// Optional style override.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = GoogleFonts.jetBrainsMono(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.accent.withValues(alpha: 0.7),
      letterSpacing: 2,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final pct = (animation.value * 100).round();
        return Text(
          '$pct%',
          style: style ?? defaultStyle,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// DissolveTransition
// ---------------------------------------------------------------------------

/// A clip-path circle-expand reveal that transitions from the preloader
/// to the main content beneath.
///
/// [revealProgress] drives the circle from radius 0 to full diagonal.
/// When [revealProgress] >= 1, the child is shown without clipping.
class DissolveTransition extends StatelessWidget {
  const DissolveTransition({
    super.key,
    required this.revealProgress,
    required this.child,
  });

  /// 0 = fully hidden, 1 = fully revealed.
  final double revealProgress;

  /// The content being revealed.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (revealProgress >= 1.0) return child;
    if (revealProgress <= 0.0) return const SizedBox.shrink();

    return ClipPath(
      clipper: _CircleRevealClipper(revealProgress),
      child: child,
    );
  }
}

class _CircleRevealClipper extends CustomClipper<Path> {
  _CircleRevealClipper(this.progress);
  final double progress;

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(
      (size.width / 2) * (size.width / 2) +
          (size.height / 2) * (size.height / 2),
    );
    final radius = maxRadius * progress;
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircleRevealClipper old) => progress != old.progress;
}

// ---------------------------------------------------------------------------
// PreloaderParticlePainter
// ---------------------------------------------------------------------------

/// Lightweight ambient particle field for the preloader background.
/// Much simpler than the main constellation — just drifting dots.
class PreloaderParticles extends StatefulWidget {
  const PreloaderParticles({
    super.key,
    this.particleCount = 50,
    this.color,
  });

  final int particleCount;
  final Color? color;

  @override
  State<PreloaderParticles> createState() => _PreloaderParticlesState();
}

class _PreloaderParticlesState extends State<PreloaderParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_FloatingParticle> _particles;
  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _particles = [];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  void _initParticles(Size size) {
    if (size.isEmpty) return;
    final rng = math.Random(7);
    _particles = List.generate(widget.particleCount, (_) =>
      _FloatingParticle(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        vx: (rng.nextDouble() - 0.5) * 0.3,
        vy: (rng.nextDouble() - 0.5) * 0.15 - 0.1, // slight upward drift
        radius: rng.nextDouble() * 1.2 + 0.3,
        opacity: rng.nextDouble() * 0.3 + 0.05,
        phase: rng.nextDouble() * math.pi * 2,
      ),
    );
    _lastSize = size;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          if (size != _lastSize || _particles.isEmpty) {
            _initParticles(size);
          }
          return AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              // Update positions
              for (final p in _particles) {
                p
                  ..x += p.vx
                  ..y += p.vy;
                if (p.x < 0) p.x = size.width;
                if (p.x > size.width) p.x = 0;
                if (p.y < 0) p.y = size.height;
                if (p.y > size.height) p.y = 0;
              }
              return CustomPaint(
                painter: _FloatingParticlePainter(
                  particles: _particles,
                  color: widget.color ?? AppColors.accent,
                  time: _controller.value,
                ),
                size: size,
              );
            },
          );
        },
      ),
    ),
  );
}

class _FloatingParticle {
  _FloatingParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.opacity,
    required this.phase,
  });

  double x, y, vx, vy;
  final double radius;
  final double opacity;
  final double phase;
}

class _FloatingParticlePainter extends CustomPainter {
  _FloatingParticlePainter({
    required this.particles,
    required this.color,
    required this.time,
  });

  final List<_FloatingParticle> particles;
  final Color color;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final glowPaint = Paint();

    for (final p in particles) {
      // Gentle twinkle
      final twinkle =
          (math.sin(time * math.pi * 2 + p.phase) * 0.3 + 0.7).clamp(0.0, 1.0);
      final alpha = (p.opacity * twinkle).clamp(0.0, 1.0);

      paint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(p.x, p.y), p.radius, paint);

      // Subtle glow on larger particles
      if (p.radius > 0.8) {
        glowPaint
          ..color = color.withValues(alpha: alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(p.x, p.y), p.radius * 3, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_FloatingParticlePainter old) => true;
}

// ---------------------------------------------------------------------------
// FilmGrainOverlay (lightweight version for preloader)
// ---------------------------------------------------------------------------

/// Thin film grain noise overlay to match the cinematic aesthetic.
class PreloaderFilmGrain extends StatefulWidget {
  const PreloaderFilmGrain({super.key, this.opacity = 0.03});
  final double opacity;

  @override
  State<PreloaderFilmGrain> createState() => _PreloaderFilmGrainState();
}

class _PreloaderFilmGrainState extends State<PreloaderFilmGrain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _GrainPainter(
          seed: (_controller.value * 1000).toInt(),
          opacity: widget.opacity,
        ),
        size: MediaQuery.sizeOf(context),
      ),
    ),
  );
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.seed, required this.opacity});
  final int seed;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final paint = Paint();
    // Sparse grain — only ~200 dots for performance
    for (var i = 0; i < 200; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final a = rng.nextDouble() * opacity;
      paint.color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => seed != old.seed;
}
