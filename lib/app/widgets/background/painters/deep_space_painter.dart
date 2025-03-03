import 'dart:math' as math;
import 'package:flutter/material.dart';

// Uzak galaksiler ve nebulalar çizici - sonsuz hareket
class DeepSpacePainter extends CustomPainter {
  final double time;

  // Nebula objelerini statik tut - sürekli yeniden oluşturulmasın
  static List<Nebula>? _cachedNebulas;
  static final _random = math.Random(42);

  DeepSpacePainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    // Nebula'ları ilk kez oluştur veya ekran boyutu değiştiyse yeniden oluştur
    if (_cachedNebulas == null) {
      _initializeNebulas(size);
    }

    // Gerçek zamanı saniyelerle hesapla - çok daha yavaş hareket için
    final realTime = time * 10000; // ~3 saatlik çok yavaş döngü

    // Her bir nebulayı çiz
    _drawNebulas(canvas, size, realTime);
  }

  // Nebula objelerini başlangıçta oluştur
  void _initializeNebulas(Size size) {
    // Daha küçük ve daha az belirgin nebulalar - büyük şeffaf daireler yerine
    const nebulaCount = 3;
    _cachedNebulas = List.generate(nebulaCount, (i) {
      // Rastgele özellikler
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height * 0.8;

      // Daha küçük boyutlar - çok daha küçük
      final nebulaSize =
          30.0 + _random.nextDouble() * 40.0; // Boyutları küçülttük

      // Daha düşük opaklık değerleri - çok daha az belirgin
      List<Color> colors;
      final colorType = _random.nextInt(3);

      switch (colorType) {
        case 0: // Mor/mavi nebula
          colors = [
            const Color(0xFF9C27B0).withOpacity(0.01), // Opaklığı azalttık
            const Color(0xFF3F51B5).withOpacity(0.008), // Opaklığı azalttık
            const Color(0xFF673AB7).withOpacity(0.005), // Opaklığı azalttık
            Colors.transparent,
          ];
          break;
        case 1: // Pembe/kırmızı nebula
          colors = [
            const Color(0xFFE91E63).withOpacity(0.01), // Opaklığı azalttık
            const Color(0xFFF44336).withOpacity(0.008), // Opaklığı azalttık
            const Color(0xFFFF9800).withOpacity(0.005), // Opaklığı azalttık
            Colors.transparent,
          ];
          break;
        default: // Turkuaz/yeşil nebula
          colors = [
            const Color(0xFF009688).withOpacity(0.01), // Opaklığı azalttık
            const Color(0xFF4CAF50).withOpacity(0.008), // Opaklığı azalttık
            const Color(0xFF00BCD4).withOpacity(0.005), // Opaklığı azalttık
            Colors.transparent,
          ];
      }

      // Hareket parametreleri - çok yavaş hareket
      final movementSpeed = 0.00002 + _random.nextDouble() * 0.00005;
      final movementAmplitude = 15.0 + _random.nextDouble() * 10.0;

      // İç hareket parametreleri - nebula içindeki dalgalanma
      final innerSpeed = 0.0001 + _random.nextDouble() * 0.0002;
      final innerAmplitude = 0.05 + _random.nextDouble() * 0.1;

      // Faz farklılığı - aynı anda hareket etmesinler
      final phase = _random.nextDouble() * math.pi * 2;

      return Nebula(
        x: x,
        y: y,
        size: nebulaSize,
        colors: colors,
        movementSpeed: movementSpeed,
        movementAmplitude: movementAmplitude,
        innerSpeed: innerSpeed,
        innerAmplitude: innerAmplitude,
        phase: phase,
      );
    });

    // Daha küçük arka plan galaxiler - daha uzak hissi vermek için çok daha soluk ve sabit
    _cachedNebulas!.addAll(
      List.generate(12, (i) {
        // Sayıyı artırdık, daha fazla küçük galaksi
        final x = _random.nextDouble() * size.width;
        final y = _random.nextDouble() * size.height * 0.9;

        // Daha küçük boyutlar - çok daha küçük
        final nebulaSize =
            10.0 + _random.nextDouble() * 20.0; // Boyutları küçülttük

        // Çok daha soluk renkler - uzakta gibi
        final colors = [
          Colors.white.withOpacity(0.008), // Opaklığı azalttık
          Colors.white.withOpacity(0.005), // Opaklığı azalttık
          Colors.transparent,
        ];

        // Daha yavaş hareket - daha uzakta gibi
        final movementSpeed = 0.00001 + _random.nextDouble() * 0.00002;
        final movementAmplitude = 3.0 + _random.nextDouble() * 5.0;

        // Daha az iç hareketlilik
        final innerSpeed = 0.00005 + _random.nextDouble() * 0.0001;
        final innerAmplitude = 0.02 + _random.nextDouble() * 0.05;

        // Faz farklılığı
        final phase = _random.nextDouble() * math.pi * 2;

        return Nebula(
          x: x,
          y: y,
          size: nebulaSize,
          colors: colors,
          movementSpeed: movementSpeed,
          movementAmplitude: movementAmplitude,
          innerSpeed: innerSpeed,
          innerAmplitude: innerAmplitude,
          phase: phase,
          isDistant: true,
        );
      }),
    );
  }

  // Tüm nebulaları çiz
  void _drawNebulas(Canvas canvas, Size size, double time) {
    if (_cachedNebulas == null) return;

    for (var nebula in _cachedNebulas!) {
      // Zamanla çok yavaş hareket
      final xOffset =
          math.sin(time * nebula.movementSpeed + nebula.phase) *
          nebula.movementAmplitude;
      final yOffset =
          math.cos(time * nebula.movementSpeed * 0.7 + nebula.phase) *
          nebula.movementAmplitude *
          0.5;

      // Çizim pozisyonu
      final x = nebula.x + xOffset;
      final y = nebula.y + yOffset;

      // İç şekil değişimi - nebula merkezinin zamanla hafifçe kayması
      final centerOffsetX =
          math.sin(time * nebula.innerSpeed + nebula.phase) *
          nebula.innerAmplitude;
      final centerOffsetY =
          math.cos(time * nebula.innerSpeed * 1.1 + nebula.phase) *
          nebula.innerAmplitude;

      // Dalgalı kenarlar için yarıçap modülasyonu
      final radiusModulation =
          1.0 + math.sin(time * nebula.innerSpeed * 0.5) * 0.05;

      // Nebula gradyantı
      final gradient = RadialGradient(
        center: Alignment(centerOffsetX, centerOffsetY),
        radius: radiusModulation,
        colors: nebula.colors,
        stops:
            nebula.isDistant
                ? [0.0, 0.5, 1.0] // Uzak nebulalar için daha basit degrade
                : [
                  0.0,
                  0.3,
                  0.6,
                  1.0,
                ], // Ana nebulalar için daha zengin degrade
      ).createShader(
        Rect.fromCircle(center: Offset(x, y), radius: nebula.size),
      );

      // Nebula çizimi
      final paint =
          Paint()
            ..shader = gradient
            ..style = PaintingStyle.fill
            ..blendMode = BlendMode.screen;

      canvas.drawCircle(Offset(x, y), nebula.size, paint);

      // Parlak noktaları kaldırdık - şeffaf baloncukları önlemek için
    }
  }

  @override
  bool shouldRepaint(DeepSpacePainter oldDelegate) {
    return oldDelegate.time != time;
  }
}

// Nebula veri sınıfı
class Nebula {
  final double x, y;
  final double size;
  final List<Color> colors;
  final double movementSpeed;
  final double movementAmplitude;
  final double innerSpeed;
  final double innerAmplitude;
  final double phase;
  final bool isDistant;

  Nebula({
    required this.x,
    required this.y,
    required this.size,
    required this.colors,
    required this.movementSpeed,
    required this.movementAmplitude,
    required this.innerSpeed,
    required this.innerAmplitude,
    required this.phase,
    this.isDistant = false,
  });
}
