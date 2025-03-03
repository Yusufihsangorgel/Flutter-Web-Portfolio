import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui' show PointMode;
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/shared_background_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Painter sınıflarını import et
import 'painters/star_field_painter.dart';
import 'painters/shooting_star_painter.dart';
import 'painters/deep_space_painter.dart';
import 'painters/moon_surface_painter.dart';

// Widget'ları import et
import 'widgets/rocket_widget.dart';

// Kozmik Arka Plan Widget'ı
class CosmicBackground extends StatefulWidget {
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

    // Başlangıç değerlerini ayarla
    rocketPosition = Offset(0, 0); // Başlangıçta ekranın ortasında olacak
    rocketVelocity = Offset(
      0.6 +
          math.Random().nextDouble() *
              1.2, // 1.0+Random*2.0 yerine 0.6+Random*1.2, daha düşük başlangıç hızı
      0.3 +
          math.Random().nextDouble() *
              1.0, // 0.5+Random*2.0 yerine 0.3+Random*1.0, daha düşük başlangıç hızı
    ); // Rastgele başlangıç hızı, minimum hız garantili
    rocketRotation =
        math.pi / 2; // -math.pi/2 yerine math.pi/2, doğru başlangıç yönü

    // Her frame'de roketi hareket ettir
    rocketTimer = Timer.periodic(Duration(milliseconds: 20), (timer) {
      // 16ms yerine 20ms, %25 daha yavaş
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

    // Kenar güvenlik sınırları - daha fazla kullanılabilir alan için daraltıldı
    final minX = size.width * 0.05; // %2'den %5'e arttırıldı
    final maxX = size.width * 0.95; // %98'den %95'e azaltıldı
    final minY = size.height * 0.05; // %2'den %5'e arttırıldı
    final maxY = size.height * 0.95; // %98'den %95'e azaltıldı

    // -------------------- PROFESYONEL UZAY FİZİĞİ ALGORİTMASI ---------------------

    // Fizik zaman adımı (saniyenin 60'da biri) - daha yavaş hareket için azaltıldı
    final dt = 1.0 / 90.0; // 60'dan 90'a çıkarıldı, %33 daha yavaş

    // Çoklu çekim merkezleri - daha karmaşık hareket sağlar
    final List<Offset> attractors = [
      Offset(size.width * 0.2, size.height * 0.2), // Sol üst
      Offset(size.width * 0.8, size.height * 0.2), // Sağ üst
      Offset(size.width * 0.5, size.height * 0.5), // Merkez
      Offset(size.width * 0.2, size.height * 0.8), // Sol alt
      Offset(size.width * 0.8, size.height * 0.8), // Sağ alt
    ];

    final List<double> attractorMasses = [
      0.5, // Sol üst - 0.8'den 0.5'e azaltıldı
      0.5, // Sağ üst - 0.8'den 0.5'e azaltıldı
      0.8, // Merkez - 1.2'den 0.8'e azaltıldı
      0.5, // Sol alt - 0.8'den 0.5'e azaltıldı
      0.5, // Sağ alt - 0.8'den 0.5'e azaltıldı
    ];

    // Roketin yeni hız vektörünü hesapla (tüm çekim alanlarının toplam etkisi)
    Offset acceleration = Offset.zero;

    // Periyodik zaman faktörü - yörüngelerin zaman içinde değişmesini sağlar
    final time =
        DateTime.now().millisecondsSinceEpoch /
        15000; // 10000'den 15000'e çıkarıldı, daha yavaş değişim
    final timeFactor =
        math.sin(time) * 0.15 +
        0.85; // 0.2 ve 0.8 yerine 0.15 ve 0.85, daha az dalgalanma

    // Her bir çekim merkezinin etkisini hesapla
    for (int i = 0; i < attractors.length; i++) {
      final attractorPos = attractors[i];
      final mass = attractorMasses[i] * timeFactor;

      // Roket ile çekim merkezi arasındaki mesafe
      final dx = attractorPos.dx - rocketPosition.dx;
      final dy = attractorPos.dy - rocketPosition.dy;
      final distanceSquared = dx * dx + dy * dy;
      final distance = math.sqrt(distanceSquared);

      // Sıfıra bölme kontrolü - minimum mesafeyi 5.0'dan 10.0'a çıkardık
      if (distance > 10.0) {
        // Newton'un evrensel çekim yasası: F = G*m1*m2/r²
        // Burada G ve m1 sabit kabul edilerek basitleştirildi
        final forceMagnitude =
            mass /
            distanceSquared *
            6.0; // 10.0'dan 6.0'ya azaltıldı, daha az kuvvet

        // Çekim yönünü hesapla ve kuvveti uygula
        final forceX = dx / distance * forceMagnitude;
        final forceY = dy / distance * forceMagnitude;

        // Toplam ivmeye ekle
        acceleration += Offset(forceX, forceY);
      }
    }

    // Kaotik yörünge bileşeni - hafif periyodik davranış ekler, azaltıldı
    final chaosX =
        math.sin(rocketPosition.dx / 70 + time) *
        0.02; // 50 ve 0.03 yerine 70 ve 0.02
    final chaosY =
        math.cos(rocketPosition.dy / 70 + time * 1.3) *
        0.02; // 50 ve 0.03 yerine 70 ve 0.02
    acceleration += Offset(chaosX, chaosY);

    // İvmeyi hıza uygula - daha az etki
    rocketVelocity +=
        acceleration * dt * 1.5; // 2.0 yerine 1.5, daha az hızlanma

    // Hız sınırlaması uygulanıyor
    final speed = math.sqrt(
      rocketVelocity.dx * rocketVelocity.dx +
          rocketVelocity.dy * rocketVelocity.dy,
    );

    // Minimum ve maksimum hız sınırları - düşürüldü
    if (speed > 0.0) {
      if (speed < 0.8) {
        // Minimum hız sınırı - 1.0'dan 0.8'e düşürüldü
        rocketVelocity = rocketVelocity * (0.8 / speed);
      } else if (speed > 2.5) {
        // Maksimum hız sınırı - 4.0'dan 2.5'e düşürüldü
        rocketVelocity = rocketVelocity * (2.5 / speed);
      }
    } else {
      // Sıfır hızı önlemek için rastgele yön
      final angle = math.Random().nextDouble() * 2 * math.pi;
      rocketVelocity =
          Offset(math.cos(angle), math.sin(angle)) *
          0.8; // 0.8 çarpanı eklendi, daha düşük başlangıç hızı
    }

    // Hızı pozisyona uygula
    Offset newPosition = rocketPosition + rocketVelocity * dt * 60;

    // Daha yumuşak sınır yaklaşım kontrolü - köşelerde daha doğal davranış için
    final edgeProximity = 20.0; // Kenardan bu kadar uzaklıkta yavaşlamaya başla
    final slowdownFactor = 0.95; // Yavaşlama faktörü

    // Kenar yaklaşımında yavaşlama ve daha yumuşak dönüş
    if (newPosition.dx < minX + edgeProximity) {
      // Sol kenara yaklaşıyorsa, yavaşla ve dönüşe hazırlan
      if (rocketVelocity.dx < 0) {
        rocketVelocity = Offset(
          rocketVelocity.dx * slowdownFactor,
          rocketVelocity.dy,
        );
      }
    } else if (newPosition.dx > maxX - edgeProximity) {
      // Sağ kenara yaklaşıyorsa, yavaşla ve dönüşe hazırlan
      if (rocketVelocity.dx > 0) {
        rocketVelocity = Offset(
          rocketVelocity.dx * slowdownFactor,
          rocketVelocity.dy,
        );
      }
    }

    if (newPosition.dy < minY + edgeProximity) {
      // Üst kenara yaklaşıyorsa, yavaşla ve dönüşe hazırlan
      if (rocketVelocity.dy < 0) {
        rocketVelocity = Offset(
          rocketVelocity.dx,
          rocketVelocity.dy * slowdownFactor,
        );
      }
    } else if (newPosition.dy > maxY - edgeProximity) {
      // Alt kenara yaklaşıyorsa, yavaşla ve dönüşe hazırlan
      if (rocketVelocity.dy > 0) {
        rocketVelocity = Offset(
          rocketVelocity.dx,
          rocketVelocity.dy * slowdownFactor,
        );
      }
    }

    // Sınır kontrolleri - daha gerçekçi yansıma sağlar
    if (newPosition.dx < minX) {
      newPosition = Offset(
        minX + 2.0,
        newPosition.dy,
      ); // 2 piksel içeri çek, yapışmayı önle
      // Daha yumuşak ve gerçekçi yansıma, mevcut hıza bağlı daha doğal yansıma açısı
      final vx = -rocketVelocity.dx * 0.8; // %20 enerji kaybı
      final vy = rocketVelocity.dy * 0.95; // Y hızında da hafif azalma
      rocketVelocity = Offset(vx, vy);
    } else if (newPosition.dx > maxX) {
      newPosition = Offset(
        maxX - 2.0,
        newPosition.dy,
      ); // 2 piksel içeri çek, yapışmayı önle
      // Daha yumuşak ve gerçekçi yansıma, mevcut hıza bağlı daha doğal yansıma açısı
      final vx = -rocketVelocity.dx * 0.8; // %20 enerji kaybı
      final vy = rocketVelocity.dy * 0.95; // Y hızında da hafif azalma
      rocketVelocity = Offset(vx, vy);
    }

    if (newPosition.dy < minY) {
      newPosition = Offset(
        newPosition.dx,
        minY + 2.0,
      ); // 2 piksel içeri çek, yapışmayı önle
      // Daha yumuşak ve gerçekçi yansıma, mevcut hıza bağlı daha doğal yansıma açısı
      final vx = rocketVelocity.dx * 0.95; // X hızında hafif azalma
      final vy = -rocketVelocity.dy * 0.8; // %20 enerji kaybı
      rocketVelocity = Offset(vx, vy);
    } else if (newPosition.dy > maxY) {
      newPosition = Offset(
        newPosition.dx,
        maxY - 2.0,
      ); // 2 piksel içeri çek, yapışmayı önle
      // Daha yumuşak ve gerçekçi yansıma, mevcut hıza bağlı daha doğal yansıma açısı
      final vx = rocketVelocity.dx * 0.95; // X hızında hafif azalma
      final vy = -rocketVelocity.dy * 0.8; // %20 enerji kaybı
      rocketVelocity = Offset(vx, vy);
    }

    // Pozisyonu güncelle
    rocketPosition = newPosition;

    // Rotasyon hesaplama ve NaN kontrolü
    double targetRotation;
    if (rocketVelocity.dx != 0 || rocketVelocity.dy != 0) {
      // Rotasyon açısını uçuş yönüne göre ayarla, ters uçmayı düzelt
      targetRotation =
          math.atan2(rocketVelocity.dy, rocketVelocity.dx) + math.pi / 2;
      // Not: Önceki rotasyon math.atan2(rocketVelocity.dy, rocketVelocity.dx) - math.pi / 2 idi
      // math.pi/2 ekleyerek (çıkarma yerine) roketin yönünü düzeltiyoruz
    } else {
      targetRotation = rocketRotation;
    }

    // NaN kontrolü
    if (targetRotation.isNaN) {
      targetRotation =
          math.pi / 2; // -math.pi/2 yerine math.pi/2, doğru yönlendirme
    }

    // Yumuşak dönüş - Daha akıcı hareket için, daha yavaş
    rocketRotation = _smoothAngle(
      rocketRotation,
      targetRotation,
      0.05,
    ); // 0.1 yerine 0.05, daha yavaş dönüş

    // SharedBackgroundController'ı da güncelle
    SharedBackgroundController.rocketX = rocketPosition.dx;
    SharedBackgroundController.rocketY = rocketPosition.dy;
    SharedBackgroundController.rocketRotation = rocketRotation;
  }

  @override
  Widget build(BuildContext context) {
    // Öncelikle parametre olarak geçilen controller'ı kullan, yoksa shared controller'ı kullan
    final animController =
        widget.animationController ??
        SharedBackgroundController.animationController;
    final mousePosition = SharedBackgroundController.mousePosition;

    if (animController == null) {
      return Container(color: Colors.black);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // İlk kez oluşturulduğunda merkeze yerleştir
        if (rocketPosition == Offset(0, 0)) {
          rocketPosition = Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2,
          );
        }

        return MouseRegion(
          onHover: (event) {
            // Fare pozisyonunu doğrudan MouseRegion'dan al
            SharedBackgroundController.updateMousePosition(event.localPosition);
          },
          child: Stack(
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

              // Uzak galaksiler ve nebulalar - RepaintBoundary ile optimize ediyoruz
              RepaintBoundary(
                child: CustomPaint(
                  painter: DeepSpacePainter(time: animController.value),
                  size: Size.infinite,
                ),
              ),

              // Yıldızlar - RepaintBoundary ile optimize ediyoruz
              RepaintBoundary(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: StarFieldPainter(
                    animController: animController,
                    scrollOffset: widget.scrollController?.offset ?? 0,
                  ),
                ),
              ),

              // Ay - daha gerçekçi ve çok daha yavaş hareket
              _buildMoon(animController),

              // Kayan yıldızlar ve kuyruklu yıldızlar - RepaintBoundary ile optimize ediyoruz
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

              // Uzay roketi - Scroll pozisyonuna göre hareket eder veya serbest hareket eder
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

  // Ay widget'ı - daha gerçekçi ve çok daha yavaş hareket
  Widget _buildMoon(AnimationController animController) {
    return Positioned(
      top: 120, // 80'den 120'ye değiştirildi - ay'ı aşağı çekmek için
      right: 120,
      child: AnimatedBuilder(
        animation: animController,
        builder: (_, __) {
          // Çok yavaş hareket eden ay - 24 saate bir tam dönüş (gerçek dünyada olduğu gibi)
          // Saniye bazında zaman hesabı
          final moonTime =
              animController.value * 24 * 60 * 60; // 24 saatlik döngü

          // Çok küçük eliptik yörünge - çok hafif ve yavaş hareket
          final moonPosition = Offset(
            math.sin(moonTime * 0.00005) * 10, // Çok yavaş X hareketi
            math.cos(moonTime * 0.00005) * 5, // Çok yavaş Y hareketi
          );

          // Işınlanma sorununu çözmek için son pozisyonu kaydet ve kontrol et
          if (SharedBackgroundController.moonX == null) {
            SharedBackgroundController.moonX = moonPosition.dx;
            SharedBackgroundController.moonY = moonPosition.dy;
          } else {
            // Ani değişimleri kontrol et
            final xDiff =
                (moonPosition.dx - SharedBackgroundController.moonX!).abs();
            final yDiff =
                (moonPosition.dy - SharedBackgroundController.moonY!).abs();

            if (xDiff > 5 || yDiff > 5) {
              // Ani değişim - yumuşat
              final smoothX =
                  SharedBackgroundController.moonX! +
                  (moonPosition.dx - SharedBackgroundController.moonX!) * 0.01;
              final smoothY =
                  SharedBackgroundController.moonY! +
                  (moonPosition.dy - SharedBackgroundController.moonY!) * 0.01;

              // Yumuşatılmış değerleri kaydet
              SharedBackgroundController.moonX = smoothX;
              SharedBackgroundController.moonY = smoothY;
            } else {
              // Normal hareket
              SharedBackgroundController.moonX = moonPosition.dx;
              SharedBackgroundController.moonY = moonPosition.dy;
            }
          }

          // Kaydedilen pozisyonu kullan
          final smoothMoonPosition = Offset(
            SharedBackgroundController.moonX!,
            SharedBackgroundController.moonY!,
          );

          return Transform.translate(
            offset: smoothMoonPosition,
            child: ClipOval(
              // Ay'ın dışına taşan içeriği kırp
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Daha gerçekçi ay renk gradyantı
                  gradient: const RadialGradient(
                    center: Alignment(-0.2, -0.2),
                    radius: 0.9, // Radius'u küçülttük, taşmaları önlemek için
                    colors: [
                      Color(0xFFF5F5F5), // Çok açık gri
                      Color(0xFFE0E0E0), // Açık gri
                      Color(0xFFBDBDBD), // Gri
                      Color(0xFFAAAAAA), // Koyu gri
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(
                        0.1, // Glow'u azalttık
                      ), // Daha az parlak glow
                      blurRadius: 15, // Blur'u azalttık
                      spreadRadius: 1, // Spread'i azalttık
                    ),
                  ],
                ),
                // Ay kraterleri - daha gerçekçi
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

  // Scroll pozisyonuna göre hareket eden roket - daha yumuşak ve daha fiziksel
  Widget _buildScrollBasedRocket(
    BoxConstraints constraints,
    AnimationController animController,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge([animController, widget.scrollController!]),
      builder: (context, child) {
        // Scroll pozisyonunu al (0.0 - 1.0 arasında normalize edilmiş)
        final scrollProgress =
            (widget.scrollController!.hasClients)
                ? (widget.scrollController!.position.pixels /
                        (widget.pageHeight * 0.8))
                    .clamp(0.0, 1.0)
                : 0.0;

        // Roketin y pozisyonu (yukarıdan aşağıya doğru)
        final rocketY = constraints.maxHeight * scrollProgress;

        // Section'lar arasındaki geçiş için farklı rotalar hesapla
        // section sayısına göre 5 eşit parçaya böl (0%, 20%, 40%, 60%, 80%, 100%)
        final sectionCount = 5;
        final sectionIndex = (scrollProgress * sectionCount).floor();
        final sectionProgress = (scrollProgress * sectionCount) - sectionIndex;

        // Her section için farklı x pozisyonu ve dönüş açısı hesapla
        double targetXPos = 0;
        double targetAngle = 0;

        // Roketin her section için farklı rotalar izlemesi - daha yumuşak geçişler
        switch (sectionIndex) {
          case 0: // Home -> About geçişi
            // Soldan sağa doğru eğimli rota - daha yumuşak eğri
            targetXPos =
                constraints.maxWidth *
                (0.2 + _easeInOut(sectionProgress) * 0.6);
            targetAngle =
                math.pi * 1.6 +
                math.sin(_easeInOut(sectionProgress) * math.pi) *
                    0.2; // Daha az rotasyon
            break;
          case 1: // About -> Skills geçişi
            // Sağdan sola S rota - daha yumuşak
            targetXPos =
                constraints.maxWidth *
                (0.8 - _easeInOut(sectionProgress) * 0.5);
            targetAngle =
                math.pi * 1.45 +
                math.cos(_easeInOut(sectionProgress) * math.pi) * 0.2;
            break;
          case 2: // Skills -> Projects geçişi
            // Soldan ortaya doğru rota
            targetXPos =
                constraints.maxWidth *
                (0.3 + _easeInOut(sectionProgress) * 0.2);
            targetAngle =
                math.pi * 1.5 +
                math.sin(_easeInOut(sectionProgress) * math.pi * 2) * 0.1;
            break;
          case 3: // Projects -> Contact geçişi
            // Ortadan sağa doğru ve tekrar sola
            targetXPos =
                constraints.maxWidth *
                (0.5 + math.sin(_easeInOut(sectionProgress) * math.pi) * 0.3);
            targetAngle =
                math.pi * 1.5 +
                math.cos(_easeInOut(sectionProgress) * math.pi * 2) * 0.2;
            break;
          case 4: // Contact -> Footer geçişi
            // Sağdan sola ve aşağı doğru
            targetXPos =
                constraints.maxWidth *
                (0.7 - _easeInOut(sectionProgress) * 0.4);
            targetAngle =
                math.pi * 1.45 +
                math.sin(_easeInOut(sectionProgress) * math.pi) * 0.15;
            break;
          default:
            // Varsayılan rota
            targetXPos = constraints.maxWidth * 0.5;
            targetAngle = math.pi * 1.5;
        }

        // Animasyon değerlerine göre küçük ekstra hareketler ekle - çok daha az salınım
        // Gerçek zamanlı hareket için saat yerine saniye kullan
        final realTime = animController.value * 3600; // 1 saatlik döngü

        // Çok daha küçük ve daha yavaş hareketler
        targetXPos +=
            math.sin(realTime * 0.001) * 5; // Saniyede 1 pikselden az hareket
        targetAngle +=
            math.sin(realTime * 0.0005) * 0.015; // Çok hafif açı değişimi

        // Son pozisyonu al veya hedef pozisyonu kullan
        final lastXPos = SharedBackgroundController.rocketX ?? targetXPos;

        // Pozisyon değişimini sınırla - çok daha yumuşak hareket
        final maxPositionChange = 1.5; // Daha az hızlı hareket (piksel/kare)

        // X pozisyonu için yumuşak geçiş - fizik tabanlı hareket
        final xDiff = targetXPos - lastXPos;
        final limitedXDiff = xDiff.clamp(-maxPositionChange, maxPositionChange);
        final smoothXPos = lastXPos + limitedXDiff;

        // Pozisyonu kaydet
        SharedBackgroundController.rocketX = smoothXPos;
        SharedBackgroundController.rocketY = 80 + rocketY;

        // Yumuşak açı geçişleri için son açıyı kontrol et
        final lastAngle =
            SharedBackgroundController.rocketRotation ?? targetAngle;

        // Açı değişimini sınırla - çok daha yumuşak dönüşler
        final maxAngleChange = 0.01; // Çok daha az hızlı dönüş
        final angleDiff = (targetAngle - lastAngle);

        // Açı farkını normalize et
        final normalizedDiff =
            angleDiff > math.pi
                ? angleDiff - 2 * math.pi
                : (angleDiff < -math.pi ? angleDiff + 2 * math.pi : angleDiff);

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
            child: RocketWidget(animController: animController),
          ),
        );
      },
    );
  }

  // Serbest dolaşan roket - fizik kurallarına göre sürekli hareket eden
  Widget _buildFreeRoamingRocket(
    BoxConstraints constraints,
    AnimationController animController,
  ) {
    // Roketin pozisyonu - artık State değişkenini kullanıyoruz
    final rocketX = rocketPosition.dx;
    final rocketY = rocketPosition.dy;

    // Roketin merkez noktasından konumlandırılması için offset
    return Positioned(
      left: rocketX - 25, // Merkez noktasından konumlandırma için offset
      top:
          rocketY -
          50, // Merkez noktasından konumlandırma için offset - roketin boyutunun yarısı
      child: Transform.rotate(
        angle: rocketRotation,
        child: RocketWidget(animController: animController, isDragging: false),
      ),
    );
  }

  // Smooth ease-in-out fonksiyonu - daha doğal hareket için
  double _easeInOut(double t) {
    return t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1;
  }

  // Yumuşak açı geçişi için kullanılan fonksiyon
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
