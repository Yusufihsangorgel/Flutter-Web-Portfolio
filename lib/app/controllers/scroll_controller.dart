import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppScrollController extends GetxController {
  static AppScrollController get to => Get.find();

  final homeKey = GlobalKey();
  final aboutKey = GlobalKey();
  final experienceKey = GlobalKey();
  final projectsKey = GlobalKey();
  final skillsKey = GlobalKey();
  final contactKey = GlobalKey();

  final ScrollController scrollController = ScrollController();
  final RxString activeSection = 'home'.obs;

  final Map<String, double> _sectionOffsets = {};
  final Map<String, double> _sectionHeights = {};
  bool _isManualScrolling = false;

  Timer? _debounceTimer;
  Timer? _periodicTimer;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_handleScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSectionInfo();
      _periodicTimer = Timer.periodic(
        const Duration(milliseconds: 1000),
        (_) => _updateSectionInfo(),
      );
    });
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _periodicTimer?.cancel();
    scrollController.removeListener(_handleScroll);
    scrollController.dispose();
    super.onClose();
  }

  void _updateSectionInfo() {
    _updateKeyInfo('home', homeKey);
    _updateKeyInfo('about', aboutKey);
    _updateKeyInfo('experience', experienceKey);
    _updateKeyInfo('projects', projectsKey);
    _updateKeyInfo('skills', skillsKey);
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
    _debounceTimer = Timer(const Duration(milliseconds: 100), _detectActiveSection);
  }

  void _detectActiveSection() {
    if (!scrollController.hasClients || _sectionOffsets.isEmpty) return;

    try {
      const appBarHeight = 80.0;
      final screenHeight = Get.height;

      if (scrollController.positions.isEmpty) return;

      final scrollPosition = scrollController.offset;
      final visibleTop = scrollPosition + appBarHeight;
      final visibleBottom = visibleTop + screenHeight - appBarHeight;
      final visibleMiddle = visibleTop + (screenHeight - appBarHeight) / 2;

      final Map<String, double> sectionScores = {};

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
        String closestSection = 'home';
        double minDistance = double.infinity;

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
    } catch (_) {
      // Scroll detection failed silently
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
        'skills' => skillsKey,
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
      const appBarHeight = 80.0;

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
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          )
          .then((_) => _finishScrolling());
    } catch (_) {
      _isManualScrolling = false;
    }
  }

  void _finishScrolling() {
    Future.delayed(const Duration(milliseconds: 500), () {
      _isManualScrolling = false;
      _updateSectionInfo();
      _detectActiveSection();
    });
  }
}
