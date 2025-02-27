import 'package:flutter/material.dart';

/// Tüm bölümler arasında paylaşılan kozmik arka plan için singleton controller
/// Bu controller sayesinde bölümler arası geçiş yaparken arka plan animasyonları
/// kesintisiz devam eder
class SharedBackgroundController {
  // Singleton yapısı
  static final SharedBackgroundController _instance =
      SharedBackgroundController._internal();
  factory SharedBackgroundController() => _instance;
  SharedBackgroundController._internal();

  // Arka plan için kullanılacak controller - uygulamanın herhangi bir yerinde başlatılacak
  static AnimationController? _animationController;
  static final ValueNotifier<Offset> mousePosition = ValueNotifier<Offset>(
    Offset.zero,
  );

  // Animasyon controllerine erişim için getter
  static AnimationController? get animationController => _animationController;

  // Scroll kontrolcüsü
  static ScrollController? _scrollController;
  static final ValueNotifier<double> totalPageHeight = ValueNotifier<double>(
    0.0,
  );

  // Controller'ın başlatılıp başlatılmadığını kontrol eden değişken
  static bool get isInitialized => _animationController != null;

  static void init(TickerProvider vsync) {
    if (_animationController == null) {
      _animationController = AnimationController(
        duration: const Duration(seconds: 120),
        vsync: vsync,
      )..repeat();
    }
  }

  static void updateMousePosition(Offset position) {
    mousePosition.value = position;
  }

  static void setScrollController(ScrollController controller) {
    _scrollController = controller;
  }

  static ScrollController? get scrollController => _scrollController;

  static void updatePageHeight(double height) {
    totalPageHeight.value = height;
  }

  static void dispose() {
    _animationController?.dispose();
    _animationController = null;
    mousePosition.dispose();
    totalPageHeight.dispose();
  }
}
