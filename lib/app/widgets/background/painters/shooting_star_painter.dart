import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui' show PointMode;

// Kayan yıldız çizici - profesyonel astronomik hesaplamalar
class ShootingStarPainter extends CustomPainter {
  final double time;
  final Offset mousePosition;
  final List<ShootingStar> shootingStars = [];

  // Statik olarak yıldızları tutma
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

    // Leonids meteor yağmuru parametreleri
    const radiantRA = 152.0; // Radiant sağ açıklık (derece)
    const radiantDec = 22.0; // Radiant yükselme (derece)
    const zhr = 15.0; // Saatlik zenit meteor oranı

    // Daha fazla kayan yıldız - 20 adet (önceki 12 yerine)
    _cachedShootingStars = List.generate(20, (i) {
      // Radiant noktasından yayılma açısı (15-30 derece arası)
      final dispersionAngle = math.pi / 12 + random.nextDouble() * math.pi / 12;

      // Meteor hızı (71 km/s tipik Leonids hızı)
      // Farklı hızlarda meteorlar için çeşitlilik ekle
      final speedFactor =
          0.7 + random.nextDouble() * 0.6; // 0.7x - 1.3x hız çarpanı

      // Hızı artırdık - daha görünür olması için
      final speed = (0.0005 + random.nextDouble() * 0.0003) * speedFactor;

      // Başlangıç pozisyonu - ekranın farklı bölgelerinden
      // Daha geniş bir alandan başlasınlar
      final startX = random.nextDouble(); // Tüm ekran genişliği
      final startY =
          random.nextDouble() * 0.5; // Üst yarım kısım - daha geniş alan

      // Meteor yolu açısı - daha gerçekçi fizik için
      // Yerçekimi etkisi altında düşen meteorlar gibi
      final baseAngle =
          (radiantRA * math.pi / 180) + math.pi; // Radiant'ın tersi yönü
      final angle = baseAngle + (random.nextDouble() - 0.5) * dispersionAngle;

      // Meteor parlaklığı ve boyutu - daha gerçekçi dağılım
      // Parlaklık dağılımı - çoğu meteor sönük, az sayıda parlak
      final magnitude =
          (math.pow(random.nextDouble(), 2) * 2 - 1)
              as double; // Daha çok sönük meteor

      // Boyutu artırdık - daha görünür olması için
      final size = 1.0 + magnitude * 0.8; // Parlaklığa bağlı boyut - daha büyük

      // Kuyruk uzunluğu - hıza ve parlaklığa bağlı
      // Kuyruk uzunluğunu artırdık - daha görünür olması için
      final tailLength = (12 + magnitude * 5) * speedFactor;

      // Gecikme - daha doğal görünüm için rastgele başlangıç zamanları
      // Gecikmeyi azalttık - daha sık meteor yağmuru için
      final delay =
          random.nextDouble() *
          20; // 20 saniye içinde rastgele başlangıç (önceki 40 yerine)

      return ShootingStar(
        startX: startX,
        startY: startY,
        angle: angle,
        speed: speed,
        tailLength: tailLength,
        delay: delay,
        maxDistance: 0.5 + random.nextDouble() * 0.4, // Daha uzun görünür yol
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
          // Daha kısa gecikme - daha sık meteor yağmuru
          star.delay =
              10 +
              math.Random().nextDouble() *
                  30; // 10-40 saniye arası (önceki 20-60 yerine)
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

        // Atmosferik perspektif ve parlaklık hesaplaması - daha gerçekçi
        final baseOpacity = _calculateMeteorBrightness(
          star.progress,
          star.magnitude,
        );

        if (baseOpacity > 0.01) {
          // Meteor başı ve kuyruk noktaları
          final points = <Offset>[];
          final pointPaints = <Paint>[];

          // Meteor başı - daha parlak
          points.add(Offset(currentX, currentY));
          pointPaints.add(
            Paint()
              ..color = Colors.white.withOpacity(
                (baseOpacity * 1.5).clamp(0.0, 1.0), // Daha parlak baş
              )
              ..strokeWidth =
                  star.size *
                  1.2 // Daha büyük baş
              ..strokeCap = StrokeCap.round,
          );

          // Meteor kuyruğu - daha gerçekçi parçacık fiziği
          // Parçacık sayısını artırdık - daha görünür kuyruk için
          final particleCount =
              (star.tailLength * baseOpacity).round() +
              5; // Daha fazla parçacık
          for (int i = 1; i <= particleCount; i++) {
            final t = i / particleCount;

            // Türbülans - daha doğal kuyruk hareketi
            final turbulence =
                math.sin(t * math.pi * 3 + currentTime * 0.1) * (1 - t) * 0.8;

            // Kuyruk pozisyonu - daha doğal eğri
            final tailX =
                currentX - math.cos(star.angle) * (i * 3.0); // Daha uzun kuyruk
            final tailY =
                currentY -
                math.sin(star.angle) * (i * 3.0) +
                turbulence; // Daha uzun kuyruk

            points.add(Offset(tailX, tailY));

            // Parçacık parlaklığı - daha doğal azalma
            // Parlaklığı artırdık - daha görünür kuyruk için
            final particleOpacity = (baseOpacity * math.pow(1 - t, 1.5) * 0.9)
                .clamp(0.0, 1.0); // Daha parlak kuyruk
            final particleSize =
                star.size * (1 - math.pow(t, 0.6)) * 1.1; // Daha büyük kuyruk

            pointPaints.add(
              Paint()
                ..color = Colors.white.withOpacity(particleOpacity)
                ..strokeWidth = particleSize
                ..strokeCap = StrokeCap.round,
            );
          }

          // Meteor ve parçacıkları çiz
          for (int i = 0; i < points.length; i++) {
            canvas.drawPoints(PointMode.points, [points[i]], pointPaints[i]);
          }
        }
      }
    }

    _cachedShootingStars = List.from(shootingStars);
  }

  // Meteor hareketi için özel fizik fonksiyonu - daha gerçekçi
  double _meteorMotion(double t) {
    // Atmosfer sürtünmesi ve yerçekimi etkisi - daha doğal hareket
    return 4 * t * (1 - t) * math.sin(t * math.pi * 0.8) + t;
  }

  // Meteor parlaklığı hesaplama - daha gerçekçi
  double _calculateMeteorBrightness(double progress, double magnitude) {
    // Atmosferik sönümlenme ve parlaklık değişimi
    // Meteor atmosfere girdikçe parlar, sonra söner
    final atmosphericEffect = math.sin(progress * math.pi) * 0.7 + 0.3;
    final baseBrightness = 0.4 + (1 - magnitude) * 0.5; // Daha parlak meteorlar
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
  final double magnitude; // Yıldız parlaklığı (-1 ile 1 arası)
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
