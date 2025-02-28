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
            // Uzay arka planı - daha derin uzay görünümü
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF000510), // En üst - neredeyse siyah
                    Color(0xFF00101F), // Koyu mavi-siyah
                    Color(0xFF001429), // Biraz daha açık mavi-siyah
                  ],
                ),
              ),
            ),

            // Uzak galaksiler ve nebulalar
            CustomPaint(
              painter: DeepSpacePainter(time: animController.value),
              size: Size.infinite,
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

            // Ay - daha gerçekçi
            Positioned(
              top: 100,
              right: 100,
              child: AnimatedBuilder(
                animation: animController,
                builder: (_, __) {
                  final moonPosition = Offset(
                    math.sin(animController.value * math.pi * 2) * 10,
                    math.cos(animController.value * math.pi * 2) * 10,
                  );

                  return Transform.translate(
                    offset: moonPosition,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFE0E0E0), // Açık gri
                            Color(0xFFBDBDBD), // Gri
                            Color(0xFFAAAAAA), // Koyu gri
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      // Ay kraterleri
                      child: CustomPaint(
                        painter: MoonSurfacePainter(),
                        size: const Size(60, 60),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Kayan yıldızlar ve kuyruklu yıldızlar
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
                  double targetXPos = 0;
                  double targetAngle = 0;

                  // Roketin her section için farklı rotalar izlemesi
                  switch (sectionIndex) {
                    case 0: // Home -> About geçişi
                      // Soldan sağa doğru eğimli rota
                      targetXPos =
                          constraints.maxWidth * (0.2 + sectionProgress * 0.6);
                      targetAngle =
                          math.pi * 1.6 +
                          math.sin(sectionProgress * math.pi) * 0.3;
                      break;
                    case 1: // About -> Skills geçişi
                      // Sağdan sola S rota
                      targetXPos =
                          constraints.maxWidth * (0.8 - sectionProgress * 0.5);
                      targetAngle =
                          math.pi * 1.4 +
                          math.cos(sectionProgress * math.pi) * 0.3;
                      break;
                    case 2: // Skills -> Projects geçişi
                      // Soldan ortaya doğru rota
                      targetXPos =
                          constraints.maxWidth * (0.3 + sectionProgress * 0.2);
                      targetAngle =
                          math.pi * 1.5 +
                          math.sin(sectionProgress * math.pi * 2) * 0.2;
                      break;
                    case 3: // Projects -> Contact geçişi
                      // Ortadan sağa doğru ve tekrar sola
                      targetXPos =
                          constraints.maxWidth *
                          (0.5 + math.sin(sectionProgress * math.pi) * 0.3);
                      targetAngle =
                          math.pi * 1.5 +
                          math.cos(sectionProgress * math.pi * 3) * 0.3;
                      break;
                    case 4: // Contact -> Footer geçişi
                      // Sağdan sola ve aşağı doğru
                      targetXPos =
                          constraints.maxWidth * (0.7 - sectionProgress * 0.4);
                      targetAngle =
                          math.pi * 1.4 +
                          math.sin(sectionProgress * math.pi) * 0.2;
                      break;
                    default:
                      // Varsayılan rota
                      targetXPos = constraints.maxWidth * 0.5;
                      targetAngle = math.pi * 1.5;
                  }

                  // Animasyon değerlerine göre küçük ekstra hareketler ekle
                  targetXPos +=
                      math.sin(animController.value * math.pi * 2) * 20;
                  targetAngle +=
                      math.sin(animController.value * math.pi * 3) * 0.05;

                  // Son pozisyonu al veya hedef pozisyonu kullan
                  final lastXPos =
                      SharedBackgroundController.rocketX ?? targetXPos;

                  // Pozisyon değişimini sınırla - daha yumuşak hareket
                  final maxPositionChange =
                      3.0; // Maksimum 3 piksel hareket (scroll'da biraz daha hızlı)

                  // X pozisyonu için yumuşak geçiş
                  final xDiff = targetXPos - lastXPos;
                  final limitedXDiff = xDiff.clamp(
                    -maxPositionChange,
                    maxPositionChange,
                  );
                  final smoothXPos = lastXPos + limitedXDiff;

                  // Pozisyonu kaydet
                  SharedBackgroundController.rocketX = smoothXPos;
                  SharedBackgroundController.rocketY = 80 + rocketY;

                  // Yumuşak açı geçişleri için son açıyı kontrol et
                  final lastAngle =
                      SharedBackgroundController.rocketRotation ?? targetAngle;

                  // Açı değişimini sınırla
                  final maxAngleChange =
                      0.02; // Section geçişlerinde biraz daha hızlı olsun
                  final angleDiff = (targetAngle - lastAngle);

                  // Açı farkını normalize et
                  final normalizedDiff =
                      angleDiff > math.pi
                          ? angleDiff - 2 * math.pi
                          : (angleDiff < -math.pi
                              ? angleDiff + 2 * math.pi
                              : angleDiff);

                  // Sınırlı açı değişimi uygula
                  final limitedDiff = normalizedDiff.clamp(
                    -maxAngleChange,
                    maxAngleChange,
                  );
                  final smoothAngle = lastAngle + limitedDiff;

                  // Son açıyı güncelle
                  SharedBackgroundController.rocketRotation = smoothAngle;

                  return Positioned(
                    left: smoothXPos,
                    top: 80 + rocketY,
                    child: Transform.rotate(
                      angle: smoothAngle, // Yumuşatılmış açı kullan
                      child: _buildRocket(),
                    ),
                  );
                },
              )
            else
              // Rastgele yörüngede hareket eden roket
              AnimatedBuilder(
                animation: animController,
                builder: (context, child) {
                  // Rastgele yörünge için parametreler - DAHA YAVAŞ PARAMETRELER
                  final time = animController.value * math.pi * 2;

                  // Çok daha yavaş değişen parametreler - kesintisizlik için
                  // Eğer daha önce parametreler kaydedilmişse onları kullan, yoksa yeni oluştur
                  final a =
                      SharedBackgroundController.rocketParamA ??
                      (2.0 + math.sin(time * 0.05) * 0.3); // 2x daha yavaş
                  final b =
                      SharedBackgroundController.rocketParamB ??
                      (1.5 + math.cos(time * 0.03) * 0.2); // 2.7x daha yavaş

                  // Faz farkını neredeyse sabit tut (çok yavaş değişim) - ani yön değişimini önler
                  final delta =
                      SharedBackgroundController.rocketParamDelta ??
                      (math.pi / 4 +
                          math.sin(time * 0.02) *
                              0.05); // 2.5x daha yavaş ve daha az değişim

                  // Parametreleri kaydet
                  SharedBackgroundController.rocketParamA = a;
                  SharedBackgroundController.rocketParamB = b;
                  SharedBackgroundController.rocketParamDelta = delta;

                  // Ekranın merkezinden itibaren hareket
                  final centerX = constraints.maxWidth * 0.5;
                  final centerY = constraints.maxHeight * 0.5;

                  // Hareket yarıçapı - ekranın %25'i kadar (daha küçük yarıçap = daha az ani değişim)
                  final radiusX = constraints.maxWidth * 0.25;
                  final radiusY = constraints.maxHeight * 0.25;

                  // Lissajous eğrisi formülü
                  final targetX =
                      centerX + radiusX * math.sin(a * time + delta);
                  final targetY = centerY + radiusY * math.sin(b * time);

                  // Son pozisyonu al veya hedef pozisyonu kullan
                  final lastX = SharedBackgroundController.rocketX ?? targetX;
                  final lastY = SharedBackgroundController.rocketY ?? targetY;

                  // Pozisyon değişimini sınırla - çok yavaş hareket
                  final maxPositionChange = 2.0; // Maksimum 2 piksel hareket

                  // X pozisyonu için yumuşak geçiş
                  final xDiff = targetX - lastX;
                  final limitedXDiff = xDiff.clamp(
                    -maxPositionChange,
                    maxPositionChange,
                  );
                  final smoothX = lastX + limitedXDiff;

                  // Y pozisyonu için yumuşak geçiş
                  final yDiff = targetY - lastY;
                  final limitedYDiff = yDiff.clamp(
                    -maxPositionChange,
                    maxPositionChange,
                  );
                  final smoothY = lastY + limitedYDiff;

                  // Pozisyonları kaydet
                  SharedBackgroundController.rocketX = smoothX;
                  SharedBackgroundController.rocketY = smoothY;

                  // Roketin yönü hesaplaması için 10 kat daha küçük zaman adımı - çok daha yumuşak geçiş
                  final prevTime = time - 0.001; // 10x daha küçük adım
                  final prevX =
                      centerX + radiusX * math.sin(a * prevTime + delta);
                  final prevY = centerY + radiusY * math.sin(b * prevTime);

                  // Gerçek hareket vektörü kullanarak açıyı hesapla
                  final dx = smoothX - lastX;
                  final dy = smoothY - lastY;
                  final rawAngle = math.atan2(dy, dx) + math.pi / 2;

                  // Son açıyı sınıfın dışında sakla - statik değişken sorununu çöz
                  // Ortak kontrolcü aracılığıyla son açıyı tut
                  final lastAngle =
                      SharedBackgroundController.rocketRotation ?? rawAngle;

                  // Açı değişimini sınırla - her adımda max 0.01 radyan değişim olsun
                  final maxAngleChange = 0.01;
                  final angleDiff = (rawAngle - lastAngle);

                  // Açı farkını normalize et (-pi ve pi arasında olsun)
                  final normalizedDiff =
                      angleDiff > math.pi
                          ? angleDiff - 2 * math.pi
                          : (angleDiff < -math.pi
                              ? angleDiff + 2 * math.pi
                              : angleDiff);

                  // Sınırlı açı değişimi uygula
                  final limitedDiff = normalizedDiff.clamp(
                    -maxAngleChange,
                    maxAngleChange,
                  );
                  final smoothAngle = lastAngle + limitedDiff;

                  // Son açıyı güncelle
                  SharedBackgroundController.rocketRotation = smoothAngle;

                  // Küçük titreşimler ekle - daha doğal ama aşırı değil
                  final vibrationX =
                      math.sin(time * 8) * 0.8; // 2x daha az titreşim
                  final vibrationY =
                      math.cos(time * 9) * 0.5; // 2x daha az titreşim

                  return Positioned(
                    left: smoothX + vibrationX,
                    top: smoothY + vibrationY,
                    child: Transform.rotate(
                      angle: smoothAngle, // Yumuşatılmış açı kullan
                      child: _buildRocket(),
                    ),
                  );
                },
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
    // Shared controller'dan animasyon controller'ı al
    final animController = SharedBackgroundController.animationController;

    if (animController == null) {
      return Container(height: 80, width: 40);
    }

    return AnimatedBuilder(
      animation: animController,
      builder: (context, child) {
        // 3D efekti için perspektif açısı
        final perspectiveAngle = math.sin(animController.value * math.pi) * 0.1;

        // Işık açısı - zamanla değişen
        final lightAngle = animController.value * math.pi * 2;
        final lightX = math.cos(lightAngle) * 0.5;
        final lightY = math.sin(lightAngle) * 0.3;

        return Transform(
          transform:
              Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspektif efekti için
                ..rotateX(perspectiveAngle)
                ..rotateY(perspectiveAngle * 0.7),
          alignment: Alignment.center,
          child: Container(
            height: 100,
            width: 50,
            child: Stack(
              children: [
                // Roket gövdesi - metalik görünüm
                Positioned(
                  top: 20,
                  left: 10,
                  right: 10,
                  bottom: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment(lightX, lightY),
                        end: Alignment(-lightX, -lightY),
                        colors: const [
                          Color(0xFFE0E0E0), // Açık gri
                          Color(0xFF9E9E9E), // Gri
                          Color(0xFFBDBDBD), // Orta gri
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 5,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Roket detayları - çizgiler
                          Container(
                            height: 2,
                            margin: EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          Container(
                            height: 2,
                            margin: EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Roket burnu - metalik koni
                Positioned(
                  top: 0,
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 25,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment(lightX, lightY),
                        end: Alignment(-lightX, -lightY),
                        colors: const [
                          Color(0xFFE0E0E0), // Açık gri
                          Color(0xFFBDBDBD), // Orta gri
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 3,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    // Burun üzerinde parlak nokta
                    child: Align(
                      alignment: Alignment(lightX * 2, lightY * 2),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ),

                // Roket penceresi - parlak cam efekti
                Positioned(
                  top: 30,
                  left: 15,
                  child: Container(
                    height: 15,
                    width: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment(lightX, lightY),
                        end: Alignment(-lightX, -lightY),
                        colors: [
                          Colors.lightBlue.shade100,
                          Colors.lightBlue.shade300,
                        ],
                      ),
                      border: Border.all(color: Colors.white70, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.lightBlue.shade200.withOpacity(0.5),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    // Pencere üzerinde parlak nokta
                    child: Align(
                      alignment: Alignment(lightX, lightY),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                ),

                // Roket kanatları - sol
                Positioned(
                  bottom: 15,
                  left: 0,
                  child: Transform(
                    transform: Matrix4.identity()..rotateZ(-0.1),
                    alignment: Alignment.topRight,
                    child: Container(
                      height: 25,
                      width: 15,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(lightX, lightY),
                          end: Alignment(-lightX, -lightY),
                          colors: const [
                            Color(0xFFE53935), // Kırmızı
                            Color(0xFFB71C1C), // Koyu kırmızı
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(5),
                          topRight: Radius.circular(10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 3,
                            offset: Offset(-1, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Roket kanatları - sağ
                Positioned(
                  bottom: 15,
                  right: 0,
                  child: Transform(
                    transform: Matrix4.identity()..rotateZ(0.1),
                    alignment: Alignment.topLeft,
                    child: Container(
                      height: 25,
                      width: 15,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(lightX, lightY),
                          end: Alignment(-lightX, -lightY),
                          colors: const [
                            Color(0xFFE53935), // Kırmızı
                            Color(0xFFB71C1C), // Koyu kırmızı
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(5),
                          topLeft: Radius.circular(10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 3,
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Işık yansıması efekti
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomPaint(
                        painter: RocketLightReflectionPainter(
                          time: animController.value,
                          lightX: lightX,
                          lightY: lightY,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Yıldız Alanı Çizici - Yanıp sönen ve parlayan yıldızlar
class StarFieldPainter extends CustomPainter {
  final AnimationController animController;
  final double scrollOffset;

  StarFieldPainter({required this.animController, this.scrollOffset = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(
      42,
    ); // Sabit tohum değeri kullanarak tutarlı yıldızlar oluştur
    final starCount = 1000; // Daha da fazla yıldız

    // Yıldızları çiz
    for (int i = 0; i < starCount; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;

      // Yıldız boyutu - çeşitli boyutlar
      double starSize = random.nextDouble() * 2.0 + 0.5;

      // Yanıp sönen yıldızlar için zaman bazlı parlaklık
      double time = animController.value * math.pi * 2;
      double blinkFactor = 0.0;

      // Sadece her 8 yıldızdan biri yanıp sönsün (çoğu normal olsun)
      if (i % 8 == 0) {
        // Farklı hızlarda yanıp sönme
        double blinkSpeed = 3.0 + (i % 5) * 1.5;
        blinkFactor = (math.sin(time * blinkSpeed + i) + 1) / 2 * 0.7;
      }

      // Normal yıldızlar için daha sabit parlaklık
      double brightness = 0.0;
      if (blinkFactor > 0) {
        // Yanıp sönen yıldızlar
        brightness = 0.3 + blinkFactor;
      } else {
        // Normal yıldızlar - boyuta göre parlaklık
        brightness = 0.4 + (starSize / 3.0) * 0.4;

        // Bazı yıldızlar daha parlak olsun
        if (i % 6 == 0) {
          brightness += 0.2;
          starSize += 0.5;
        }
      }

      // Animasyon - Normal yıldızlar çok az hareket etsin
      double movement = (i % 8 == 0) ? 1.5 : 0.3;
      x += math.sin(time + i) * movement;
      y += math.cos(time + i) * movement;

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

      // Sadece parlak yıldızlar için parlaklık efekti
      if (brightness > 0.7) {
        final glowPaint =
            Paint()
              ..color = Colors.white.withOpacity(brightness * 0.3)
              ..strokeWidth = starSize * 3
              ..strokeCap = StrokeCap.round;

        canvas.drawPoints(PointMode.points, [Offset(x, y)], glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Kayan yıldız ve kuyruklu yıldız çizici
class ShootingStarPainter extends CustomPainter {
  final double time;
  final Offset mousePosition;

  ShootingStarPainter({required this.time, required this.mousePosition});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);

    // Kayan yıldız sayısı
    final shootingStarsCount = 8; // Daha fazla kayan yıldız

    // Kuyruklu yıldız sayısı - nadir
    final cometCount = 1;

    // Kayan yıldızlar
    for (int i = 0; i < shootingStarsCount; i++) {
      // Her yıldız için farklı başlangıç zamanı
      final startTime = (i * (1.0 / shootingStarsCount)) % 1.0;
      final currentCycle = (time + startTime) % 1.0;

      // Ekranın farklı bölgelerinde kayan yıldızlar olsun
      final startX =
          (i * size.width / shootingStarsCount +
              size.width * 0.1 * math.sin(i)) %
          size.width;
      final startY =
          (i * size.height / shootingStarsCount +
              size.height * 0.1 * math.cos(i)) %
          size.height;
      final angle = math.pi / 4 + (i * math.pi / 8) % math.pi; // Farklı açılar

      // Yıldızın hareket mesafesi ve ilerleme
      final distance = size.width * 0.15; // Daha kısa mesafe
      final progress = currentCycle;

      // Yıldızın mevcut konumu - döngüsel hareket
      final currentX = startX + math.cos(angle) * distance * progress;
      final currentY = startY + math.sin(angle) * distance * progress;

      // Kuyruk noktaları
      final tailLength = 15.0 + random.nextDouble() * 15.0; // Daha kısa kuyruk
      final tailX = currentX - math.cos(angle) * tailLength * progress;
      final tailY = currentY - math.sin(angle) * tailLength * progress;

      // Görünürlüğü kademeli olarak değiştir - kademeli solma
      final opacity = math.sin(progress * math.pi) * 0.8;

      if (opacity > 0.1) {
        // Çok soluk olanları çizme
        // Kuyruk çizgisi - daha parlak ve daha kalın
        final paint =
            Paint()
              ..color = Colors.white.withOpacity(opacity)
              ..strokeWidth = 1.8
              ..strokeCap = StrokeCap.round;

        canvas.drawLine(
          Offset(tailX, tailY),
          Offset(currentX, currentY),
          paint,
        );

        // Yıldız başı
        final headPaint =
            Paint()
              ..color = Colors.white.withOpacity(opacity + 0.2)
              ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(currentX, currentY), 2.5, headPaint);

        // Parlaklık efekti
        final glowPaint =
            Paint()
              ..color = Colors.white.withOpacity(opacity * 0.4)
              ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(currentX, currentY), 3.5, glowPaint);
      }
    }

    // Kuyruklu yıldız - daha gerçekçi
    final cometTime = (time * 0.1) % 1.0;
    // Kuyruklu yıldız için sürekli yörünge - her zaman görünsün
    {
      // Kuyruklu yıldız hareketini sürekli hale getir
      final progress = cometTime;
      final startX = size.width * 0.9;
      final startY = size.height * 0.3;
      final angle = math.pi / 3.5; // Daha yatay açı

      // Tam bir döngü için hesaplama
      final orbitX = math.cos(time * 0.2) * size.width * 0.4;
      final orbitY = math.sin(time * 0.15) * size.height * 0.3;

      // Kuyruklu yıldızın mevcut konumu - yumuşak yörünge
      final currentX = startX + orbitX;
      final currentY = startY + orbitY;

      // Hareket yönünü tespit et
      final prevTime = time - 0.01;
      final prevOrbitX = math.cos((prevTime) * 0.2) * size.width * 0.4;
      final prevOrbitY = math.sin((prevTime) * 0.15) * size.height * 0.3;
      final prevX = startX + prevOrbitX;
      final prevY = startY + prevOrbitY;

      // Hareket yönünü kullanarak kuyruğu doğru yönde çiz
      final dx = currentX - prevX;
      final dy = currentY - prevY;
      final moveAngle = math.atan2(dy, dx);

      // Hareket yönüne göre dönüş açısı
      final rotateAngle = moveAngle + math.pi / 2;

      // Hareket vektörünü kullanarak kuyruğu çiz
      final path = Path();
      path.moveTo(prevX, prevY);
      path.quadraticBezierTo(
        prevX + 0.5 * math.cos(moveAngle) * 20,
        prevY + 0.5 * math.sin(moveAngle) * 20,
        currentX,
        currentY,
      );

      // Kuyruk gradyanı - daha gerçekçi renk geçişi
      final gradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white,
          Colors.white.withOpacity(0.9),
          Colors.white.withOpacity(0.7),
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.2),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.1, 0.3, 0.5, 0.8, 1.0],
      ).createShader(
        Rect.fromPoints(Offset(prevX, prevY), Offset(currentX, currentY)),
      );

      // Kuyruk çizimi
      final paint =
          Paint()
            ..shader = gradient
            ..style = PaintingStyle.fill
            ..blendMode = BlendMode.screen;

      canvas.drawPath(path, paint);

      // Kuyruklu yıldız başı - daha parlak ve gerçekçi
      final headPaint =
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(currentX, currentY), 6.0, headPaint);

      // Parlaklık efekti - daha güçlü parlama
      final glowPaint =
          Paint()
            ..color = Colors.white.withOpacity(0.5)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(currentX, currentY), 10.0, glowPaint);
    }
  }

  @override
  bool shouldRepaint(ShootingStarPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}

// Ay yüzeyi çizici
class MoonSurfacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);

    // Krater sayısı
    final craterCount = 15;

    for (int i = 0; i < craterCount; i++) {
      // Krater pozisyonu
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      // Krater boyutu
      final craterSize = 2.0 + random.nextDouble() * 5.0;

      // Krater rengi - gölgeli
      final paint =
          Paint()
            ..color = const Color(0xFF9E9E9E).withOpacity(0.5)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), craterSize, paint);

      // Krater kenarı - hafif yükseltili
      final borderPaint =
          Paint()
            ..color = const Color(0xFFE0E0E0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;

      canvas.drawCircle(Offset(x, y), craterSize, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Uzak galaksiler ve nebulalar çizici
class DeepSpacePainter extends CustomPainter {
  final double time;

  DeepSpacePainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);

    // Nebula sayısı
    final nebulaCount = 3;

    for (int i = 0; i < nebulaCount; i++) {
      // Nebula pozisyonu
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.7;

      // Nebula boyutu
      final nebulaSize = 50.0 + random.nextDouble() * 100.0;

      // Nebula renkleri - mor, mavi, pembe tonları
      final colors = [
        const Color(0xFF9C27B0).withOpacity(0.05),
        const Color(0xFF3F51B5).withOpacity(0.03),
        const Color(0xFFE91E63).withOpacity(0.02),
        Colors.transparent,
      ];

      // Nebula gradyanı
      final gradient = RadialGradient(
        center: Alignment(
          random.nextDouble() * 0.4 - 0.2,
          random.nextDouble() * 0.4 - 0.2,
        ),
        radius: 1.0,
        colors: colors,
        stops: [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: nebulaSize));

      // Nebula çizimi
      final paint =
          Paint()
            ..shader = gradient
            ..style = PaintingStyle.fill
            ..blendMode = BlendMode.screen;

      // Hafif animasyon
      final animOffset = math.sin(time * math.pi * 2 + i) * 5;

      canvas.drawCircle(Offset(x + animOffset, y), nebulaSize, paint);
    }
  }

  @override
  bool shouldRepaint(DeepSpacePainter oldDelegate) {
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
    // Mouse etrafında lokalize bir ışık efekti
    if (mousePosition.dx > 0 && mousePosition.dy > 0) {
      final lightRadius = 150.0;

      // Doğrudan fare pozisyonunu kullan, hesaplama yapma
      final lightPosition = mousePosition;

      // Işık gradyanı - daha subtle
      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.white.withOpacity(0.07),
          Colors.blue.withOpacity(0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(center: lightPosition, radius: lightRadius),
      );

      final paint = Paint()..shader = gradient;
      canvas.drawCircle(lightPosition, lightRadius, paint);
    }
  }

  @override
  bool shouldRepaint(LightEffectPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.mousePosition != mousePosition;
  }
}

// Roket üzerindeki ışık yansıması efekti
class RocketLightReflectionPainter extends CustomPainter {
  final double time;
  final double lightX;
  final double lightY;

  RocketLightReflectionPainter({
    required this.time,
    required this.lightX,
    required this.lightY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Işık yansıması için gradient
    final gradient = LinearGradient(
      begin: Alignment(lightX, lightY),
      end: Alignment(-lightX, -lightY),
      colors: [Colors.white.withOpacity(0.3), Colors.transparent],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Yansıma şekli
    final path =
        Path()
          ..moveTo(size.width * 0.5, 0)
          ..lineTo(size.width * 0.7, size.height * 0.3)
          ..lineTo(size.width * 0.6, size.height * 0.7)
          ..lineTo(size.width * 0.4, size.height * 0.7)
          ..lineTo(size.width * 0.3, size.height * 0.3)
          ..close();

    // Yansıma çizimi
    final paint =
        Paint()
          ..shader = gradient
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.screen;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(RocketLightReflectionPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.lightX != lightX ||
        oldDelegate.lightY != lightY;
  }
}

// Alev dalgalanma efekti çizici
class FlameWavePainter extends CustomPainter {
  final double time;
  final double flameWidth;
  final double flameHeight;

  FlameWavePainter({
    required this.time,
    required this.flameWidth,
    required this.flameHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    // Alevin dalgalı kenarları için
    final waveCount = 8; // Daha fazla dalga
    final amplitude = flameWidth * 0.3; // Daha belirgin dalgalar

    // Başlangıç noktası
    path.moveTo(0, 0);

    // Sol kenar - dalgalı
    for (int i = 0; i < waveCount; i++) {
      final y = i * (flameHeight / waveCount);
      final nextY = (i + 1) * (flameHeight / waveCount);
      final controlY = (y + nextY) / 2;

      // Zaman ile değişen dalga - çoklu frekans daha gerçekçi görünüm
      final waveOffset =
          math.sin(time * math.pi * 8 + i * 0.8) * amplitude * 0.7 +
          math.sin(time * math.pi * 15 + i * 1.5) * amplitude * 0.3;

      // Bezier eğrisi ile dalgalı kenar
      path.quadraticBezierTo(waveOffset.toDouble(), controlY, 0, nextY);
    }

    // Alt kenar
    path.lineTo(flameWidth, flameHeight);

    // Sağ kenar - dalgalı
    for (int i = waveCount - 1; i >= 0; i--) {
      final y = i * (flameHeight / waveCount);
      final nextY = (i > 0) ? (i - 1) * (flameHeight / waveCount) : 0;
      final controlY = (y + nextY) / 2;

      // Zaman ile değişen dalga - sol kenardan farklı faz
      final waveOffset =
          math.sin(time * math.pi * 8 + i + math.pi) * amplitude * 0.7 +
          math.sin(time * math.pi * 18 + i * 1.2 + math.pi / 2) *
              amplitude *
              0.3;

      // Bezier eğrisi ile dalgalı kenar
      path.quadraticBezierTo(
        (flameWidth + waveOffset).toDouble(),
        controlY,
        flameWidth.toDouble(),
        nextY.toDouble(),
      );
    }

    path.close();

    // Alev gradyanı - daha parlak ve çeşitli renkler
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withOpacity(0.8),
        Colors.yellow.withOpacity(0.7),
        Colors.amber.withOpacity(0.6),
        Colors.orange.withOpacity(0.4),
        Colors.deepOrange.withOpacity(0.2),
        Colors.transparent,
      ],
      stops: const [0.0, 0.15, 0.3, 0.5, 0.7, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, flameWidth, flameHeight));

    // Alev çizimi
    final paint =
        Paint()
          ..shader = gradient
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.screen;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(FlameWavePainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.flameWidth != flameWidth ||
        oldDelegate.flameHeight != flameHeight;
  }
}
