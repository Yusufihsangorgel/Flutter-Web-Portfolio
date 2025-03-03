import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Uygulama genelinde paylaşılan arka plan kontrolcüsü.
/// Arka plan animasyonlarını ve görsel efektleri yönetir.
class SharedBackgroundController extends GetxController {
  static SharedBackgroundController get to => Get.find();

  // Yıldız animasyonu kontrolü
  final RxBool _showStars = true.obs;
  final RxBool _showMoon = true.obs;
  final RxBool _showGrid = true.obs;
  final RxBool _showParticles = true.obs;

  // Getter'lar
  bool get showStars => _showStars.value;
  bool get showMoon => _showMoon.value;
  bool get showGrid => _showGrid.value;
  bool get showParticles => _showParticles.value;

  /// Yıldızların görünürlüğünü değiştirir
  void toggleStars() {
    _showStars.value = !_showStars.value;
    update();
  }

  /// Ayın görünürlüğünü değiştirir
  void toggleMoon() {
    _showMoon.value = !_showMoon.value;
    update();
  }

  /// Izgara görünürlüğünü değiştirir
  void toggleGrid() {
    _showGrid.value = !_showGrid.value;
    update();
  }

  /// Parçacıkların görünürlüğünü değiştirir
  void toggleParticles() {
    _showParticles.value = !_showParticles.value;
    update();
  }

  /// Tüm arka plan öğelerini açar
  void enableAllEffects() {
    _showStars.value = true;
    _showMoon.value = true;
    _showGrid.value = true;
    _showParticles.value = true;
    update();
  }

  /// Tüm arka plan öğelerini kapatır
  void disableAllEffects() {
    _showStars.value = false;
    _showMoon.value = false;
    _showGrid.value = false;
    _showParticles.value = false;
    update();
  }

  // Singleton yapısı
  static final SharedBackgroundController _instance =
      SharedBackgroundController._internal();
  factory SharedBackgroundController() => _instance;
  SharedBackgroundController._internal();

  // Arka plan için kullanılacak controller - uygulamanın herhangi bir yerinde başlatılacak
  static AnimationController? _animationController;
  static final Rx<Offset> mousePosition = Offset.zero.obs;

  // Roketin rotasyon açısını tut - yumuşak geçişler için
  static double? rocketRotation;

  // Roketin pozisyonunu tut - teleport sorununu çözmek için
  static double? rocketX;
  static double? rocketY;

  // Roketin son hareket yönünü tut - ani değişimleri tespit etmek için
  static double? rocketLastDx;
  static double? rocketLastDy;

  // Roketin sürüklenmesi için gerekli değişkenler
  static bool isRocketDragging = false;
  static Offset? rocketDragPosition;
  static Offset? rocketDragDelta;

  // Ay pozisyonunu tut - teleport sorununu çözmek için
  static double? moonX;
  static double? moonY;

  // Roket animasyonu için sürekli zaman değişkenleri
  static double? rocketContinuousTime;
  static double lastAnimValue = 0.0;

  // Roketin hareket parametrelerini tut
  static double? rocketParamA;
  static double? rocketParamB;
  static double? rocketParamC;
  static double? rocketParamDelta;

  // Animasyon controllerine erişim için getter
  static AnimationController? get animationController => _animationController;

  // Scroll kontrolcüsü
  static ScrollController? _scrollController;
  static final ValueNotifier<double> totalPageHeight = ValueNotifier<double>(
    0.0,
  );

  // Controller'ın başlatılıp başlatılmadığını kontrol eden değişken
  static bool get isInitialized => _animationController != null;

  /// Animasyon kontrolcüsünü başlatır
  static void init(TickerProvider vsync) {
    if (_animationController == null) {
      _animationController = AnimationController(
        duration: const Duration(minutes: 10), // Çok daha uzun süre - 10 dakika
        vsync: vsync,
      );

      // Animasyonu başlat - sonsuz döngü
      _animationController!.forward();

      // Animasyon tamamlandığında otomatik olarak tekrar başlat
      _animationController!.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // Animasyonu sıfırlamadan devam ettir - ani değişim olmasın
          // Önce son değerleri kaydet
          final lastValue = _animationController!.value;

          // Animasyonu başa al ama değerleri sıfırlama
          _animationController!.reset();

          // Hemen bir sonraki kareye geç (0.0'dan başlama)
          _animationController!.value = 0.001;

          // Devam et
          _animationController!.forward();
        }
      });
    }
  }

  /// Fare pozisyonunu günceller
  static void updateMousePosition(Offset position) {
    mousePosition.value = position;
  }

  /// Kaydırma kontrolcüsünü ayarlar
  static void setScrollController(ScrollController controller) {
    _scrollController = controller;
  }

  /// Kaydırma kontrolcüsüne erişim sağlar
  static ScrollController? get scrollController => _scrollController;

  /// Sayfa yüksekliğini günceller
  static void updatePageHeight(double height) {
    totalPageHeight.value = height;
  }

  /// Kaynakları temizler ve kontrolcüleri serbest bırakır
  static void clearResources() {
    _animationController?.dispose();
    _animationController = null;
    mousePosition.close();
    totalPageHeight.dispose();
  }

  @override
  void onClose() {
    // GetX controller kapatıldığında gerekli temizleme işlemleri
    super.onClose();
  }

  /// Animasyon controller'ı ayarlar
  static void setAnimationController(AnimationController controller) {
    _animationController = controller;
  }

  /// Tüm değerleri sıfırlar
  static void reset() {
    rocketX = null;
    rocketY = null;
    rocketRotation = null;
    rocketLastDx = null;
    rocketLastDy = null;
    isRocketDragging = false;
    rocketDragPosition = null;
    rocketDragDelta = null;
    moonX = null;
    moonY = null;
    rocketContinuousTime = null;
    lastAnimValue = 0.0;
    rocketParamA = null;
    rocketParamB = null;
    rocketParamC = null;
    rocketParamDelta = null;
    mousePosition.value = Offset.zero;
  }
}
