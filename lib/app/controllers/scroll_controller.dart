import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/routes/app_pages.dart';
import 'package:flutter_web_portfolio/app/utils/web_url_strategy.dart'
    as url_strategy;

/// Owns the main ScrollController, tracks section offsets, and drives smooth-scroll.
///
/// Deep-linking: keeps the browser URL in sync with the visible section and
/// scrolls to the correct section when the page is loaded via a direct URL or
/// browser back/forward navigation.
class AppScrollController extends GetxController with WidgetsBindingObserver {
  static AppScrollController get to => Get.find();

  final homeKey = GlobalKey();
  final aboutKey = GlobalKey();
  final experienceKey = GlobalKey();
  final testimonialsKey = GlobalKey();
  final blogKey = GlobalKey();
  final projectsKey = GlobalKey();
  final contactKey = GlobalKey();

  final ScrollController scrollController = ScrollController();
  final RxString activeSection = 'home'.obs;

  final Map<String, double> _sectionOffsets = {};
  final Map<String, double> _sectionHeights = {};
  bool _isManualScrolling = false;

  Timer? _debounceTimer;

  /// Pending section to scroll to on first layout (set from initial URL).
  String? _pendingSection;

  /// Dispose function for the browser popstate listener.
  void Function()? _disposePopState;

  @override
  void onInit() {
    super.onInit();

    // Determine initial section from URL before any frame renders.
    _readInitialRoute();

    WidgetsBinding.instance
      ..addObserver(this)
      ..addPostFrameCallback((_) {
        _updateSectionInfo();
      });
    scrollController.addListener(_handleScroll);

    // Listen to activeSection changes and push URL updates.
    ever(activeSection, _onActiveSectionChanged);

    // Listen for browser back/forward.
    if (kIsWeb) {
      _disposePopState = url_strategy.onPopState(_onBrowserNavigation);
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _disposePopState?.call();
    scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Deep-link helpers
  // ---------------------------------------------------------------------------

  /// Reads the initial URL hash and stores the target section for deferred scroll.
  void _readInitialRoute() {
    if (!kIsWeb) return;

    final hash = url_strategy.getUrlHash();
    if (hash.isNotEmpty && Routes.sectionIds.contains(hash)) {
      _pendingSection = hash;
      activeSection.value = hash;
    }
  }

  /// Scrolls to the pending section once layout is ready.
  ///
  /// Called from [HomeView] after its first frame to guarantee that all
  /// section GlobalKeys are attached before we attempt to scroll.
  void handleInitialDeepLink() {
    final target = _pendingSection;
    _pendingSection = null;
    if (target == null || target == 'home') return;

    _updateSectionInfo();
    // Short delay ensures section render boxes have valid sizes.
    Future.delayed(const Duration(milliseconds: 100), () {
      scrollToSection(target);
    });
  }

  /// Pushes a new browser URL when the active section changes.
  void _onActiveSectionChanged(String section) {
    if (!kIsWeb) return;
    url_strategy.setUrlHash(section);
  }

  /// Called when the user presses browser back/forward.
  void _onBrowserNavigation(String hash) {
    final section =
        (hash.isNotEmpty && Routes.sectionIds.contains(hash)) ? hash : 'home';
    scrollToSection(section);
  }

  @override
  void didChangeMetrics() {
    _updateSectionInfo();
  }

  void _updateSectionInfo() {
    _updateKeyInfo('home', homeKey);
    _updateKeyInfo('about', aboutKey);
    _updateKeyInfo('experience', experienceKey);
    _updateKeyInfo('testimonials', testimonialsKey);
    _updateKeyInfo('blog', blogKey);
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
        'testimonials' => testimonialsKey,
        'blog' => blogKey,
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
