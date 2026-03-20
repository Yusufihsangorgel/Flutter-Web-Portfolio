import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/scene_configs.dart';

// ---------------------------------------------------------------------------
// Spatial grid for O(n) neighbour lookups
// ---------------------------------------------------------------------------
class _SpatialGrid {
  _SpatialGrid(this.cellSize);
  final double cellSize;
  final Map<int, List<int>> _cells = {};

  void clear() => _cells.clear();

  int _key(double x, double y) {
    final cx = (x / cellSize).floor();
    final cy = (y / cellSize).floor();
    return cx * 10000 + cy;
  }

  void insert(int index, double x, double y) {
    _cells.putIfAbsent(_key(x, y), () => []).add(index);
  }

  List<int> getNearby(double x, double y) {
    final cx = (x / cellSize).floor();
    final cy = (y / cellSize).floor();
    final result = <int>[];
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        final key = (cx + dx) * 10000 + (cy + dy);
        final cell = _cells[key];
        if (cell != null) result.addAll(cell);
      }
    }
    return result;
  }
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Mouse-reactive constellation particle system.
/// Particles repel from cursor. Nearby particles draw connecting lines.
class ConstellationParticles extends StatefulWidget {
  const ConstellationParticles({super.key, this.particleCount = 100});
  final int particleCount;

  @override
  State<ConstellationParticles> createState() => _ConstellationParticlesState();
}

class _ConstellationParticlesState extends State<ConstellationParticles>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late List<_Particle> _particles;
  Offset _mousePos = Offset.zero;
  bool _mouseInside = false;
  Size _lastSize = Size.zero;

  /// Generation counter – incremented every tick so the painter knows to repaint.
  int _generation = 0;

  /// Spatial grid reused every tick (avoids allocation).
  late final _SpatialGrid _grid;

  /// Cached scene config – updated via `ever()` instead of Obx.
  late SceneConfig _config;
  Worker? _configWorker;

  static const _connectionDistance = 120.0;
  static const _mouseRepulsionRadius = 200.0;
  static const _mouseRepulsionForce = 50.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _particles = [];
    _grid = _SpatialGrid(_connectionDistance);

    // Initialise config from SceneDirector and listen for changes.
    final director = Get.find<SceneDirector>();
    _config = director.blendedConfig.value;
    _configWorker = ever(director.blendedConfig, (cfg) {
      _config = cfg;
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tick)
      ..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduce particle count for high-contrast / accessibility mode
    // and for narrow (mobile) screens to improve performance.
    final mq = MediaQuery.of(context);
    var effectiveCount = widget.particleCount;
    if (mq.highContrast) {
      effectiveCount = (effectiveCount * 0.5).round();
    }
    if (effectiveCount != _particles.length && !_lastSize.isEmpty) {
      _initParticles(_lastSize, count: effectiveCount);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_controller.isAnimating) {
          _controller.repeat();
        }
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        if (_controller.isAnimating) {
          _controller.stop();
        }
      default:
        break;
    }
  }

  // -- Particle helpers -----------------------------------------------------

  void _initParticles(Size size, {int? count}) {
    if (size.isEmpty) return;
    final rng = math.Random(42);
    final effectiveCount = count ?? widget.particleCount;
    _particles = List.generate(effectiveCount, (_) => _Particle(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        vx: (rng.nextDouble() - 0.5) * 0.4,
        vy: (rng.nextDouble() - 0.5) * 0.4,
        radius: rng.nextDouble() * 1.5 + 0.5,
        opacity: rng.nextDouble() * 0.4 + 0.1,
      ));
    _lastSize = size;
  }

  void _tick() {
    if (_lastSize.isEmpty || _particles.isEmpty) return;

    final speed = _config.particleSpeed;

    for (final p in _particles) {
      p
        ..x += p.vx * speed
        ..y += p.vy * speed;

      // Wrap around
      if (p.x < 0) p.x = _lastSize.width;
      if (p.x > _lastSize.width) p.x = 0;
      if (p.y < 0) p.y = _lastSize.height;
      if (p.y > _lastSize.height) p.y = 0;

      // Mouse repulsion
      if (_mouseInside) {
        final dx = p.x - _mousePos.dx;
        final dy = p.y - _mousePos.dy;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < _mouseRepulsionRadius && dist > 0) {
          final force = (_mouseRepulsionRadius - dist) / _mouseRepulsionRadius;
          p
            ..x += (dx / dist) * force * _mouseRepulsionForce * 0.02
            ..y += (dy / dist) * force * _mouseRepulsionForce * 0.02;
        }
      }
    }

    // Build spatial grid for this frame
    _grid.clear();
    for (var i = 0; i < _particles.length; i++) {
      _grid.insert(i, _particles[i].x, _particles[i].y);
    }

    _generation++;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _configWorker?.dispose();
    _controller
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
      onHover: (e) {
        _mousePos = e.localPosition;
        _mouseInside = true;
      },
      onExit: (_) => _mouseInside = false,
      hitTestBehavior: HitTestBehavior.translucent,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              if (size != _lastSize || _particles.isEmpty) {
                _initParticles(size);
              }
              return AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => CustomPaint(
                  painter: _ConstellationPainter(
                    particles: _particles,
                    accentColor: _config.accent,
                    connectionDistance: _connectionDistance,
                    generation: _generation,
                    grid: _grid,
                  ),
                  size: size,
                ),
              );
            },
          ),
        ),
      ),
    );
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter({
    required this.particles,
    required this.accentColor,
    required this.connectionDistance,
    required this.generation,
    required this.grid,
  });

  final List<_Particle> particles;
  final Color accentColor;

  static final _linePaint = Paint()..style = PaintingStyle.stroke;
  static final _particlePaint = Paint();
  static final _glowPaint = Paint();
  final double connectionDistance;
  final int generation;
  final _SpatialGrid grid;

  /// Cached glow color – only rebuilt when accentColor changes.
  static Color? _cachedGlowColor;
  static List<Color>? _cachedGlowStops;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final particleColor = accentColor.withValues(alpha: 0.6);
    final lineColor = accentColor.withValues(alpha: 0.08);
    final distSqThreshold = connectionDistance * connectionDistance;

    // Draw connection lines using spatial grid (O(n) instead of O(n²))
    _linePaint.strokeWidth = 0.5;

    for (var i = 0; i < particles.length; i++) {
      final pi = particles[i];
      final nearby = grid.getNearby(pi.x, pi.y);
      for (final j in nearby) {
        if (j <= i) continue; // avoid duplicate pairs
        final pj = particles[j];
        final dx = pi.x - pj.x;
        final dy = pi.y - pj.y;
        final distSq = dx * dx + dy * dy;
        if (distSq < distSqThreshold) {
          final dist = math.sqrt(distSq);
          final opacity = (1.0 - dist / connectionDistance) * 0.15;
          _linePaint.color = lineColor.withValues(alpha: opacity);
          canvas.drawLine(
            Offset(pi.x, pi.y),
            Offset(pj.x, pj.y),
            _linePaint,
          );
        }
      }
    }

    // Rebuild glow gradient cache when accent changes
    if (_cachedGlowColor != accentColor) {
      _cachedGlowColor = accentColor;
      _cachedGlowStops = [accentColor.withValues(alpha: 0.05), Colors.transparent];
    }

    // Draw particles
    for (final p in particles) {
      _particlePaint.color = particleColor.withValues(alpha: p.opacity);
      canvas.drawCircle(Offset(p.x, p.y), p.radius, _particlePaint);

      // Glow for larger particles
      if (p.radius > 1.2) {
        _glowPaint.shader = ui.Gradient.radial(
          Offset(p.x, p.y),
          p.radius * 4,
          _cachedGlowStops!,
        );
        canvas.drawCircle(Offset(p.x, p.y), p.radius * 4, _glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter old) =>
      generation != old.generation || accentColor != old.accentColor;
}

// ---------------------------------------------------------------------------
// Particle data
// ---------------------------------------------------------------------------

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.opacity,
  });

  double x;
  double y;
  double vx;
  double vy;
  final double radius;
  final double opacity;
}
