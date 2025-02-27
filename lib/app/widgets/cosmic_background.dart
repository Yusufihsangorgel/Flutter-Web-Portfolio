import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' show PointMode;
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/shared_background_controller.dart';

// Kozmik Arka Plan Widget'ı
class CosmicBackground extends StatelessWidget {
  final ScrollController? scrollController;
  final double pageHeight;
  final AnimationController? animationController;

  const CosmicBackground({
    Key? key,
    this.scrollController,
    this.pageHeight = 0,
    this.animationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Öncelikle parametre olarak geçilen controller'ı kullan, yoksa shared controller'ı kullan
    final animController =
        animationController ?? SharedBackgroundController.animationController;
    final mousePosition = SharedBackgroundController.mousePosition;

    if (animController == null) {
      return Container(color: Colors.black);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Uzay arka planı
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF000510), // En üst - neredeyse siyah
                    Color(0xFF00101F), // Koyu mavi-siyah
                  ],
                ),
              ),
            ),

            // Yıldızlar
            RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: StarFieldPainter(
                  animController: animController,
                  scrollOffset: scrollController?.offset ?? 0,
                ),
              ),
            ),

            // Gezegen
            Positioned(
              top: 100,
              right: 100,
              child: AnimatedBuilder(
                animation: animController,
                builder: (_, __) {
                  final planetPosition = Offset(
                    math.sin(animController.value * math.pi * 2) * 10,
                    math.cos(animController.value * math.pi * 2) * 10,
                  );

                  return Transform.translate(
                    offset: planetPosition,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1A237E), // Koyu mavi
                            Color(0xFF3949AB), // Mavi
                            Color(0xFF3F51B5), // Açık mavi
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3F51B5).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Kayan yıldızlar
            AnimatedBuilder(
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

            // Uzay roketi - Scroll pozisyonuna göre hareket eder
            if (scrollController != null && pageHeight > 0)
              AnimatedBuilder(
                animation: Listenable.merge([
                  animController,
                  scrollController!,
                ]),
                builder: (context, child) {
                  // Scroll pozisyonunu al (0.0 - 1.0 arasında normalize edilmiş)
                  final scrollProgress =
                      (scrollController!.hasClients)
                          ? (scrollController!.position.pixels /
                                  (pageHeight * 0.8))
                              .clamp(0.0, 1.0)
                          : 0.0;

                  // Roketin y pozisyonu (yukarıdan aşağıya doğru)
                  final rocketY = constraints.maxHeight * scrollProgress;

                  // Section'lar arasındaki geçiş için farklı rotalar hesapla
                  // section sayısına göre 5 eşit parçaya böl (0%, 20%, 40%, 60%, 80%, 100%)
                  final sectionCount = 5;
                  final sectionIndex = (scrollProgress * sectionCount).floor();
                  final sectionProgress =
                      (scrollProgress * sectionCount) - sectionIndex;

                  // Her section için farklı x pozisyonu ve dönüş açısı hesapla
                  double xPos = 0;
                  double angle = 0;

                  // Roketin her section için farklı rotalar izlemesi
                  switch (sectionIndex) {
                    case 0: // Home -> About geçişi
                      // Soldan sağa doğru eğimli rota
                      xPos =
                          constraints.maxWidth * (0.2 + sectionProgress * 0.6);
                      angle =
                          math.pi * 1.6 +
                          math.sin(sectionProgress * math.pi) * 0.3;
                      break;
                    case 1: // About -> Skills geçişi
                      // Sağdan sola S rota
                      xPos =
                          constraints.maxWidth * (0.8 - sectionProgress * 0.5);
                      angle =
                          math.pi * 1.4 +
                          math.cos(sectionProgress * math.pi) * 0.3;
                      break;
                    case 2: // Skills -> Projects geçişi
                      // Soldan ortaya doğru rota
                      xPos =
                          constraints.maxWidth * (0.3 + sectionProgress * 0.2);
                      angle =
                          math.pi * 1.5 +
                          math.sin(sectionProgress * math.pi * 2) * 0.2;
                      break;
                    case 3: // Projects -> Contact geçişi
                      // Ortadan sağa doğru ve tekrar sola
                      xPos =
                          constraints.maxWidth *
                          (0.5 + math.sin(sectionProgress * math.pi) * 0.3);
                      angle =
                          math.pi * 1.5 +
                          math.cos(sectionProgress * math.pi * 3) * 0.3;
                      break;
                    case 4: // Contact -> Footer geçişi
                      // Sağdan sola ve aşağı doğru
                      xPos =
                          constraints.maxWidth * (0.7 - sectionProgress * 0.4);
                      angle =
                          math.pi * 1.4 +
                          math.sin(sectionProgress * math.pi) * 0.2;
                      break;
                    default:
                      // Varsayılan rota
                      xPos = constraints.maxWidth * 0.5;
                      angle = math.pi * 1.5;
                  }

                  // Animasyon değerlerine göre küçük ekstra hareketler ekle
                  xPos += math.sin(animController.value * math.pi * 2) * 20;
                  angle += math.sin(animController.value * math.pi * 3) * 0.05;

                  return Positioned(
                    left: xPos,
                    top: 80 + rocketY,
                    child: Transform.rotate(
                      angle: angle,
                      child: _buildRocket(),
                    ),
                  );
                },
              )
            else
              // Sabit roket (scroll controller yoksa)
              Positioned(
                bottom: 50 + math.sin(animController.value * math.pi * 2) * 30,
                right: 100 + math.cos(animController.value * math.pi * 3) * 20,
                child: AnimatedBuilder(
                  animation: animController,
                  builder: (_, __) {
                    return Transform.rotate(
                      angle:
                          math.pi /
                          20 *
                          math.sin(animController.value * math.pi),
                      child: _buildRocket(),
                    );
                  },
                ),
              ),

            // Işık efektleri
            AnimatedBuilder(
              animation: animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: LightEffectPainter(
                    time: animController.value,
                    mousePosition: mousePosition.value,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Roket bileşeni
  Widget _buildRocket() {
    return Container(
      height: 80,
      width: 40,
      child: Stack(
        children: [
          // Roket gövdesi
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            bottom: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFEF5350), // Kırmızı
                    Color(0xFFF44336), // Koyu kırmızı
                  ],
                ),
              ),
            ),
          ),

          // Roket burnu
          Positioned(
            top: 0,
            left: 10,
            right: 10,
            child: Container(
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
            ),
          ),

          // Roket penceresi
          Positioned(
            top: 25,
            left: 15,
            child: Container(
              height: 15,
              width: 15,
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade200,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),

          // Roket kanatları
          Positioned(
            bottom: 10,
            left: 0,
            child: Container(
              height: 20,
              width: 15,
              decoration: const BoxDecoration(
                color: Color(0xFFD32F2F),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(5),
                  topRight: Radius.circular(10),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 0,
            child: Container(
              height: 20,
              width: 15,
              decoration: const BoxDecoration(
                color: Color(0xFFD32F2F),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(5),
                  topLeft: Radius.circular(10),
                ),
              ),
            ),
          ),

          // Roket ateşi
          Positioned(bottom: 0, left: 13, child: _buildRocketFire()),
        ],
      ),
    );
  }

  // Roket ateşi animasyonu
  Widget _buildRocketFire() {
    // Shared controller'dan animasyon controller'ı al
    final animController = SharedBackgroundController.animationController;

    if (animController == null) {
      return Container(height: 20, width: 14);
    }

    return AnimatedBuilder(
      animation: animController,
      builder: (context, child) {
        final size = 14.0 + math.sin(animController.value * math.pi * 10) * 4;
        return Container(
          height: 20 + math.sin(animController.value * math.pi * 8) * 5,
          width: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.orangeAccent, Colors.orange, Colors.deepOrange],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(size / 2),
              bottomRight: Radius.circular(size / 2),
            ),
          ),
        );
      },
    );
  }
}

// Yıldız Alanı Çizici
class StarFieldPainter extends CustomPainter {
  final AnimationController animController;
  final double scrollOffset;

  StarFieldPainter({required this.animController, this.scrollOffset = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(
      42,
    ); // Sabit tohum değeri kullanarak tutarlı yıldızlar oluştur
    final starCount = 300;

    // Yıldızları çiz
    for (int i = 0; i < starCount; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;

      // Yıldız boyutu ve parlaklığı
      double starSize = random.nextDouble() * 2 + 1;
      double brightness = random.nextDouble() * 0.8 + 0.2;

      // Animasyon - Yıldızları hafifçe hareket ettir
      double time = animController.value * math.pi * 2;
      x += math.sin(time + i) * 1.5;
      y += math.cos(time + i) * 1.5;

      // Scroll ile yıldızları kaydır - paralax efekti
      double parallaxFactor = random.nextDouble() * 0.5;
      y -= scrollOffset * parallaxFactor;

      // Ekran dışındaki yıldızları ekranın diğer tarafına taşı
      y = y % size.height;

      // Yıldızı çiz
      final paint =
          Paint()
            ..color = Colors.white.withOpacity(brightness)
            ..strokeWidth = starSize
            ..strokeCap = StrokeCap.round;

      canvas.drawPoints(PointMode.points, [Offset(x, y)], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Kayan yıldız çizici
class ShootingStarPainter extends CustomPainter {
  final double time;
  final Offset mousePosition;

  ShootingStarPainter({required this.time, required this.mousePosition});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);

    // Kayan yıldız sayısı
    final shootingStarsCount = 3;

    for (int i = 0; i < shootingStarsCount; i++) {
      // Yıldızın başlangıç noktası
      final startTime = (i * 0.3) % 1.0;
      final currentTime = (time + startTime) % 1.0;

      // Yıldızın aktif olup olmadığı
      if (currentTime > 0.05 && currentTime < 0.25) {
        // Yıldızın rotası
        final startX = random.nextDouble() * size.width * 0.8;
        final startY = random.nextDouble() * size.height * 0.5;
        final angle =
            math.pi / 4 +
            random.nextDouble() * math.pi / 4; // 45-90 derece arası

        // Yıldızın hareket mesafesi
        final progress =
            (currentTime - 0.05) / 0.2; // 0-1 arası normalize edilmiş ilerleme
        final distance =
            size.width * 0.3; // Ekran genişliğinin %30'u kadar mesafe

        // Yıldızın mevcut konumu
        final currentX = startX + math.cos(angle) * distance * progress;
        final currentY = startY + math.sin(angle) * distance * progress;

        // Kuyruk noktaları
        final tailLength = 30.0;
        final tailX = currentX - math.cos(angle) * tailLength * progress;
        final tailY = currentY - math.sin(angle) * tailLength * progress;

        // Kuyruk çizgisi
        final paint =
            Paint()
              ..color = Colors.white.withOpacity(0.8 * (1 - progress))
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round;

        canvas.drawLine(
          Offset(tailX, tailY),
          Offset(currentX, currentY),
          paint,
        );

        // Yıldız başı
        final headPaint =
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(currentX, currentY), 3.0, headPaint);
      }
    }
  }

  @override
  bool shouldRepaint(ShootingStarPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}

// Işık efekti çizici
class LightEffectPainter extends CustomPainter {
  final double time;
  final Offset mousePosition;

  LightEffectPainter({required this.time, required this.mousePosition});

  @override
  void paint(Canvas canvas, Size size) {
    // Fare pozisyonuna göre ışık efekti
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.4;

    // Işık gradyanı
    final gradient = RadialGradient(
      center: const Alignment(0.0, 0.0),
      radius: 1.0,
      colors: [
        const Color(0xFF4A148C).withOpacity(0.1), // Mor
        const Color(0xFF311B92).withOpacity(0.05), // Koyu mor
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    // Fare pozisyonuna göre ışık efekti
    final mouseOffset = Offset(
      (mousePosition.dx / size.width) * 2 - 1,
      (mousePosition.dy / size.height) * 2 - 1,
    );

    final lightPosition = Offset(
      center.dx + mouseOffset.dx * 100,
      center.dy + mouseOffset.dy * 100,
    );

    final rect = Rect.fromCircle(center: lightPosition, radius: radius);
    final paint = Paint()..shader = gradient.createShader(rect);

    canvas.drawCircle(lightPosition, radius, paint);
  }

  @override
  bool shouldRepaint(LightEffectPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.mousePosition != mousePosition;
  }
}
