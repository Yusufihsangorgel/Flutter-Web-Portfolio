import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui' show PointMode;

// Yıldız Alanı Çizici - Yanıp sönen ve parlayan yıldızlar
class StarFieldPainter extends CustomPainter {
  final AnimationController animController;
  final double scrollOffset;

  // Yıldız verisi için statik tutucular
  static List<Star>? _cachedStars;
  static final _random = math.Random(42);

  StarFieldPainter({required this.animController, this.scrollOffset = 0});

  @override
  void paint(Canvas canvas, Size size) {
    // Yıldızları ilk kez oluşturma veya ekran boyutu değiştiyse yeniden oluşturma
    if (_cachedStars == null) {
      _initializeStars(size);
    }

    // Saniyeler cinsinden gerçek zaman - daha yavaş hareket için
    final realTime = animController.value * 7200; // 2 saatlik bir döngü

    // Yıldızları çiz
    _drawStars(canvas, size, realTime);
  }

  // Yıldızları tek seferde oluştur ve sakla
  void _initializeStars(Size size) {
    const starCount = 1000; // Çok sayıda yıldız
    _cachedStars = List.generate(starCount, (i) {
      // Farklı parlaklık tipleri
      final brightnessType = _random.nextInt(10);
      final isTwinkler = brightnessType < 2; // %20'si yanıp sönen yıldız
      final isVeryBright = brightnessType == 9; // %10'u çok parlak

      // Farklı boyutlar - çoğunlukla küçük
      double starSize = _random.nextDouble() * 1.5 + 0.3;
      if (isVeryBright) starSize += 0.5;

      // Yıldız hareketi için parametreler - çok küçük hareketler
      final movementAmplitude = starSize * 0.3; // Daha küçük hareketler
      final movementSpeed =
          0.00005 + _random.nextDouble() * 0.0001; // Çok daha yavaş

      // Ekranda rastgele konum
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;

      // Her yıldız için özel faz değeri - böylece hepsi farklı zamanlarda yanıp söner
      final phase = _random.nextDouble() * math.pi * 2;

      // Paralaks etkisi için katman - farklı katmanlarda yıldızlar farklı hızda hareket etsin
      final layer = _random.nextDouble();

      return Star(
        x: x,
        y: y,
        size: starSize,
        isTwinkler: isTwinkler,
        isBright: isVeryBright,
        movementAmplitude: movementAmplitude,
        movementSpeed: movementSpeed,
        phase: phase,
        layer: layer,
      );
    });
  }

  // Tüm yıldızları çizme
  void _drawStars(Canvas canvas, Size size, double time) {
    if (_cachedStars == null) return;

    for (var star in _cachedStars!) {
      // Yıldızın temel parlaklığı
      double brightness = star.isBright ? 0.8 : 0.4;

      // Yanıp sönen yıldızlar için parlaklık modülasyonu
      if (star.isTwinkler) {
        // Çok daha yavaş yanıp sönme - 10-20 saniyelik döngüler
        final twinkleSpeed = 0.05 + (star.size * 0.02);
        brightness *=
            0.3 + (math.sin(time * twinkleSpeed + star.phase) + 1) / 2 * 0.6;
      }

      // Yıldızın pozisyonu - çok küçük hareketler
      // Dikkat: Çok yavaş hareket - neredeyse fark edilmeyecek kadar
      double x =
          star.x +
          math.sin(time * star.movementSpeed + star.phase) *
              star.movementAmplitude;
      double y =
          star.y +
          math.cos(time * star.movementSpeed + star.phase) *
              star.movementAmplitude;

      // Parallax etkisi - scroll ile yavaşça hareket
      // Farklı katmanlar farklı hızda hareket etsin
      final parallaxFactor = 0.1 + star.layer * 0.2; // 0.1 - 0.3 arası faktör
      y -= scrollOffset * parallaxFactor;

      // Ekran dışına çıkan yıldızları ekranın diğer ucuna taşı
      // Ama bu kaydırma çok sert olmasın - sürekli bir animasyon hissi için
      y = y % size.height;

      // Yıldız boyutu - sabit
      double starSize = star.size;

      // Yıldızı çiz
      final paint =
          Paint()
            ..color = Colors.white.withOpacity(brightness)
            ..strokeWidth = starSize
            ..strokeCap = StrokeCap.round;

      canvas.drawPoints(PointMode.points, [Offset(x, y)], paint);

      // Parlak yıldızlar için hafif glow efekti
      if (brightness > 0.6) {
        final glowPaint =
            Paint()
              ..color = Colors.white.withOpacity(
                brightness * 0.15,
              ) // Daha hafif glow
              ..strokeWidth = starSize * 2.5
              ..strokeCap = StrokeCap.round;

        canvas.drawPoints(PointMode.points, [Offset(x, y)], glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StarFieldPainter oldDelegate) {
    return oldDelegate.animController.value != animController.value ||
        oldDelegate.scrollOffset != scrollOffset;
  }
}

// Yıldız veri sınıfı
class Star {
  final double x, y;
  final double size;
  final bool isTwinkler;
  final bool isBright;
  final double movementAmplitude;
  final double movementSpeed;
  final double phase;
  final double layer; // Parallax için katman (0-1)

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.isTwinkler,
    required this.isBright,
    required this.movementAmplitude,
    required this.movementSpeed,
    required this.phase,
    required this.layer,
  });
}
