import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/controllers/shared_background_controller.dart';

import 'painters/star_field_painter.dart';
import 'painters/shooting_star_painter.dart';
import 'painters/deep_space_painter.dart';
import 'painters/moon_surface_painter.dart';

import 'widgets/rocket_widget.dart';

class CosmicBackground extends StatefulWidget {
  final ScrollController? scrollController;
  final double pageHeight;
  final AnimationController? animationController;

  const CosmicBackground({
    super.key,
    this.scrollController,
    this.pageHeight = 0,
    this.animationController,
  });

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with SingleTickerProviderStateMixin {
  late Offset rocketPosition;
  late Offset rocketVelocity;
  late double rocketRotation;
  late Timer rocketTimer;

  @override
  void initState() {
    super.initState();

    rocketPosition = Offset(0, 0);
    rocketVelocity = Offset(
      0.6 + math.Random().nextDouble() * 1.2,
      0.3 + math.Random().nextDouble() * 1.0,
    );
    rocketRotation = math.pi / 2;

    rocketTimer = Timer.periodic(Duration(milliseconds: 20), (timer) {
      if (mounted) {
        setState(() {
          _updateRocketPosition();
        });
      }
    });
  }

  @override
  void dispose() {
    rocketTimer.cancel();
    super.dispose();
  }

  void _updateRocketPosition() {
    final size = MediaQuery.of(context).size;

    final minX = size.width * 0.05;
    final maxX = size.width * 0.95;
    final minY = size.height * 0.05;
    final maxY = size.height * 0.95;

    // --- ORBITAL PHYSICS ALGORITHM ---

    final dt = 1.0 / 90.0;

    // Multiple gravity attractors for complex orbital motion
    final List<Offset> attractors = [
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.8, size.height * 0.8),
    ];

    final List<double> attractorMasses = [0.5, 0.5, 0.8, 0.5, 0.5];

    Offset acceleration = Offset.zero;

    // Time-varying factor so orbits shift over time
    final time = DateTime.now().millisecondsSinceEpoch / 15000;
    final timeFactor = math.sin(time) * 0.15 + 0.85;

    for (int i = 0; i < attractors.length; i++) {
      final attractorPos = attractors[i];
      final mass = attractorMasses[i] * timeFactor;

      final dx = attractorPos.dx - rocketPosition.dx;
      final dy = attractorPos.dy - rocketPosition.dy;
      final distanceSquared = dx * dx + dy * dy;
      final distance = math.sqrt(distanceSquared);

      if (distance > 10.0) {
        // Simplified Newtonian gravity: F = G*m/r^2
        final forceMagnitude = mass / distanceSquared * 6.0;
        final forceX = dx / distance * forceMagnitude;
        final forceY = dy / distance * forceMagnitude;
        acceleration += Offset(forceX, forceY);
      }
    }

    // Slight chaotic perturbation for more organic orbits
    final chaosX = math.sin(rocketPosition.dx / 70 + time) * 0.02;
    final chaosY = math.cos(rocketPosition.dy / 70 + time * 1.3) * 0.02;
    acceleration += Offset(chaosX, chaosY);

    rocketVelocity += acceleration * dt * 1.5;

    final speed = math.sqrt(
      rocketVelocity.dx * rocketVelocity.dx +
          rocketVelocity.dy * rocketVelocity.dy,
    );

    if (speed > 0.0) {
      if (speed < 0.8) {
        rocketVelocity = rocketVelocity * (0.8 / speed);
      } else if (speed > 2.5) {
        rocketVelocity = rocketVelocity * (2.5 / speed);
      }
    } else {
      // Prevent zero velocity by assigning a random direction
      final angle = math.Random().nextDouble() * 2 * math.pi;
      rocketVelocity = Offset(math.cos(angle), math.sin(angle)) * 0.8;
    }

    Offset newPosition = rocketPosition + rocketVelocity * dt * 60;

    // Smooth deceleration near edges for natural boundary behavior
    final edgeProximity = 20.0;
    final slowdownFactor = 0.95;

    if (newPosition.dx < minX + edgeProximity) {
      if (rocketVelocity.dx < 0) {
        rocketVelocity = Offset(
          rocketVelocity.dx * slowdownFactor,
          rocketVelocity.dy,
        );
      }
    } else if (newPosition.dx > maxX - edgeProximity) {
      if (rocketVelocity.dx > 0) {
        rocketVelocity = Offset(
          rocketVelocity.dx * slowdownFactor,
          rocketVelocity.dy,
        );
      }
    }

    if (newPosition.dy < minY + edgeProximity) {
      if (rocketVelocity.dy < 0) {
        rocketVelocity = Offset(
          rocketVelocity.dx,
          rocketVelocity.dy * slowdownFactor,
        );
      }
    } else if (newPosition.dy > maxY - edgeProximity) {
      if (rocketVelocity.dy > 0) {
        rocketVelocity = Offset(
          rocketVelocity.dx,
          rocketVelocity.dy * slowdownFactor,
        );
      }
    }

    // Boundary reflection with energy loss for realistic bouncing
    if (newPosition.dx < minX) {
      newPosition = Offset(minX + 2.0, newPosition.dy);
      final vx = -rocketVelocity.dx * 0.8;
      final vy = rocketVelocity.dy * 0.95;
      rocketVelocity = Offset(vx, vy);
    } else if (newPosition.dx > maxX) {
      newPosition = Offset(maxX - 2.0, newPosition.dy);
      final vx = -rocketVelocity.dx * 0.8;
      final vy = rocketVelocity.dy * 0.95;
      rocketVelocity = Offset(vx, vy);
    }

    if (newPosition.dy < minY) {
      newPosition = Offset(newPosition.dx, minY + 2.0);
      final vx = rocketVelocity.dx * 0.95;
      final vy = -rocketVelocity.dy * 0.8;
      rocketVelocity = Offset(vx, vy);
    } else if (newPosition.dy > maxY) {
      newPosition = Offset(newPosition.dx, maxY - 2.0);
      final vx = rocketVelocity.dx * 0.95;
      final vy = -rocketVelocity.dy * 0.8;
      rocketVelocity = Offset(vx, vy);
    }

    rocketPosition = newPosition;

    double targetRotation;
    if (rocketVelocity.dx != 0 || rocketVelocity.dy != 0) {
      // Align rotation to flight direction (+pi/2 so the nose points forward)
      targetRotation =
          math.atan2(rocketVelocity.dy, rocketVelocity.dx) + math.pi / 2;
    } else {
      targetRotation = rocketRotation;
    }

    if (targetRotation.isNaN) {
      targetRotation = math.pi / 2;
    }

    rocketRotation = _smoothAngle(rocketRotation, targetRotation, 0.05);

    SharedBackgroundController.rocketX = rocketPosition.dx;
    SharedBackgroundController.rocketY = rocketPosition.dy;
    SharedBackgroundController.rocketRotation = rocketRotation;
  }

  @override
  Widget build(BuildContext context) {
    // Prefer the animation controller passed as a parameter; fall back to the shared one
    final animController =
        widget.animationController ??
        SharedBackgroundController.animationController;
    final mousePosition = SharedBackgroundController.mousePosition;

    if (animController == null) {
      return Container(color: Colors.black);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Center the rocket on first layout
        if (rocketPosition == Offset(0, 0)) {
          rocketPosition = Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2,
          );
        }

        return MouseRegion(
          onHover: (event) {
            SharedBackgroundController.updateMousePosition(event.localPosition);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Deep space gradient background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF000510),
                      Color(0xFF00101F),
                      Color(0xFF001429),
                    ],
                  ),
                ),
              ),

              // Distant galaxies and nebulae
              RepaintBoundary(
                child: CustomPaint(
                  painter: DeepSpacePainter(time: animController.value),
                  size: Size.infinite,
                ),
              ),

              // Star field
              RepaintBoundary(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: StarFieldPainter(
                    animController: animController,
                    scrollOffset: widget.scrollController?.offset ?? 0,
                  ),
                ),
              ),

              // Moon
              _buildMoon(animController),

              // Shooting stars and comets
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: animController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ShootingStarPainter(
                        time: animController.value,
                        mousePosition: mousePosition.value,
                      ),
                    );
                  },
                ),
              ),

              // Rocket - scroll-based or free-roaming depending on context
              if (widget.scrollController != null && widget.pageHeight > 0)
                _buildScrollBasedRocket(constraints, animController)
              else
                _buildFreeRoamingRocket(constraints, animController),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoon(AnimationController animController) {
    return Positioned(
      top: 120,
      right: 120,
      child: AnimatedBuilder(
        animation: animController,
        builder: (_, __) {
          // Very slow orbital motion simulating a realistic lunar cycle
          final moonTime = animController.value * 24 * 60 * 60;

          final moonPosition = Offset(
            math.sin(moonTime * 0.00005) * 10,
            math.cos(moonTime * 0.00005) * 5,
          );

          // Smooth position tracking to prevent teleportation artifacts
          if (SharedBackgroundController.moonX == null) {
            SharedBackgroundController.moonX = moonPosition.dx;
            SharedBackgroundController.moonY = moonPosition.dy;
          } else {
            final xDiff =
                (moonPosition.dx - SharedBackgroundController.moonX!).abs();
            final yDiff =
                (moonPosition.dy - SharedBackgroundController.moonY!).abs();

            if (xDiff > 5 || yDiff > 5) {
              final smoothX =
                  SharedBackgroundController.moonX! +
                  (moonPosition.dx - SharedBackgroundController.moonX!) * 0.01;
              final smoothY =
                  SharedBackgroundController.moonY! +
                  (moonPosition.dy - SharedBackgroundController.moonY!) * 0.01;

              SharedBackgroundController.moonX = smoothX;
              SharedBackgroundController.moonY = smoothY;
            } else {
              SharedBackgroundController.moonX = moonPosition.dx;
              SharedBackgroundController.moonY = moonPosition.dy;
            }
          }

          final smoothMoonPosition = Offset(
            SharedBackgroundController.moonX!,
            SharedBackgroundController.moonY!,
          );

          return Transform.translate(
            offset: smoothMoonPosition,
            child: ClipOval(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.2, -0.2),
                    radius: 0.9,
                    colors: [
                      Color(0xFFF5F5F5),
                      Color(0xFFE0E0E0),
                      Color(0xFFBDBDBD),
                      Color(0xFFAAAAAA),
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: MoonSurfacePainter(),
                  size: const Size(70, 70),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Scroll-based rocket movement with physics-based smoothing
  Widget _buildScrollBasedRocket(
    BoxConstraints constraints,
    AnimationController animController,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge([animController, widget.scrollController!]),
      builder: (context, child) {
        // Normalized scroll progress (0.0 - 1.0)
        final scrollProgress =
            (widget.scrollController!.hasClients)
                ? (widget.scrollController!.position.pixels /
                        (widget.pageHeight * 0.8))
                    .clamp(0.0, 1.0)
                : 0.0;

        final rocketY = constraints.maxHeight * scrollProgress;

        // Divide scroll range into sections for varied flight paths
        final sectionCount = 5;
        final sectionIndex = (scrollProgress * sectionCount).floor();
        final sectionProgress = (scrollProgress * sectionCount) - sectionIndex;

        double targetXPos = 0;
        double targetAngle = 0;

        switch (sectionIndex) {
          case 0:
            targetXPos =
                constraints.maxWidth *
                (0.2 + _easeInOut(sectionProgress) * 0.6);
            targetAngle =
                math.pi * 1.6 +
                math.sin(_easeInOut(sectionProgress) * math.pi) * 0.2;
            break;
          case 1:
            targetXPos =
                constraints.maxWidth *
                (0.8 - _easeInOut(sectionProgress) * 0.5);
            targetAngle =
                math.pi * 1.45 +
                math.cos(_easeInOut(sectionProgress) * math.pi) * 0.2;
            break;
          case 2:
            targetXPos =
                constraints.maxWidth *
                (0.3 + _easeInOut(sectionProgress) * 0.2);
            targetAngle =
                math.pi * 1.5 +
                math.sin(_easeInOut(sectionProgress) * math.pi * 2) * 0.1;
            break;
          case 3:
            targetXPos =
                constraints.maxWidth *
                (0.5 + math.sin(_easeInOut(sectionProgress) * math.pi) * 0.3);
            targetAngle =
                math.pi * 1.5 +
                math.cos(_easeInOut(sectionProgress) * math.pi * 2) * 0.2;
            break;
          case 4:
            targetXPos =
                constraints.maxWidth *
                (0.7 - _easeInOut(sectionProgress) * 0.4);
            targetAngle =
                math.pi * 1.45 +
                math.sin(_easeInOut(sectionProgress) * math.pi) * 0.15;
            break;
          default:
            targetXPos = constraints.maxWidth * 0.5;
            targetAngle = math.pi * 1.5;
        }

        final realTime = animController.value * 3600;

        // Subtle oscillation for liveliness
        targetXPos += math.sin(realTime * 0.001) * 5;
        targetAngle += math.sin(realTime * 0.0005) * 0.015;

        final lastXPos = SharedBackgroundController.rocketX ?? targetXPos;

        final maxPositionChange = 1.5;
        final xDiff = targetXPos - lastXPos;
        final limitedXDiff = xDiff.clamp(-maxPositionChange, maxPositionChange);
        final smoothXPos = lastXPos + limitedXDiff;

        SharedBackgroundController.rocketX = smoothXPos;
        SharedBackgroundController.rocketY = 80 + rocketY;

        final lastAngle =
            SharedBackgroundController.rocketRotation ?? targetAngle;
        final maxAngleChange = 0.01;
        final angleDiff = (targetAngle - lastAngle);
        final normalizedDiff =
            angleDiff > math.pi
                ? angleDiff - 2 * math.pi
                : (angleDiff < -math.pi ? angleDiff + 2 * math.pi : angleDiff);
        final limitedDiff = normalizedDiff.clamp(
          -maxAngleChange,
          maxAngleChange,
        );
        final smoothAngle = lastAngle + limitedDiff;

        SharedBackgroundController.rocketRotation = smoothAngle;

        return Positioned(
          left: smoothXPos,
          top: 80 + rocketY,
          child: Transform.rotate(
            angle: smoothAngle,
            child: RocketWidget(animController: animController),
          ),
        );
      },
    );
  }

  // Free-roaming rocket driven by the physics simulation in _updateRocketPosition
  Widget _buildFreeRoamingRocket(
    BoxConstraints constraints,
    AnimationController animController,
  ) {
    final rocketX = rocketPosition.dx;
    final rocketY = rocketPosition.dy;

    return Positioned(
      left: rocketX - 25,
      top: rocketY - 50,
      child: Transform.rotate(
        angle: rocketRotation,
        child: RocketWidget(animController: animController, isDragging: false),
      ),
    );
  }

  double _easeInOut(double t) {
    return t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1;
  }

  // Interpolates between two angles via the shortest arc
  double _smoothAngle(
    double currentAngle,
    double targetAngle,
    double smoothFactor,
  ) {
    var angleDiff = targetAngle - currentAngle;
    while (angleDiff > math.pi) angleDiff -= 2 * math.pi;
    while (angleDiff < -math.pi) angleDiff += 2 * math.pi;
    return currentAngle + angleDiff * smoothFactor;
  }
}
