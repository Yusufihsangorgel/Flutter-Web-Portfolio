import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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

/// Owns the primary scroll position, section geometry and URL synchronization.
///
/// Section changes are exposed as immutable Cubit state. Pixel-level scroll
/// movement stays on Flutter's [ScrollController], so cinematic painters can
/// subscribe without rebuilding navigation widgets every frame.
final class AppScrollController extends Cubit<AppScrollState>
    with WidgetsBindingObserver {
  AppScrollController() : super(const AppScrollState()) {
    _readInitialRoute();
    WidgetsBinding.instance
      ..addObserver(this)
      ..addPostFrameCallback((_) => _updateSectionInfo());
    scrollController.addListener(_handleScroll);

    if (kIsWeb) {
      _disposePopState = url_strategy.onPopState(_onBrowserNavigation);
    }
  }

  final homeKey = GlobalKey();
  final aboutKey = GlobalKey();
  final experienceKey = GlobalKey();
  final proofKey = GlobalKey();
  final blogKey = GlobalKey();
  final projectsKey = GlobalKey();
  final contactKey = GlobalKey();

  final ScrollController scrollController = ScrollController();

  String get activeSection => state.activeSection;

  final Map<String, double> _sectionOffsets = {};
  final Map<String, double> _sectionHeights = {};
  bool _isManualScrolling = false;
  bool _suppressNextHistoryUpdate = false;
  Timer? _debounceTimer;
  String? _pendingSection;
  void Function()? _disposePopState;

  void _readInitialRoute() {
    if (!kIsWeb) return;

    final hash = url_strategy.getUrlHash();
    if (hash.isNotEmpty && Routes.sectionIds.contains(hash)) {
      _pendingSection = hash;
      _setActiveSection(hash, syncUrl: false);
    }
  }

  void handleInitialDeepLink() {
    final target = _pendingSection;
    _pendingSection = null;
    if (target == null || target == 'home') return;

    _updateSectionInfo();
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (!isClosed) scrollToSection(target);
    });
  }

  void _setActiveSection(String section, {bool syncUrl = true}) {
    if (state.activeSection == section) return;
    emit(AppScrollState(activeSection: section));
    if (syncUrl) _onActiveSectionChanged(section);
  }

  void _onActiveSectionChanged(String section) {
    if (!kIsWeb) return;
    if (_suppressNextHistoryUpdate) {
      _suppressNextHistoryUpdate = false;
      return;
    }
    url_strategy.setUrlHash(section);
  }

  void _onBrowserNavigation(String hash) {
    final section = hash.isNotEmpty && Routes.sectionIds.contains(hash)
        ? hash
        : 'home';
    _suppressNextHistoryUpdate = state.activeSection != section;
    scrollToSection(section);
  }

  @override
  void didChangeMetrics() => _updateSectionInfo();

  void _updateSectionInfo() {
    _updateKeyInfo('home', homeKey);
    _updateKeyInfo('about', aboutKey);
    _updateKeyInfo('experience', experienceKey);
    _updateKeyInfo('proof', proofKey);
    _updateKeyInfo('blog', blogKey);
    _updateKeyInfo('projects', projectsKey);
    _updateKeyInfo('contact', contactKey);
  }

  void _updateKeyInfo(String sectionId, GlobalKey key) {
    final context = key.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final position = renderObject.localToGlobal(Offset.zero);
    final currentOffset = scrollController.hasClients
        ? scrollController.offset
        : 0.0;
    _sectionOffsets[sectionId] = position.dy + currentOffset;
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
      _updateSectionInfo();
      if (_sectionOffsets.isEmpty) return;

      const appBarHeight = AppDimensions.appBarHeight;
      final scrollOffset = scrollController.offset;
      final rawViewportHeight = scrollController.position.viewportDimension;
      final viewportHeight = rawViewportHeight > appBarHeight
          ? rawViewportHeight - appBarHeight
          : 0.0;
      final viewportCenter = scrollOffset + appBarHeight + viewportHeight / 2;

      var bestSection = 'home';
      var bestDistance = double.infinity;
      _sectionOffsets.forEach((sectionId, top) {
        final height = _sectionHeights[sectionId] ?? 0;
        final distance = (top + height / 2 - viewportCenter).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          bestSection = sectionId;
        }
      });

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

  void scrollToSection(String sectionId) {
    try {
      if (!scrollController.hasClients) return;

      final sectionKey = switch (sectionId) {
        'home' => homeKey,
        'about' => aboutKey,
        'experience' => experienceKey,
        'proof' => proofKey,
        'blog' => blogKey,
        'projects' => projectsKey,
        'contact' => contactKey,
        _ => null,
      };
      final sectionContext = sectionKey?.currentContext;
      final renderObject = sectionContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;

      _isManualScrolling = true;
      _setActiveSection(sectionId);

      const appBarHeight = AppDimensions.appBarHeight;
      final globalY = renderObject.localToGlobal(Offset.zero).dy;
      final targetScrollOffset =
          (globalY + scrollController.offset - appBarHeight).clamp(
            0.0,
            scrollController.position.maxScrollExtent,
          );

      unawaited(
        scrollController
            .animateTo(
              targetScrollOffset,
              duration: AppDurations.sectionScroll,
              curve: Curves.easeInOut,
            )
            .then((_) => _finishScrolling()),
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

  void _finishScrolling() {
    Future<void>.delayed(AppDurations.heroDebounce, () {
      if (isClosed) return;
      _isManualScrolling = false;
      _updateSectionInfo();
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
