import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

/// Owns the main ScrollController, tracks section offsets, and drives smooth-scroll.
class AppScrollController extends GetxController with WidgetsBindingObserver {
  static AppScrollController get to => Get.find();

  final homeKey = GlobalKey();
  final aboutKey = GlobalKey();
  final experienceKey = GlobalKey();
  final projectsKey = GlobalKey();
  final contactKey = GlobalKey();

  final ScrollController scrollController = ScrollController();
  final RxString activeSection = 'home'.obs;

  final Map<String, double> _sectionOffsets = {};
  final Map<String, double> _sectionHeights = {};
  bool _isManualScrolling = false;

  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance
      ..addObserver(this)
      ..addPostFrameCallback((_) {
        _updateSectionInfo();
      });
    scrollController.addListener(_handleScroll);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.onClose();
  }

  @override
  void didChangeMetrics() {
    _updateSectionInfo();
  }

  void _updateSectionInfo() {
    _updateKeyInfo('home', homeKey);
    _updateKeyInfo('about', aboutKey);
    _updateKeyInfo('experience', experienceKey);
    _updateKeyInfo('projects', projectsKey);
    _updateKeyInfo('contact', contactKey);
  }

  void _updateKeyInfo(String sectionId, GlobalKey key) {
    if (key.currentContext == null) return;

    final renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    _sectionOffsets[sectionId] = position.dy;
    _sectionHeights[sectionId] = renderBox.size.height;
  }

  void _handleScroll() {
    if (_isManualScrolling) return;
    if (!scrollController.hasClients) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(AppDurations.scrollDebounce, _detectActiveSection);
  }

  void _detectActiveSection() {
    if (!scrollController.hasClients || _sectionOffsets.isEmpty) return;

    try {
      const appBarHeight = AppDimensions.appBarHeight;
      final screenHeight = Get.height;

      if (scrollController.positions.isEmpty) return;

      final scrollPosition = scrollController.offset;
      final visibleTop = scrollPosition + appBarHeight;
      final visibleBottom = visibleTop + screenHeight - appBarHeight;
      final visibleMiddle = visibleTop + (screenHeight - appBarHeight) / 2;

      final sectionScores = <String, double>{};

      _sectionOffsets.forEach((sectionId, offsetTop) {
        final height = _sectionHeights[sectionId] ?? 600;
        final offsetBottom = offsetTop + height;

        final visibleStart = math.max(offsetTop, visibleTop);
        final visibleEnd = math.min(offsetBottom, visibleBottom);

        if (visibleEnd > visibleStart) {
          final visibleAmount = visibleEnd - visibleStart;
          final visibilityPercentage = visibleAmount / height;

          final sectionMiddle = offsetTop + height / 2;
          final distanceFromMiddle = (sectionMiddle - visibleMiddle).abs();
          final normalizedDistance =
              1.0 - math.min(1.0, distanceFromMiddle / (screenHeight / 2));

          sectionScores[sectionId] =
              (visibilityPercentage * 0.7) + (normalizedDistance * 0.3);
        }
      });

      if (sectionScores.isEmpty) {
        var closestSection = 'home';
        var minDistance = double.infinity;

        _sectionOffsets.forEach((sectionId, offsetTop) {
          final height = _sectionHeights[sectionId] ?? 0;
          final sectionMiddle = offsetTop + height / 2;
          final distance = (sectionMiddle - visibleMiddle).abs();

          if (distance < minDistance) {
            minDistance = distance;
            closestSection = sectionId;
          }
        });

        if (activeSection.value != closestSection) {
          activeSection.value = closestSection;
        }
        return;
      }

      final bestSection = sectionScores.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      if (activeSection.value != bestSection) {
        activeSection.value = bestSection;
      }
    } catch (e) {
      dev.log('Section detection failed', name: 'AppScrollController', error: e);
    }
  }

  void scrollToSection(String sectionId) {
    try {
      if (!scrollController.hasClients) return;

      final sectionKey = switch (sectionId) {
        'home' => homeKey,
        'about' => aboutKey,
        'experience' => experienceKey,
        'projects' => projectsKey,
        'contact' => contactKey,
        _ => null,
      };
      if (sectionKey == null) return;

      if (sectionKey.currentContext == null) return;

      _isManualScrolling = true;
      activeSection.value = sectionId;

      final renderBox =
          sectionKey.currentContext!.findRenderObject() as RenderBox;
      final screenSize = Get.size;
      const appBarHeight = AppDimensions.appBarHeight;

      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final currentScrollPosition = scrollController.offset;
      final viewportHeight = screenSize.height - appBarHeight;
      final targetGlobalY = appBarHeight + (viewportHeight - size.height) / 2;

      var targetScrollOffset =
          position.dy - targetGlobalY + currentScrollPosition;
      targetScrollOffset = math.max(0, targetScrollOffset);

      if (scrollController.position.maxScrollExtent > 0) {
        targetScrollOffset = math.min(
          targetScrollOffset,
          scrollController.position.maxScrollExtent,
        );
      }

      scrollController
          .animateTo(
            targetScrollOffset,
            duration: AppDurations.sectionScroll,
            curve: Curves.easeInOut,
          )
          .then((_) => _finishScrolling());
    } catch (e) {
      dev.log('Scroll to section failed', name: 'AppScrollController', error: e);
      _isManualScrolling = false;
    }
  }

  void _finishScrolling() {
    Future.delayed(AppDurations.heroDebounce, () {
      _isManualScrolling = false;
      _updateSectionInfo();
      _detectActiveSection();
    });
  }
}
