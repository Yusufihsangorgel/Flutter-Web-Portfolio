import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// ===========================================================================
// Shared utilities
// ===========================================================================

final math.Random _rng = math.Random();

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

double _randomRange(double min, double max) =>
    min + _rng.nextDouble() * (max - min);

/// Particle shape types used by [ParticleExplosion].
enum ParticleShape { circle, square, triangle, star }

// ===========================================================================
// 1. ParticleExplosion — burst of particles from a tap point
// ===========================================================================

/// Configuration for [ParticleExplosion].
class ParticleExplosionConfig {
  const ParticleExplosionConfig({
    this.particleCount = 70,
    this.minVelocity = 100.0,
    this.maxVelocity = 400.0,
    this.spreadAngle = 2 * math.pi,
    this.gravity = 600.0,
    this.windX = 0.0,
    this.minLifetime = 1.0,
    this.maxLifetime = 2.0,
    this.minSize = 2.0,
    this.maxSize = 6.0,
    this.colors = const [
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
      Color(0xFFFFE66D),
      Color(0xFF95E1D3),
      Color(0xFFF38181),
      Color(0xFFAA96DA),
    ],
    this.shapes = const [
      ParticleShape.circle,
      ParticleShape.square,
      ParticleShape.triangle,
      ParticleShape.star,
    ],
  });

  final int particleCount;
  final double minVelocity;
  final double maxVelocity;

  /// Total spread angle in radians. 2*pi = all directions.
  final double spreadAngle;
  final double gravity;
  final double windX;
  final double minLifetime;
  final double maxLifetime;
  final double minSize;
  final double maxSize;
  final List<Color> colors;
  final List<ParticleShape> shapes;
}

/// Tap-triggered particle explosion effect.
///
/// Wrap any widget — tapping fires a burst of particles from the tap point.
/// ```dart
/// ParticleExplosion(child: MyWidget())
/// ```
class ParticleExplosion extends StatefulWidget {
  const ParticleExplosion({
    super.key,
    required this.child,
    this.config = const ParticleExplosionConfig(),
    this.enabled = true,
  });

  final Widget child;
  final ParticleExplosionConfig config;
  final bool enabled;

  @override
  State<ParticleExplosion> createState() => ParticleExplosionState();
}

class ParticleExplosionState extends State<ParticleExplosion>
    with TickerProviderStateMixin {
  final List<_ExplosionBurst> _bursts = [];

  /// Programmatically trigger an explosion at [position] (local coordinates).
  void explodeAt(Offset position) {
    if (!widget.enabled) return;
    final controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds:
            (widget.config.maxLifetime * 1000).round(),
      ),
    );
    final burst = _ExplosionBurst(
      origin: position,
      particles: _generateParticles(position),
      controller: controller,
    );
    _bursts.add(burst);
    controller
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _removeBurst(burst);
        }
      })
      ..forward();
    setState(() {});
  }

  void _removeBurst(_ExplosionBurst burst) {
    burst.controller.dispose();
    if (mounted) {
      setState(() => _bursts.remove(burst));
    } else {
      _bursts.remove(burst);
    }
  }

  List<_ExplosionParticle> _generateParticles(Offset origin) {
    final cfg = widget.config;
    const baseAngle = -math.pi / 2; // default: upward center
    return List.generate(cfg.particleCount, (_) {
      final angle =
          baseAngle + _randomRange(-cfg.spreadAngle / 2, cfg.spreadAngle / 2);
      final speed = _randomRange(cfg.minVelocity, cfg.maxVelocity);
      return _ExplosionParticle(
        x: origin.dx,
        y: origin.dy,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        size: _randomRange(cfg.minSize, cfg.maxSize),
        rotation: _randomRange(0, 2 * math.pi),
        rotationSpeed: _randomRange(-6, 6),
        lifetime: _randomRange(cfg.minLifetime, cfg.maxLifetime),
        color: cfg.colors[_rng.nextInt(cfg.colors.length)],
        shape: cfg.shapes[_rng.nextInt(cfg.shapes.length)],
      );
    });
  }

  @override
  void dispose() {
    for (final b in _bursts) {
      b.controller.dispose();
    }
    _bursts.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) => explodeAt(details.localPosition),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          for (final burst in _bursts)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: burst.controller,
                    builder: (_, __) => CustomPaint(
                      painter: _ExplosionPainter(
                        particles: burst.particles,
                        progress: burst.controller.value,
                        gravity: widget.config.gravity,
                        windX: widget.config.windX,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExplosionBurst {
  _ExplosionBurst({
    required this.origin,
    required this.particles,
    required this.controller,
  });
  final Offset origin;
  final List<_ExplosionParticle> particles;
  final AnimationController controller;
}

class _ExplosionParticle {
  _ExplosionParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.lifetime,
    required this.color,
    required this.shape,
  });
  final double x, y, vx, vy;
  final double size, rotation, rotationSpeed, lifetime;
  final Color color;
  final ParticleShape shape;
}

class _ExplosionPainter extends CustomPainter {
  _ExplosionPainter({
    required this.particles,
    required this.progress,
    required this.gravity,
    required this.windX,
  });

  final List<_ExplosionParticle> particles;
  final double progress;
  final double gravity;
  final double windX;

  static final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (progress > 1.0) continue;

      // Normalised age (controller runs for maxLifetime duration).
      final age = progress;
      if (age > 1.0) continue;

      final px = p.x + p.vx * age + 0.5 * windX * age * age;
      final py = p.y + p.vy * age + 0.5 * gravity * age * age;
      final rot = p.rotation + p.rotationSpeed * age;
      final alpha = (1.0 - age).clamp(0.0, 1.0);
      final currentSize = p.size * _lerpDouble(1.0, 0.3, age);

      _paint.color = p.color.withValues(alpha: alpha);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);

      switch (p.shape) {
        case ParticleShape.circle:
          canvas.drawCircle(Offset.zero, currentSize, _paint);
        case ParticleShape.square:
          canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero,
                width: currentSize * 2,
                height: currentSize * 2),
            _paint,
          );
        case ParticleShape.triangle:
          final path = Path()
            ..moveTo(0, -currentSize)
            ..lineTo(currentSize, currentSize)
            ..lineTo(-currentSize, currentSize)
            ..close();
          canvas.drawPath(path, _paint);
        case ParticleShape.star:
          canvas.drawPath(
            _starPath(currentSize, 5),
            _paint,
          );
      }
      canvas.restore();
    }
  }

  Path _starPath(double radius, int points) {
    final path = Path();
    final inner = radius * 0.4;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : inner;
      final angle = (math.pi / points) * i - math.pi / 2;
      final x = math.cos(angle) * r;
      final y = math.sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_ExplosionPainter old) => progress != old.progress;
}

// ===========================================================================
// 2. ConfettiCannon — celebration confetti
// ===========================================================================

/// Firing origin for the confetti cannon.
enum ConfettiOrigin { bottomLeft, bottomRight }

/// Configuration for [ConfettiCannon].
class ConfettiCannonConfig {
  const ConfettiCannonConfig({
    this.particleCount = 120,
    this.origin = ConfettiOrigin.bottomLeft,
    this.burstDuration = const Duration(milliseconds: 600),
    this.totalDuration = const Duration(milliseconds: 3000),
    this.minVelocity = 300.0,
    this.maxVelocity = 800.0,
    this.gravity = 500.0,
    this.airResistance = 0.97,
    this.colors = const [
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
      Color(0xFFFFE66D),
      Color(0xFF95E1D3),
      Color(0xFFF38181),
      Color(0xFFAA96DA),
      Color(0xFF6C5CE7),
      Color(0xFFFF9FF3),
    ],
  });

  final int particleCount;
  final ConfettiOrigin origin;
  final Duration burstDuration;
  final Duration totalDuration;
  final double minVelocity;
  final double maxVelocity;
  final double gravity;

  /// Per-frame velocity multiplier to simulate air drag (0-1).
  final double airResistance;
  final List<Color> colors;
}

/// Programmatically triggered confetti cannon.
///
/// Use a [GlobalKey<ConfettiCannonState>] and call `fire()` to trigger.
/// ```dart
/// final confettiKey = GlobalKey<ConfettiCannonState>();
/// ConfettiCannon(key: confettiKey, child: ...);
/// confettiKey.currentState?.fire();
/// ```
class ConfettiCannon extends StatefulWidget {
  const ConfettiCannon({
    super.key,
    required this.child,
    this.config = const ConfettiCannonConfig(),
  });

  final Widget child;
  final ConfettiCannonConfig config;

  @override
  State<ConfettiCannon> createState() => ConfettiCannonState();
}

class ConfettiCannonState extends State<ConfettiCannon>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  List<_ConfettiPiece> _pieces = [];
  Size _canvasSize = Size.zero;

  /// Fire the confetti cannon.
  void fire() {
    _controller?.dispose();
    _controller = AnimationController(
      vsync: this,
      duration: widget.config.totalDuration,
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() => _pieces = []);
        }
      })
      ..forward();

    _pieces = _generatePieces();
    setState(() {});
  }

  List<_ConfettiPiece> _generatePieces() {
    final cfg = widget.config;
    final isLeft = cfg.origin == ConfettiOrigin.bottomLeft;
    final ox = isLeft ? 0.0 : _canvasSize.width;
    final oy = _canvasSize.height;

    // Angle range: roughly 30-80 degrees upward toward the opposite side
    final minAngle = isLeft ? -math.pi * 0.8 : -math.pi * 0.2;
    final maxAngle = isLeft ? -math.pi * 0.2 : -math.pi * 0.8;

    return List.generate(cfg.particleCount, (i) {
      final angle = _randomRange(
        math.min(minAngle, maxAngle),
        math.max(minAngle, maxAngle),
      );
      final speed = _randomRange(cfg.minVelocity, cfg.maxVelocity);
      // Stagger spawn time within burst duration
      final spawnDelay = _rng.nextDouble() *
          (cfg.burstDuration.inMilliseconds / cfg.totalDuration.inMilliseconds);
      return _ConfettiPiece(
        x: ox,
        y: oy,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        width: _randomRange(6, 12),
        height: _randomRange(3, 6),
        rotX: _randomRange(0, 2 * math.pi),
        rotY: _randomRange(0, 2 * math.pi),
        rotZ: _randomRange(0, 2 * math.pi),
        rotSpeedX: _randomRange(-8, 8),
        rotSpeedY: _randomRange(-8, 8),
        rotSpeedZ: _randomRange(-6, 6),
        color: cfg.colors[_rng.nextInt(cfg.colors.length)],
        spawnDelay: spawnDelay,
      );
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (_pieces.isNotEmpty && _controller != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _ConfettiPainter(
                        pieces: _pieces,
                        progress: _controller!.value,
                        totalDuration: widget.config.totalDuration
                            .inMilliseconds
                            .toDouble(),
                        gravity: widget.config.gravity,
                        airResistance: widget.config.airResistance,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ConfettiPiece {
  _ConfettiPiece({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.width,
    required this.height,
    required this.rotX,
    required this.rotY,
    required this.rotZ,
    required this.rotSpeedX,
    required this.rotSpeedY,
    required this.rotSpeedZ,
    required this.color,
    required this.spawnDelay,
  });
  final double x, y, vx, vy;
  final double width, height;
  final double rotX, rotY, rotZ;
  final double rotSpeedX, rotSpeedY, rotSpeedZ;
  final Color color;

  /// Normalised spawn delay (0-1 within the total duration).
  final double spawnDelay;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.pieces,
    required this.progress,
    required this.totalDuration,
    required this.gravity,
    required this.airResistance,
  });

  final List<_ConfettiPiece> pieces;
  final double progress;
  final double totalDuration;
  final double gravity;
  final double airResistance;

  static final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final totalSec = totalDuration / 1000.0;

    for (final p in pieces) {
      if (progress < p.spawnDelay) continue;

      final elapsed = (progress - p.spawnDelay) / (1.0 - p.spawnDelay);
      if (elapsed > 1.0) continue;

      final t = elapsed * totalSec;

      // Apply air resistance as exponential decay on velocity
      // x = x0 + vx * (1 - r^t) / (1 - r)  (geometric series approximation)
      final drag = math.pow(airResistance, t * 60).toDouble();

      final px = p.x + p.vx * t * drag;
      final py = p.y + p.vy * t * drag + 0.5 * gravity * t * t;

      // Fade out in last 30%
      final alpha = elapsed > 0.7
          ? ((1.0 - elapsed) / 0.3).clamp(0.0, 1.0)
          : 1.0;

      final rotX = p.rotX + p.rotSpeedX * t;
      final rotZ = p.rotZ + p.rotSpeedZ * t;

      // Simulate 3D rotation by scaling width based on rotX
      final scaleX = math.cos(rotX).abs().clamp(0.1, 1.0);
      final scaleY = math.cos(p.rotY + p.rotSpeedY * t).abs().clamp(0.1, 1.0);

      _paint.color = p.color.withValues(alpha: alpha);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rotZ);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.width * scaleX,
          height: p.height * scaleY,
        ),
        _paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => progress != old.progress;
}

// ===========================================================================
// 3. FireworkEffect — firework burst with rising trail
// ===========================================================================

/// Configuration for a single firework.
class FireworkConfig {
  const FireworkConfig({
    this.color = const Color(0xFF4ECDC4),
    this.peakHeightFraction = 0.3,
    this.explosionParticleCount = 80,
    this.riseTime = 0.35,
    this.trailParticleCount = 20,
    this.spreadRadius = 120.0,
  });

  final Color color;

  /// How high the firework rises as a fraction of canvas height (0 = top, 1 = bottom).
  final double peakHeightFraction;
  final int explosionParticleCount;

  /// Fraction of total duration spent rising (0-1).
  final double riseTime;
  final int trailParticleCount;
  final double spreadRadius;
}

/// Firework display with rise, explosion, and settling arcs.
///
/// Use a [GlobalKey<FireworkEffectState>] and call `launch()`.
/// Multiple fireworks can be sequenced by calling `launchSequence()`.
class FireworkEffect extends StatefulWidget {
  const FireworkEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2500),
  });

  final Widget child;
  final Duration duration;

  @override
  State<FireworkEffect> createState() => FireworkEffectState();
}

class FireworkEffectState extends State<FireworkEffect>
    with TickerProviderStateMixin {
  final List<_ActiveFirework> _fireworks = [];
  Size _canvasSize = Size.zero;

  /// Launch a single firework.
  void launch([FireworkConfig config = const FireworkConfig()]) {
    final controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final startX =
        _randomRange(_canvasSize.width * 0.2, _canvasSize.width * 0.8);
    final startY = _canvasSize.height;
    final peakY = _canvasSize.height * config.peakHeightFraction;

    final explosionParticles =
        List.generate(config.explosionParticleCount, (_) {
      final angle = _randomRange(0, 2 * math.pi);
      final speed = _randomRange(40, config.spreadRadius);
      return _FireworkFragment(
        angle: angle,
        speed: speed,
        size: _randomRange(1.5, 3.5),
        drag: _randomRange(0.92, 0.98),
      );
    });

    final fw = _ActiveFirework(
      controller: controller,
      config: config,
      startX: startX,
      startY: startY,
      peakY: peakY,
      explosionParticles: explosionParticles,
    );

    _fireworks.add(fw);

    controller
      ..addListener(() => setState(() {}))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          _removeFirework(fw);
        }
      })
      ..forward();
  }

  /// Launch a sequence of fireworks with [interval] between each.
  void launchSequence(List<FireworkConfig> configs,
      {Duration interval = const Duration(milliseconds: 400)}) {
    for (var i = 0; i < configs.length; i++) {
      Future.delayed(interval * i, () {
        if (mounted) launch(configs[i]);
      });
    }
  }

  void _removeFirework(_ActiveFirework fw) {
    fw.controller.dispose();
    if (mounted) {
      setState(() => _fireworks.remove(fw));
    } else {
      _fireworks.remove(fw);
    }
  }

  @override
  void dispose() {
    for (final fw in _fireworks) {
      fw.controller.dispose();
    }
    _fireworks.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            for (final fw in _fireworks)
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _FireworkPainter(
                        firework: fw,
                        progress: fw.controller.value,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActiveFirework {
  _ActiveFirework({
    required this.controller,
    required this.config,
    required this.startX,
    required this.startY,
    required this.peakY,
    required this.explosionParticles,
  });

  final AnimationController controller;
  final FireworkConfig config;
  final double startX, startY, peakY;
  final List<_FireworkFragment> explosionParticles;
}

class _FireworkFragment {
  _FireworkFragment({
    required this.angle,
    required this.speed,
    required this.size,
    required this.drag,
  });
  final double angle, speed, size, drag;
}

class _FireworkPainter extends CustomPainter {
  _FireworkPainter({
    required this.firework,
    required this.progress,
  });

  final _ActiveFirework firework;
  final double progress;

  static final _paint = Paint();
  static final _glowPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  @override
  void paint(Canvas canvas, Size size) {
    final cfg = firework.config;
    final riseEnd = cfg.riseTime;

    if (progress <= riseEnd) {
      // --- Rising phase ---
      final riseProgress = progress / riseEnd;
      final currentX = firework.startX;
      final currentY =
          _lerpDouble(firework.startY, firework.peakY, Curves.easeOut.transform(riseProgress));

      // Draw trail particles
      _paint.style = PaintingStyle.fill;
      for (var i = 0; i < cfg.trailParticleCount; i++) {
        final trailT = (riseProgress - i * 0.03).clamp(0.0, 1.0);
        final trailY = _lerpDouble(
            firework.startY, firework.peakY, Curves.easeOut.transform(trailT));
        final trailAlpha =
            ((1.0 - (i / cfg.trailParticleCount)) * 0.6).clamp(0.0, 1.0);
        final jitterX = _rng.nextDouble() * 4 - 2;
        _paint.color = cfg.color.withValues(alpha: trailAlpha);
        canvas.drawCircle(
          Offset(currentX + jitterX, trailY),
          _lerpDouble(2.5, 0.8, i / cfg.trailParticleCount),
          _paint,
        );
      }

      // Draw main rising dot
      _paint.color = cfg.color;
      canvas.drawCircle(Offset(currentX, currentY), 3, _paint);
      _glowPaint.color = cfg.color.withValues(alpha: 0.4);
      canvas.drawCircle(Offset(currentX, currentY), 8, _glowPaint);
    } else {
      // --- Explosion phase ---
      final explosionProgress = (progress - riseEnd) / (1.0 - riseEnd);
      final peakX = firework.startX;
      final peakY = firework.peakY;
      const gravity = 150.0;

      final alpha = (1.0 - explosionProgress).clamp(0.0, 1.0);

      for (final frag in firework.explosionParticles) {
        final t = explosionProgress;
        final drag = math.pow(frag.drag, t * 60).toDouble();
        final fx = peakX + math.cos(frag.angle) * frag.speed * t * drag;
        final fy = peakY +
            math.sin(frag.angle) * frag.speed * t * drag +
            0.5 * gravity * t * t;

        _paint.color = cfg.color.withValues(alpha: alpha * 0.9);
        canvas.drawCircle(Offset(fx, fy), frag.size * (1.0 - t * 0.5), _paint);

        // Glow for larger fragments
        if (frag.size > 2.5 && alpha > 0.3) {
          _glowPaint.color = cfg.color.withValues(alpha: alpha * 0.2);
          canvas.drawCircle(Offset(fx, fy), frag.size * 3, _glowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_FireworkPainter old) => progress != old.progress;
}

// ===========================================================================
// 4. DustParticles — ambient floating dust with parallax
// ===========================================================================

/// Ambient floating dust particles with optional mouse parallax.
///
/// ```dart
/// DustParticles(
///   particleCount: 60,
///   child: MyContent(),
/// )
/// ```
class DustParticles extends StatefulWidget {
  const DustParticles({
    super.key,
    required this.child,
    this.particleCount = 60,
    this.minSize = 1.0,
    this.maxSize = 3.0,
    this.minOpacity = 0.1,
    this.maxOpacity = 0.3,
    this.driftSpeed = 0.3,
    this.parallaxFactor = 0.02,
    this.color = Colors.white,
  });

  final Widget child;
  final int particleCount;
  final double minSize;
  final double maxSize;
  final double minOpacity;
  final double maxOpacity;
  final double driftSpeed;

  /// How much particles shift relative to mouse movement.
  final double parallaxFactor;
  final Color color;

  @override
  State<DustParticles> createState() => _DustParticlesState();
}

class _DustParticlesState extends State<DustParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_DustMote> _motes;
  Offset _mouseOffset = Offset.zero;
  Size _lastSize = Size.zero;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _motes = [];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )
      ..addListener(_tick)
      ..repeat();
  }

  void _initMotes(Size size) {
    if (size.isEmpty) return;
    _motes = List.generate(widget.particleCount, (_) {
      return _DustMote(
        x: _rng.nextDouble() * size.width,
        y: _rng.nextDouble() * size.height,
        size: _randomRange(widget.minSize, widget.maxSize),
        opacity: _randomRange(widget.minOpacity, widget.maxOpacity),
        // Brownian motion: small random target offsets
        driftAngle: _randomRange(0, 2 * math.pi),
        driftChangeTimer: _randomRange(0, 3),
        parallaxDepth: _randomRange(0.5, 1.5),
      );
    });
    _lastSize = size;
  }

  void _tick() {
    if (_lastSize.isEmpty || _motes.isEmpty) return;
    const dt = 1 / 60.0; // Approximate frame time

    for (final m in _motes) {
      // Brownian motion: periodically change drift direction
      m.driftChangeTimer -= dt;
      if (m.driftChangeTimer <= 0) {
        m.driftAngle += _randomRange(-math.pi / 2, math.pi / 2);
        m.driftChangeTimer = _randomRange(1.5, 4.0);
      }

      m.x += math.cos(m.driftAngle) * widget.driftSpeed;
      m.y += math.sin(m.driftAngle) * widget.driftSpeed;

      // Wrap around
      if (m.x < -10) m.x = _lastSize.width + 10;
      if (m.x > _lastSize.width + 10) m.x = -10;
      if (m.y < -10) m.y = _lastSize.height + 10;
      if (m.y > _lastSize.height + 10) m.y = -10;
    }

    _generation++;
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) {
        final center = _lastSize.center(Offset.zero);
        _mouseOffset = Offset(
          (e.localPosition.dx - center.dx) * widget.parallaxFactor,
          (e.localPosition.dy - center.dy) * widget.parallaxFactor,
        );
      },
      onExit: (_) => _mouseOffset = Offset.zero,
      hitTestBehavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size =
                        Size(constraints.maxWidth, constraints.maxHeight);
                    if (size != _lastSize || _motes.isEmpty) {
                      _initMotes(size);
                    }
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) => CustomPaint(
                        painter: _DustPainter(
                          motes: _motes,
                          mouseOffset: _mouseOffset,
                          color: widget.color,
                          generation: _generation,
                        ),
                        size: size,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DustMote {
  _DustMote({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.driftAngle,
    required this.driftChangeTimer,
    required this.parallaxDepth,
  });

  double x, y;
  final double size;
  final double opacity;
  double driftAngle;
  double driftChangeTimer;

  /// Depth multiplier for parallax — deeper particles shift more.
  final double parallaxDepth;
}

class _DustPainter extends CustomPainter {
  _DustPainter({
    required this.motes,
    required this.mouseOffset,
    required this.color,
    required this.generation,
  });

  final List<_DustMote> motes;
  final Offset mouseOffset;
  final Color color;
  final int generation;

  static final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    // Batch draw using drawRawPoints for maximum performance on small circles
    final rawPoints = Float32List(motes.length * 2);
    var pointCount = 0;
    final largeParticles = <_DustMote>[];

    for (final m in motes) {
      final px = m.x + mouseOffset.dx * m.parallaxDepth;
      final py = m.y + mouseOffset.dy * m.parallaxDepth;

      if (m.size <= 1.5) {
        rawPoints[pointCount * 2] = px;
        rawPoints[pointCount * 2 + 1] = py;
        pointCount++;
      } else {
        largeParticles.add(m);
      }
    }

    // Draw small particles as raw points
    if (pointCount > 0) {
      _paint
        ..color = color.withValues(alpha: 0.15)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.sublistView(rawPoints, 0, pointCount * 2),
        _paint,
      );
    }

    // Draw larger particles individually for proper sizing
    for (final m in largeParticles) {
      final px = m.x + mouseOffset.dx * m.parallaxDepth;
      final py = m.y + mouseOffset.dy * m.parallaxDepth;
      _paint.color = color.withValues(alpha: m.opacity);
      canvas.drawCircle(Offset(px, py), m.size, _paint);
    }
  }

  @override
  bool shouldRepaint(_DustPainter old) =>
      generation != old.generation || mouseOffset != old.mouseOffset;
}

// ===========================================================================
// 5. SparkTrail — sparks along a path / section divider
// ===========================================================================

/// Configuration for [SparkTrail].
class SparkTrailConfig {
  const SparkTrailConfig({
    this.sparkCount = 40,
    this.color = const Color(0xFF4ECDC4),
    this.secondaryColor,
    this.speed = 1.0,
    this.sparkSize = 2.5,
    this.density = 1.0,
    this.direction = SparkDirection.leftToRight,
    this.height = 2.0,
  });

  final int sparkCount;
  final Color color;

  /// Optional secondary colour for alternating sparks.
  final Color? secondaryColor;

  /// Speed multiplier (1.0 = normal).
  final double speed;
  final double sparkSize;

  /// Density multiplier — affects how many sparks are visible at once.
  final double density;
  final SparkDirection direction;

  /// Height of the spark travel band in logical pixels.
  final double height;
}

enum SparkDirection { leftToRight, rightToLeft, bidirectional }

/// Sparks that travel along a horizontal line — ideal for section dividers.
///
/// ```dart
/// SparkTrail(
///   config: SparkTrailConfig(color: Colors.cyan),
///   width: double.infinity,
/// )
/// ```
class SparkTrail extends StatefulWidget {
  const SparkTrail({
    super.key,
    this.config = const SparkTrailConfig(),
    this.width = double.infinity,
  });

  final SparkTrailConfig config;
  final double width;

  @override
  State<SparkTrail> createState() => _SparkTrailState();
}

class _SparkTrailState extends State<SparkTrail>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Spark> _sparks;
  int _generation = 0;
  double _resolvedWidth = 0;

  @override
  void initState() {
    super.initState();
    _sparks = [];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )
      ..addListener(_tick)
      ..repeat();
  }

  void _initSparks(double width) {
    if (width <= 0) return;
    _resolvedWidth = width;
    final cfg = widget.config;
    _sparks = List.generate(
      (cfg.sparkCount * cfg.density).round(),
      (i) => _createSpark(width, i),
    );
  }

  _Spark _createSpark(double width, int index) {
    final cfg = widget.config;
    final goRight = switch (cfg.direction) {
      SparkDirection.leftToRight => true,
      SparkDirection.rightToLeft => false,
      SparkDirection.bidirectional => _rng.nextBool(),
    };
    final useSecondary = cfg.secondaryColor != null && _rng.nextBool();
    return _Spark(
      x: _randomRange(0, width),
      y: _randomRange(-cfg.height / 2, cfg.height / 2),
      speed: _randomRange(40, 120) * cfg.speed * (goRight ? 1 : -1),
      size: _randomRange(cfg.sparkSize * 0.5, cfg.sparkSize * 1.5),
      phase: _randomRange(0, 2 * math.pi),
      phaseSpeed: _randomRange(3, 8),
      color: useSecondary ? cfg.secondaryColor! : cfg.color,
    );
  }

  void _tick() {
    if (_sparks.isEmpty || _resolvedWidth <= 0) return;
    const dt = 1.0 / 60.0;

    for (var i = 0; i < _sparks.length; i++) {
      final s = _sparks[i];
      s.x += s.speed * dt;
      s.phase += s.phaseSpeed * dt;

      // Wrap around
      if (s.x > _resolvedWidth + 20) {
        s.x = -20;
      } else if (s.x < -20) {
        s.x = _resolvedWidth + 20;
      }
    }

    _generation++;
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.config.height + widget.config.sparkSize * 4;
    return SizedBox(
      width: widget.width,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          if (w != _resolvedWidth || _sparks.isEmpty) {
            _initSparks(w);
          }
          return RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => CustomPaint(
                painter: _SparkPainter(
                  sparks: _sparks,
                  centerY: height / 2,
                  generation: _generation,
                ),
                size: Size(w, height),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Spark {
  _Spark({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.phase,
    required this.phaseSpeed,
    required this.color,
  });

  double x, y;
  final double speed;
  final double size;
  double phase;
  final double phaseSpeed;
  final Color color;
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.sparks,
    required this.centerY,
    required this.generation,
  });

  final List<_Spark> sparks;
  final double centerY;
  final int generation;

  static final _paint = Paint();
  static final _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparks) {
      // Oscillating brightness via sine phase for flash effect
      final brightness = (math.sin(s.phase) * 0.5 + 0.5).clamp(0.0, 1.0);
      final alpha = _lerpDouble(0.1, 0.9, brightness);
      final currentSize = s.size * _lerpDouble(0.6, 1.0, brightness);

      final py = centerY + s.y;

      _paint.color = s.color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(s.x, py), currentSize, _paint);

      // Glow when bright
      if (brightness > 0.6) {
        _glowPaint.color = s.color.withValues(alpha: alpha * 0.3);
        canvas.drawCircle(Offset(s.x, py), currentSize * 2.5, _glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) => generation != old.generation;
}
