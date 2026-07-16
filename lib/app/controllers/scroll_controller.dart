import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show ValueListenable, kIsWeb, listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/narrative/application/narrative_position.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/section_geometry.dart';
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
/// movement stays on Flutter's [ScrollController], so background painters can
/// subscribe without rebuilding navigation widgets every frame.
final class AppScrollController extends Cubit<AppScrollState>
    with WidgetsBindingObserver {
  AppScrollController({required this.narrative})
    : super(const AppScrollState()) {
    _readInitialRoute();
    WidgetsBinding.instance
      ..addObserver(this)
      ..addPostFrameCallback((_) => refreshSectionGeometry());
    scrollController.addListener(_handleScroll);

    if (kIsWeb) {
      _disposePopState = url_strategy.onPopState(_onBrowserNavigation);
    }
  }

  final NarrativeDocument narrative;

  late final Map<SectionId, GlobalKey> _sectionKeys = {
    for (final chapter in narrative.chapters) chapter.id: GlobalKey(),
  };

  final ScrollController scrollController = ScrollController();
  final ValueNotifier<NarrativePosition> _narrativePosition = ValueNotifier(
    const NarrativePosition.initial(),
  );

  String get activeSection => state.activeSection;
  ValueListenable<NarrativePosition> get narrativePosition =>
      _narrativePosition;

  late final List<String> sectionIds = List.unmodifiable(
    narrative.chapters.map((chapter) => chapter.id.value),
  );

  GlobalKey keyFor(SectionId sectionId) {
    final key = _sectionKeys[sectionId];
    if (key == null) {
      throw ArgumentError.value(
        sectionId.value,
        'sectionId',
        'is not mounted by the active narrative',
      );
    }
    return key;
  }

  List<SectionGeometry> get sectionGeometries => _sectionGeometries;

  final Map<String, double> _sectionOffsets = {};
  final Map<String, double> _sectionHeights = {};
  List<SectionGeometry> _sectionGeometries = const [];
  bool _isManualScrolling = false;
  bool _isInitialNavigationPending = false;
  bool _reduceMotion = false;
  bool _geometryFrameScheduled = false;
  bool _positionFrameScheduled = false;
  _ReadingAnchor? _pendingReadingAnchor;
  int _scrollRequestId = 0;
  String? _pendingSection;
  void Function()? _disposePopState;

  void _readInitialRoute() {
    if (!kIsWeb) return;

    final hash = url_strategy.getUrlHash();
    final reloadSection = url_strategy.takeReloadSection();
    if (reloadSection.isNotEmpty && sectionIds.contains(reloadSection)) {
      // The browser may still expose the old hash during bootstrap and then
      // normalize it while MaterialApp mounts. Delay both scroll and URL sync
      // until the measured document is ready.
      _pendingSection = reloadSection;
      _isInitialNavigationPending = reloadSection != 'home';
      return;
    }
    if (hash.isNotEmpty && sectionIds.contains(hash)) {
      _pendingSection = hash;
      _isInitialNavigationPending = hash != 'home';
      _setActiveSection(hash);
    } else if (hash.isNotEmpty) {
      url_strategy.replaceUrlHash('home');
    }
  }

  /// Keeps navigation aligned with the platform accessibility preference.
  void setReduceMotion(bool reduceMotion) {
    _reduceMotion = reduceMotion;
  }

  void handleInitialDeepLink() {
    final target = _pendingSection;
    _pendingSection = null;
    if (target == null || target == 'home') {
      _isInitialNavigationPending = false;
      return;
    }

    refreshSectionGeometry();
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (isClosed) return;
      if (!scrollController.hasClients) {
        _isInitialNavigationPending = false;
        return;
      }
      if (kIsWeb) url_strategy.replaceUrlHash(target);
      scrollToSection(target, syncUrl: false);
    });
  }

  void _setActiveSection(
    String section, {
    _UrlHistory history = _UrlHistory.none,
  }) {
    if (state.activeSection == section) return;
    emit(AppScrollState(activeSection: section));
    if (!kIsWeb) return;
    switch (history) {
      case _UrlHistory.none:
        break;
      case _UrlHistory.push:
        url_strategy.pushUrlHash(section);
      case _UrlHistory.replace:
        url_strategy.replaceUrlHash(section);
    }
  }

  void _onBrowserNavigation(String hash) {
    final valid = hash.isEmpty || sectionIds.contains(hash);
    final section = valid && hash.isNotEmpty ? hash : 'home';
    if (!valid) url_strategy.replaceUrlHash('home');
    scrollToSection(section, syncUrl: false);
  }

  @override
  void didChangeMetrics() => markGeometryDirty();

  /// Re-measures the document after the current layout frame settles.
  ///
  /// Language and responsive layout changes can both
  /// alter chapter heights without moving the primary scroll position.
  void markGeometryDirty({bool preserveReadingAnchor = true}) {
    if (isClosed) return;
    if (preserveReadingAnchor && _pendingReadingAnchor == null) {
      _pendingReadingAnchor = _captureReadingAnchor();
    }
    if (_geometryFrameScheduled) return;
    _geometryFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geometryFrameScheduled = false;
      if (isClosed) return;
      final readingAnchor = _pendingReadingAnchor;
      _pendingReadingAnchor = null;
      _refreshSectionGeometry(restoreAnchor: readingAnchor);
    });
  }

  void refreshSectionGeometry() => _refreshSectionGeometry();

  void _refreshSectionGeometry({_ReadingAnchor? restoreAnchor}) {
    final offsets = <String, double>{};
    final heights = <String, double>{};
    for (final chapter in narrative.chapters) {
      _updateKeyInfo(
        chapter.id.value,
        keyFor(chapter.id),
        offsets: offsets,
        heights: heights,
      );
    }
    final nextGeometries = List<SectionGeometry>.unmodifiable([
      for (final id in sectionIds)
        if (offsets[id] case final top?)
          if (heights[id] case final height?)
            SectionGeometry(id: id, top: top, height: height),
    ]);
    _sectionOffsets
      ..clear()
      ..addAll(offsets);
    _sectionHeights
      ..clear()
      ..addAll(heights);
    if (!listEquals(_sectionGeometries, nextGeometries)) {
      _sectionGeometries = nextGeometries;
    }
    if (restoreAnchor != null) _restoreReadingAnchor(restoreAnchor);
    _updateNarrativePosition();
  }

  _ReadingAnchor? _captureReadingAnchor() {
    if (!scrollController.hasClients || _sectionGeometries.isEmpty) {
      return null;
    }
    final snapshot = _narrativePosition.value;
    final geometry = _sectionGeometries
        .where((section) => section.id == snapshot.activeSectionId)
        .firstOrNull;
    if (geometry == null) return null;
    final localOffset = (snapshot.focalPoint - geometry.top)
        .clamp(0.0, geometry.height)
        .toDouble();
    final localProgress = (localOffset / geometry.height)
        .clamp(0.0, 1.0)
        .toDouble();
    final viewportDimension = scrollController.position.viewportDimension;
    final focalOffset = _focalOffsetFor(
      scrollOffset: scrollController.offset,
      viewportDimension: viewportDimension,
    );
    final usableViewport = math.max(
      0.0,
      viewportDimension -
          AppDimensions.appBarHeightForScrollOffset(scrollController.offset),
    );
    // A chapter link lands with its heading at the viewport start while the
    // reading focal point sits further down. Scaling that opening position by
    // chapter height can skip the heading when a compact layout grows much
    // taller, so keep an absolute local offset through this short start zone.
    final isNearChapterStart =
        localOffset <= focalOffset + usableViewport * 0.25;
    return _ReadingAnchor(
      sectionId: geometry.id,
      localOffset: localOffset,
      localProgress: localProgress,
      preserveLocalOffset: isNearChapterStart,
    );
  }

  void _restoreReadingAnchor(_ReadingAnchor anchor) {
    if (!scrollController.hasClients) return;
    final geometry = _sectionGeometries
        .where((section) => section.id == anchor.sectionId)
        .firstOrNull;
    if (geometry == null) return;

    final desiredLocalOffset = anchor.preserveLocalOffset
        ? anchor.localOffset.clamp(0.0, geometry.height).toDouble()
        : geometry.height * anchor.localProgress;
    final desiredFocalPoint = geometry.top + desiredLocalOffset;
    final viewportDimension = scrollController.position.viewportDimension;
    var targetOffset = scrollController.offset;
    for (var iteration = 0; iteration < 2; iteration += 1) {
      targetOffset =
          desiredFocalPoint -
          _focalOffsetFor(
            scrollOffset: targetOffset,
            viewportDimension: viewportDimension,
          );
    }
    targetOffset = targetOffset
        .clamp(0.0, scrollController.position.maxScrollExtent)
        .toDouble();
    if ((targetOffset - scrollController.offset).abs() >= 0.5) {
      scrollController.jumpTo(targetOffset);
    }
  }

  double _focalOffsetFor({
    required double scrollOffset,
    required double viewportDimension,
  }) {
    final topInset = AppDimensions.appBarHeightForScrollOffset(scrollOffset);
    return topInset + math.max(0.0, viewportDimension - topInset) * 0.28;
  }

  void _updateKeyInfo(
    String sectionId,
    GlobalKey key, {
    required Map<String, double> offsets,
    required Map<String, double> heights,
  }) {
    final context = key.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final viewport = RenderAbstractViewport.maybeOf(renderObject);
    if (viewport == null) return;

    offsets[sectionId] = viewport.getOffsetToReveal(renderObject, 0).offset;
    heights[sectionId] = renderObject.size.height;
  }

  void _handleScroll() {
    if (_positionFrameScheduled || !scrollController.hasClients) return;
    _positionFrameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _positionFrameScheduled = false;
      if (isClosed) return;
      _updateNarrativePosition();
    });
  }

  void _updateNarrativePosition() {
    if (!scrollController.hasClients || scrollController.positions.isEmpty) {
      return;
    }

    try {
      if (_sectionGeometries.isEmpty) return;
      final offset = scrollController.offset;
      final position = NarrativePositionResolver.resolve(
        offset: offset,
        viewportDimension: scrollController.position.viewportDimension,
        topInset: AppDimensions.appBarHeightForScrollOffset(offset),
        sections: _sectionGeometries,
      );
      if (_narrativePosition.value != position) {
        _narrativePosition.value = position;
      }
      if (!_isManualScrolling && !_isInitialNavigationPending) {
        _setActiveSection(
          position.activeSectionId,
          history: _UrlHistory.replace,
        );
      }
    } catch (error, stackTrace) {
      dev.log(
        'Narrative position resolution failed',
        name: 'AppScrollController',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void scrollToSection(String sectionId, {bool syncUrl = true}) {
    try {
      if (!scrollController.hasClients) {
        _isInitialNavigationPending = false;
        return;
      }
      refreshSectionGeometry();
      final sectionTop = _sectionOffsets[sectionId];
      if (sectionTop == null) {
        _isInitialNavigationPending = false;
        return;
      }

      final requestId = ++_scrollRequestId;
      _isManualScrolling = true;
      _setActiveSection(
        sectionId,
        history: syncUrl ? _UrlHistory.push : _UrlHistory.none,
      );

      // The measured reveal offset is the chapter destination. Applying a
      // second toolbar subtraction leaves the previous narrative bridge in
      // view on compact layouts and makes chapter links settle one bar-height
      // too early.
      final targetOffset = (sectionId == 'home' ? 0.0 : sectionTop).clamp(
        0.0,
        scrollController.position.maxScrollExtent,
      );
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
      unawaited(_completeScroll(scrollFuture, requestId));
    } catch (error, stackTrace) {
      dev.log(
        'Scroll to section failed',
        name: 'AppScrollController',
        error: error,
        stackTrace: stackTrace,
      );
      _isManualScrolling = false;
      _isInitialNavigationPending = false;
    }
  }

  Future<void> _completeScroll(Future<void> scrollFuture, int requestId) async {
    try {
      await scrollFuture;
      if (requestId == _scrollRequestId) _finishScrolling(requestId);
    } catch (error, stackTrace) {
      dev.log(
        'Section scroll animation failed',
        name: 'AppScrollController',
        error: error,
        stackTrace: stackTrace,
      );
      if (requestId == _scrollRequestId) {
        _isManualScrolling = false;
        _isInitialNavigationPending = false;
      }
    }
  }

  void _finishScrolling(int requestId) {
    Future<void>.delayed(AppDurations.heroDebounce, () {
      if (isClosed || requestId != _scrollRequestId) return;
      _isManualScrolling = false;
      _isInitialNavigationPending = false;
      refreshSectionGeometry();
      _updateNarrativePosition();
    });
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _disposePopState?.call();
    _narrativePosition.dispose();
    scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    return super.close();
  }
}

enum _UrlHistory { none, push, replace }

final class _ReadingAnchor {
  const _ReadingAnchor({
    required this.sectionId,
    required this.localOffset,
    required this.localProgress,
    required this.preserveLocalOffset,
  });

  final String sectionId;
  final double localOffset;
  final double localProgress;
  final bool preserveLocalOffset;
}
