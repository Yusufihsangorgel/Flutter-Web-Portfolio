import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SharedBackgroundController extends GetxController {
  static SharedBackgroundController get to => Get.find();

  final RxBool _showStars = true.obs;
  final RxBool _showMoon = true.obs;
  final RxBool _showGrid = true.obs;
  final RxBool _showParticles = true.obs;

  bool get showStars => _showStars.value;
  bool get showMoon => _showMoon.value;
  bool get showGrid => _showGrid.value;
  bool get showParticles => _showParticles.value;

  void toggleStars() {
    _showStars.value = !_showStars.value;
    update();
  }

  void toggleMoon() {
    _showMoon.value = !_showMoon.value;
    update();
  }

  void toggleGrid() {
    _showGrid.value = !_showGrid.value;
    update();
  }

  void toggleParticles() {
    _showParticles.value = !_showParticles.value;
    update();
  }

  void enableAllEffects() {
    _showStars.value = true;
    _showMoon.value = true;
    _showGrid.value = true;
    _showParticles.value = true;
    update();
  }

  void disableAllEffects() {
    _showStars.value = false;
    _showMoon.value = false;
    _showGrid.value = false;
    _showParticles.value = false;
    update();
  }

  // Animation state
  static AnimationController? _animationController;
  static final Rx<Offset> mousePosition = Offset.zero.obs;

  // Rocket state
  static double? rocketRotation;
  static double? rocketX;
  static double? rocketY;
  static double? rocketLastDx;
  static double? rocketLastDy;
  static bool isRocketDragging = false;
  static Offset? rocketDragPosition;
  static Offset? rocketDragDelta;

  // Moon state
  static double? moonX;
  static double? moonY;

  // Rocket animation timing
  static double? rocketContinuousTime;
  static double lastAnimValue = 0.0;

  // Rocket motion parameters
  static double? rocketParamA;
  static double? rocketParamB;
  static double? rocketParamC;
  static double? rocketParamDelta;

  static AnimationController? get animationController => _animationController;

  // Scroll controller
  static ScrollController? _scrollController;
  static final ValueNotifier<double> totalPageHeight = ValueNotifier<double>(0.0);

  static bool get isInitialized => _animationController != null;

  /// @deprecated Use setAnimationController instead.
  /// Kept for backward compatibility — safely no-ops if already initialized.
  static void init(TickerProvider vsync) {
    // No-op: animation controller is now managed by HomeView
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

  static void clearResources() {
    _animationController?.dispose();
    _animationController = null;
    mousePosition.close();
    totalPageHeight.dispose();
  }


  static void setAnimationController(AnimationController controller) {
    _animationController = controller;
  }

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
