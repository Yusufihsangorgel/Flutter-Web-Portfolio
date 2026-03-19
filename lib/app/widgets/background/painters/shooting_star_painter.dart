import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui' show PointMode;

// Shooting star painter - astronomical meteor shower simulation
class ShootingStarPainter extends CustomPainter {
  final double time;
  final Offset mousePosition;
  final List<ShootingStar> shootingStars = [];

  static List<ShootingStar>? _cachedShootingStars;

  ShootingStarPainter({required this.time, required this.mousePosition}) {
    if (_cachedShootingStars == null || _cachedShootingStars!.isEmpty) {
      _initializeStars();
    }

    if (_cachedShootingStars != null) {
      shootingStars.addAll(_cachedShootingStars!);
    }
  }

  void _initializeStars() {
    final random = math.Random(42);

    // Leonids meteor shower parameters
    const radiantRA = 152.0;
    const radiantDec = 22.0;
    const zhr = 15.0;

    _cachedShootingStars = List.generate(20, (i) {
      final dispersionAngle = math.pi / 12 + random.nextDouble() * math.pi / 12;
      final speedFactor = 0.7 + random.nextDouble() * 0.6;
      final speed = (0.0005 + random.nextDouble() * 0.0003) * speedFactor;

      final startX = random.nextDouble();
      final startY = random.nextDouble() * 0.5;

      // Meteor trajectory angle derived from radiant point
      final baseAngle = (radiantRA * math.pi / 180) + math.pi;
      final angle = baseAngle + (random.nextDouble() - 0.5) * dispersionAngle;

      // Power-law brightness distribution: most meteors are faint
      final magnitude = (math.pow(random.nextDouble(), 2) * 2 - 1) as double;
      final size = 1.0 + magnitude * 0.8;
      final tailLength = (12 + magnitude * 5) * speedFactor;
      final delay = random.nextDouble() * 20;

      return ShootingStar(
        startX: startX,
        startY: startY,
        angle: angle,
        speed: speed,
        tailLength: tailLength,
        delay: delay,
        maxDistance: 0.5 + random.nextDouble() * 0.4,
        size: size,
        active: false,
        lastActivationTime: -100,
        magnitude: magnitude,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final totalSeconds = (time * 3600);
    _drawShootingStars(canvas, size, totalSeconds);
  }

  void _drawShootingStars(Canvas canvas, Size size, double currentTime) {
    for (var star in shootingStars) {
      final timeSinceLastActivation = currentTime - star.lastActivationTime;

      if (!star.active && timeSinceLastActivation >= star.delay) {
        star.active = true;
        star.progress = 0.0;
        star.lastActivationTime = currentTime;
      }

      if (star.active) {
        star.progress += star.speed;

        if (star.progress >= 1.0) {
          star.active = false;
          star.lastActivationTime = currentTime;
          star.delay = 10 + math.Random().nextDouble() * 30;
          continue;
        }

        final easedProgress = _meteorMotion(star.progress);
        final currentX =
            size.width *
            (star.startX +
                math.cos(star.angle) * star.maxDistance * easedProgress);
        final currentY =
            size.height *
            (star.startY +
                math.sin(star.angle) * star.maxDistance * easedProgress);

        final baseOpacity = _calculateMeteorBrightness(
          star.progress,
          star.magnitude,
        );

        if (baseOpacity > 0.01) {
          final points = <Offset>[];
          final pointPaints = <Paint>[];

          // Meteor head
          points.add(Offset(currentX, currentY));
          pointPaints.add(
            Paint()
              ..color = Colors.white.withOpacity(
                (baseOpacity * 1.5).clamp(0.0, 1.0),
              )
              ..strokeWidth = star.size * 1.2
              ..strokeCap = StrokeCap.round,
          );

          // Meteor tail with turbulence for natural motion
          final particleCount =
              (star.tailLength * baseOpacity).round() + 5;
          for (int i = 1; i <= particleCount; i++) {
            final t = i / particleCount;
            final turbulence =
                math.sin(t * math.pi * 3 + currentTime * 0.1) * (1 - t) * 0.8;

            final tailX = currentX - math.cos(star.angle) * (i * 3.0);
            final tailY =
                currentY - math.sin(star.angle) * (i * 3.0) + turbulence;

            points.add(Offset(tailX, tailY));

            final particleOpacity = (baseOpacity * math.pow(1 - t, 1.5) * 0.9)
                .clamp(0.0, 1.0);
            final particleSize = star.size * (1 - math.pow(t, 0.6)) * 1.1;

            pointPaints.add(
              Paint()
                ..color = Colors.white.withOpacity(particleOpacity)
                ..strokeWidth = particleSize
                ..strokeCap = StrokeCap.round,
            );
          }

          for (int i = 0; i < points.length; i++) {
            canvas.drawPoints(PointMode.points, [points[i]], pointPaints[i]);
          }
        }
      }
    }

    _cachedShootingStars = List.from(shootingStars);
  }

  // Custom physics function for meteor motion - atmospheric drag + gravity
  double _meteorMotion(double t) {
    return 4 * t * (1 - t) * math.sin(t * math.pi * 0.8) + t;
  }

  // Brightness curve: meteor brightens on entry then fades
  double _calculateMeteorBrightness(double progress, double magnitude) {
    final atmosphericEffect = math.sin(progress * math.pi) * 0.7 + 0.3;
    final baseBrightness = 0.4 + (1 - magnitude) * 0.5;
    return (baseBrightness * atmosphericEffect).clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(ShootingStarPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}

class ShootingStar {
  final double startX;
  final double startY;
  final double angle;
  final double speed;
  final double tailLength;
  double delay;
  final double maxDistance;
  final double size;
  final double magnitude;
  bool active;
  double progress = 0.0;
  double lastActivationTime;

  ShootingStar({
    required this.startX,
    required this.startY,
    required this.angle,
    required this.speed,
    required this.tailLength,
    required this.delay,
    required this.maxDistance,
    required this.size,
    required this.active,
    required this.lastActivationTime,
    required this.magnitude,
  });
}
