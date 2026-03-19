import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_web_portfolio/app/controllers/shared_background_controller.dart';

import 'painters/star_field_painter.dart';
import 'painters/shooting_star_painter.dart';
import 'painters/deep_space_painter.dart';
import 'painters/moon_surface_painter.dart';
import 'widgets/rocket_widget.dart';

class CosmicBackground extends StatefulWidget {
  const CosmicBackground({
    super.key,
    this.scrollController,
    this.pageHeight = 0,
    this.animationController,
  });

  final ScrollController? scrollController;
  final double pageHeight;
  final AnimationController? animationController;

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with SingleTickerProviderStateMixin {
  Offset _rocketPosition = Offset.zero;
  Offset _rocketVelocity = Offset.zero;
  double _rocketRotation = math.pi / 2;
  late Ticker _physicsTicker;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _rocketVelocity = Offset(
      0.6 + math.Random().nextDouble() * 1.2,
      0.3 + math.Random().nextDouble() * 1.0,
    );

    // Use Ticker instead of Timer.periodic — syncs with display refresh rate
    _physicsTicker = createTicker((_) {
      if (mounted) {
        setState(_updateRocketPhysics);
      }
    })..start();
  }

  @override
  void dispose() {
    _physicsTicker.dispose();
    super.dispose();
  }

  void _updateRocketPhysics() {
    final size = MediaQuery.of(context).size;
    if (size.isEmpty) return;

    if (!_initialized) {
      _rocketPosition = Offset(size.width / 2, size.height / 2);
      _initialized = true;
    }

    final minX = size.width * 0.05;
    final maxX = size.width * 0.95;
    final minY = size.height * 0.05;
    final maxY = size.height * 0.95;

    const dt = 1.0 / 90.0;

    final attractors = [
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.8, size.height * 0.8),
    ];

    const attractorMasses = [0.5, 0.5, 0.8, 0.5, 0.5];
    final time = DateTime.now().millisecondsSinceEpoch / 15000;
    final timeFactor = math.sin(time) * 0.15 + 0.85;

    var acceleration = Offset.zero;

    for (int i = 0; i < attractors.length; i++) {
      final dx = attractors[i].dx - _rocketPosition.dx;
      final dy = attractors[i].dy - _rocketPosition.dy;
      final distSq = dx * dx + dy * dy;
      final dist = math.sqrt(distSq);

      if (dist > 10.0) {
        final force = attractorMasses[i] * timeFactor / distSq * 6.0;
        acceleration += Offset(dx / dist * force, dy / dist * force);
      }
    }

    acceleration += Offset(
      math.sin(_rocketPosition.dx / 70 + time) * 0.02,
      math.cos(_rocketPosition.dy / 70 + time * 1.3) * 0.02,
    );

    _rocketVelocity += acceleration * dt * 1.5;

    final speed = _rocketVelocity.distance;
    if (speed > 0) {
      if (speed < 0.8) _rocketVelocity = _rocketVelocity * (0.8 / speed);
      if (speed > 2.5) _rocketVelocity = _rocketVelocity * (2.5 / speed);
    } else {
      final angle = math.Random().nextDouble() * 2 * math.pi;
      _rocketVelocity = Offset(math.cos(angle), math.sin(angle)) * 0.8;
    }

    var newPos = _rocketPosition + _rocketVelocity * dt * 60;

    // Edge deceleration
    if (newPos.dx < minX + 20 && _rocketVelocity.dx < 0) {
      _rocketVelocity = Offset(_rocketVelocity.dx * 0.95, _rocketVelocity.dy);
    } else if (newPos.dx > maxX - 20 && _rocketVelocity.dx > 0) {
      _rocketVelocity = Offset(_rocketVelocity.dx * 0.95, _rocketVelocity.dy);
    }
    if (newPos.dy < minY + 20 && _rocketVelocity.dy < 0) {
      _rocketVelocity = Offset(_rocketVelocity.dx, _rocketVelocity.dy * 0.95);
    } else if (newPos.dy > maxY - 20 && _rocketVelocity.dy > 0) {
      _rocketVelocity = Offset(_rocketVelocity.dx, _rocketVelocity.dy * 0.95);
    }

    // Boundary reflection
    if (newPos.dx < minX) {
      newPos = Offset(minX + 2, newPos.dy);
      _rocketVelocity = Offset(-_rocketVelocity.dx * 0.8, _rocketVelocity.dy * 0.95);
    } else if (newPos.dx > maxX) {
      newPos = Offset(maxX - 2, newPos.dy);
      _rocketVelocity = Offset(-_rocketVelocity.dx * 0.8, _rocketVelocity.dy * 0.95);
    }
    if (newPos.dy < minY) {
      newPos = Offset(newPos.dx, minY + 2);
      _rocketVelocity = Offset(_rocketVelocity.dx * 0.95, -_rocketVelocity.dy * 0.8);
    } else if (newPos.dy > maxY) {
      newPos = Offset(newPos.dx, maxY - 2);
      _rocketVelocity = Offset(_rocketVelocity.dx * 0.95, -_rocketVelocity.dy * 0.8);
    }

    _rocketPosition = newPos;

    // Rotation
    var targetRot = _rocketVelocity.distance > 0
        ? math.atan2(_rocketVelocity.dy, _rocketVelocity.dx) + math.pi / 2
        : _rocketRotation;
    if (targetRot.isNaN) targetRot = math.pi / 2;
    _rocketRotation = _lerpAngle(_rocketRotation, targetRot, 0.05);

    SharedBackgroundController.rocketX = _rocketPosition.dx;
    SharedBackgroundController.rocketY = _rocketPosition.dy;
    SharedBackgroundController.rocketRotation = _rocketRotation;
  }

  @override
  Widget build(BuildContext context) {
    final animController =
        widget.animationController ?? SharedBackgroundController.animationController;
    final mousePosition = SharedBackgroundController.mousePosition;

    if (animController == null) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000510), Color(0xFF00101F)],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => MouseRegion(
        onHover: (event) => SharedBackgroundController.updateMousePosition(event.localPosition),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF000510), Color(0xFF00101F), Color(0xFF001429)],
                ),
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                painter: DeepSpacePainter(time: animController.value),
                size: Size.infinite,
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: StarFieldPainter(
                  animController: animController,
                  scrollOffset: widget.scrollController?.offset ?? 0,
                ),
              ),
            ),
            _buildMoon(animController),
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: animController,
                builder: (_, __) => CustomPaint(
                  painter: ShootingStarPainter(
                    time: animController.value,
                    mousePosition: mousePosition.value,
                  ),
                ),
              ),
            ),
            RepaintBoundary(
              child: widget.scrollController != null && widget.pageHeight > 0
                  ? _buildScrollBasedRocket(constraints, animController)
                  : _buildFreeRoamingRocket(animController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoon(AnimationController animController) => Positioned(
    top: 120,
    right: 120,
    child: RepaintBoundary(
      child: AnimatedBuilder(
        animation: animController,
        builder: (_, __) {
          final moonTime = animController.value * 24 * 60 * 60;
          final moonOffset = Offset(
            math.sin(moonTime * 0.00005) * 10,
            math.cos(moonTime * 0.00005) * 5,
          );

          SharedBackgroundController.moonX ??= moonOffset.dx;
          SharedBackgroundController.moonY ??= moonOffset.dy;

          SharedBackgroundController.moonX = SharedBackgroundController.moonX! +
              (moonOffset.dx - SharedBackgroundController.moonX!) * 0.01;
          SharedBackgroundController.moonY = SharedBackgroundController.moonY! +
              (moonOffset.dy - SharedBackgroundController.moonY!) * 0.01;

          return Transform.translate(
            offset: Offset(SharedBackgroundController.moonX!, SharedBackgroundController.moonY!),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.2, -0.2),
                  radius: 0.9,
                  colors: [Color(0xFFF5F5F5), Color(0xFFE0E0E0), Color(0xFFBDBDBD), Color(0xFFAAAAAA)],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(color: Colors.white.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: 3),
                ],
              ),
              child: ClipOval(
                child: CustomPaint(painter: MoonSurfacePainter(), size: const Size(70, 70)),
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _buildScrollBasedRocket(BoxConstraints constraints, AnimationController animController) =>
      AnimatedBuilder(
        animation: Listenable.merge([animController, widget.scrollController!]),
        builder: (_, __) {
          final scrollProgress = widget.scrollController!.hasClients
              ? (widget.scrollController!.position.pixels / (widget.pageHeight * 0.8)).clamp(0.0, 1.0)
              : 0.0;

          final rocketY = constraints.maxHeight * scrollProgress;
          const sectionCount = 5;
          final sectionIndex = (scrollProgress * sectionCount).floor();
          final sectionProgress = (scrollProgress * sectionCount) - sectionIndex;

          final (targetXPos, targetAngle) = switch (sectionIndex) {
            0 => (
              constraints.maxWidth * (0.2 + _easeInOut(sectionProgress) * 0.6),
              math.pi * 1.6 + math.sin(_easeInOut(sectionProgress) * math.pi) * 0.2,
            ),
            1 => (
              constraints.maxWidth * (0.8 - _easeInOut(sectionProgress) * 0.5),
              math.pi * 1.45 + math.cos(_easeInOut(sectionProgress) * math.pi) * 0.2,
            ),
            2 => (
              constraints.maxWidth * (0.3 + _easeInOut(sectionProgress) * 0.2),
              math.pi * 1.5 + math.sin(_easeInOut(sectionProgress) * math.pi * 2) * 0.1,
            ),
            3 => (
              constraints.maxWidth * (0.5 + math.sin(_easeInOut(sectionProgress) * math.pi) * 0.3),
              math.pi * 1.5 + math.cos(_easeInOut(sectionProgress) * math.pi * 2) * 0.2,
            ),
            4 => (
              constraints.maxWidth * (0.7 - _easeInOut(sectionProgress) * 0.4),
              math.pi * 1.45 + math.sin(_easeInOut(sectionProgress) * math.pi) * 0.15,
            ),
            _ => (constraints.maxWidth * 0.5, math.pi * 1.5),
          };

          final realTime = animController.value * 3600;
          final xWithOscillation = targetXPos + math.sin(realTime * 0.001) * 5;
          final angleWithOscillation = targetAngle + math.sin(realTime * 0.0005) * 0.015;

          final lastX = SharedBackgroundController.rocketX ?? xWithOscillation;
          final smoothX = lastX + (xWithOscillation - lastX).clamp(-1.5, 1.5);
          SharedBackgroundController.rocketX = smoothX;
          SharedBackgroundController.rocketY = 80 + rocketY;

          final lastAngle = SharedBackgroundController.rocketRotation ?? angleWithOscillation;
          var angleDiff = angleWithOscillation - lastAngle;
          if (angleDiff > math.pi) angleDiff -= 2 * math.pi;
          if (angleDiff < -math.pi) angleDiff += 2 * math.pi;
          final smoothAngle = lastAngle + angleDiff.clamp(-0.01, 0.01);
          SharedBackgroundController.rocketRotation = smoothAngle;

          return Positioned(
            left: smoothX,
            top: 80 + rocketY,
            child: Transform.rotate(
              angle: smoothAngle,
              child: RocketWidget(animController: animController),
            ),
          );
        },
      );

  Widget _buildFreeRoamingRocket(AnimationController animController) => Positioned(
    left: _rocketPosition.dx - 25,
    top: _rocketPosition.dy - 50,
    child: Transform.rotate(
      angle: _rocketRotation,
      child: RocketWidget(animController: animController, isDragging: false),
    ),
  );

  double _easeInOut(double t) =>
      t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1;

  double _lerpAngle(double current, double target, double factor) {
    var diff = target - current;
    while (diff > math.pi) diff -= 2 * math.pi;
    while (diff < -math.pi) diff += 2 * math.pi;
    return current + diff * factor;
  }
}
