import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/routes/app_routes.dart';
import 'package:flutter_web_portfolio/app/utils/web_url_strategy.dart'
    as url_strategy;

@immutable
final class AppScrollState {
  const AppScrollState({this.activeSection = 'home'});

  final String activeSection;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppScrollState && activeSection == other.activeSection;

  @override
  int get hashCode => activeSection.hashCode;
}

/// Measured document geometry for one portfolio chapter.
///
/// Navigation and the scene engine share this coordinate system. This keeps
/// visual transitions aligned even when chapters have different heights.
@immutable
final class SectionGeometry {
  const SectionGeometry({
    required this.id,
    required this.top,
    required this.height,
  });

  final String id;
  final double top;
  final double height;

  double get bottom => top + height;
  double get center => top + height / 2;
}

/// Owns the primary scroll position, section geometry and URL synchronization.
///
/// Section changes are exposed as immutable Cubit state. Pixel-level scroll
/// movement stays on Flutter's [ScrollController], so background painters can
/// subscribe without rebuilding navigation widgets every frame.
final class AppScrollController extends Cubit<AppScrollState>
    with WidgetsBindingObserver {
  AppScrollController() : super(const AppScrollState()) {
    _readInitialRoute();
    WidgetsBinding.instance
      ..addObserver(this)
      ..addPostFrameCallback((_) => refreshSectionGeometry());
    scrollController.addListener(_handleScroll);

    if (kIsWeb) {
      _disposePopState = url_strategy.onPopState(_onBrowserNavigation);
    }
  }

  final homeKey = GlobalKey();
  final aboutKey = GlobalKey();
  final experienceKey = GlobalKey();
  final proofKey = GlobalKey();
  final projectsKey = GlobalKey();

  final ScrollController scrollController = ScrollController();

  String get activeSection => state.activeSection;

  List<SectionGeometry> get sectionGeometries => [
    for (final id in Routes.sectionIds)
      if (_sectionOffsets[id] case final top?)
        if (_sectionHeights[id] case final height?)
          SectionGeometry(id: id, top: top, height: height),
  ];

  final Map<String, double> _sectionOffsets = {};
  final Map<String, double> _sectionHeights = {};
  bool _isManualScrolling = false;
  bool _reduceMotion = false;
  int _scrollRequestId = 0;
  Timer? _debounceTimer;
  String? _pendingSection;
  void Function()? _disposePopState;

  void _readInitialRoute() {
    if (!kIsWeb) return;

    final hash = url_strategy.getUrlHash();
    final reloadSection = url_strategy.takeReloadSection();
    if (reloadSection.isNotEmpty && Routes.sectionIds.contains(reloadSection)) {
      // The browser may still expose the old hash during bootstrap and then
      // normalize it while MaterialApp mounts. Delay both scroll and URL sync
      // until the measured document is ready.
      _pendingSection = reloadSection;
      return;
    }
    if (hash.isNotEmpty && Routes.sectionIds.contains(hash)) {
      _pendingSection = hash;
      _setActiveSection(hash, syncUrl: false);
    }
  }

  /// Keeps navigation aligned with the platform accessibility preference.
  void setReduceMotion(bool reduceMotion) {
    _reduceMotion = reduceMotion;
  }

  void handleInitialDeepLink() {
    final target = _pendingSection;
    _pendingSection = null;
    if (target == null || target == 'home') return;

    refreshSectionGeometry();
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (isClosed) return;
      scrollToSection(target);
    });
  }

  void _setActiveSection(String section, {bool syncUrl = true}) {
    if (state.activeSection == section) return;
    emit(AppScrollState(activeSection: section));
    if (syncUrl) _onActiveSectionChanged(section);
  }

  void _onActiveSectionChanged(String section) {
    if (!kIsWeb) return;
    url_strategy.setUrlHash(section);
  }

  void _onBrowserNavigation(String hash) {
    final section = hash.isNotEmpty && Routes.sectionIds.contains(hash)
        ? hash
        : 'home';
    scrollToSection(section, syncUrl: false);
  }

  @override
  void didChangeMetrics() => refreshSectionGeometry();

  void refreshSectionGeometry() {
    _updateKeyInfo('home', homeKey);
    _updateKeyInfo('about', aboutKey);
    _updateKeyInfo('experience', experienceKey);
    _updateKeyInfo('proof', proofKey);
    _updateKeyInfo('projects', projectsKey);
  }

  void _updateKeyInfo(String sectionId, GlobalKey key) {
    final context = key.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final viewport = RenderAbstractViewport.maybeOf(renderObject);
    if (viewport == null) return;

    _sectionOffsets[sectionId] = viewport
        .getOffsetToReveal(renderObject, 0)
        .offset;
    _sectionHeights[sectionId] = renderObject.size.height;
  }

  void _handleScroll() {
    if (_isManualScrolling || !scrollController.hasClients) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(AppDurations.scrollDebounce, _detectActiveSection);
  }

  void _detectActiveSection() {
    if (!scrollController.hasClients || scrollController.positions.isEmpty) {
      return;
    }

    try {
      refreshSectionGeometry();
      if (_sectionOffsets.isEmpty) return;

      const appBarHeight = AppDimensions.appBarHeight;
      final scrollOffset = scrollController.offset;
      final rawViewportHeight = scrollController.position.viewportDimension;
      final viewportHeight = rawViewportHeight > appBarHeight
          ? rawViewportHeight - appBarHeight
          : 0.0;
      final focalPoint = scrollOffset + appBarHeight + viewportHeight * 0.28;

      var bestSection = 'home';
      for (final sectionId in Routes.sectionIds) {
        final top = _sectionOffsets[sectionId];
        if (top == null || top > focalPoint + 1) break;
        bestSection = sectionId;
      }

      _setActiveSection(bestSection);
    } catch (error, stackTrace) {
      dev.log(
        'Section detection failed',
        name: 'AppScrollController',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void scrollToSection(String sectionId, {bool syncUrl = true}) {
    try {
      if (!scrollController.hasClients) return;
      refreshSectionGeometry();
      final sectionTop = _sectionOffsets[sectionId];
      if (sectionTop == null) return;

      final requestId = ++_scrollRequestId;
      _debounceTimer?.cancel();
      _isManualScrolling = true;
      _setActiveSection(sectionId, syncUrl: syncUrl);

      final targetOffset =
          (sectionId == 'home'
                  ? 0.0
                  : sectionTop - AppDimensions.appBarHeightMobile)
              .clamp(0.0, scrollController.position.maxScrollExtent);
      final Future<void> scrollFuture;
      if (_reduceMotion) {
        scrollController.jumpTo(targetOffset);
        scrollFuture = Future<void>.value();
      } else {
        scrollFuture = scrollController.animateTo(
          targetOffset,
          duration: AppDurations.sectionScroll,
          curve: Curves.easeInOut,
        );
      }
      unawaited(
        scrollFuture.then((_) {
          if (requestId == _scrollRequestId) _finishScrolling(requestId);
        }),
      );
    } catch (error, stackTrace) {
      dev.log(
        'Scroll to section failed',
        name: 'AppScrollController',
        error: error,
        stackTrace: stackTrace,
      );
      _isManualScrolling = false;
    }
  }

  void _finishScrolling(int requestId) {
    Future<void>.delayed(AppDurations.heroDebounce, () {
      if (isClosed || requestId != _scrollRequestId) return;
      _isManualScrolling = false;
      refreshSectionGeometry();
      _detectActiveSection();
    });
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _disposePopState?.call();
    scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    return super.close();
  }
}
