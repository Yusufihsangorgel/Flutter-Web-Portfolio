import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable, kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/narrative/application/narrative_position.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_anchor.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/section_geometry.dart';

import 'package:flutter_web_portfolio/app/controllers/scroll/active_section_cubit.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll/browser_history.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll/reading_anchor_restorer.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll/section_geometry_tracker.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll/section_scroller.dart';

export 'package:flutter_web_portfolio/app/controllers/scroll/active_section_cubit.dart'
    show AppScrollState;

/// Coordinates chapter navigation and reading state.
final class AppScrollController extends ActiveSectionCubit
    with WidgetsBindingObserver {
  AppScrollController({required this.narrative, BrowserHistory? browserHistory})
    : geometry = SectionGeometryTracker(narrative),
      super(
        browserHistory ??
            (kIsWeb ? const WebBrowserHistory() : const StubBrowserHistory()),
      ) {
    _restorer = ReadingAnchorRestorer(scrollController, geometry);
    _scroller = SectionScroller(scrollController, geometry);
    _readInitialRoute();
    WidgetsBinding.instance
      ..addObserver(this)
      ..addPostFrameCallback((_) {
        if (!isClosed) refreshSectionGeometry();
      });
    scrollController.addListener(_handleScroll);
    _disposePopState = history.onPopState(_onBrowserNavigation);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointer);
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  final NarrativeDocument narrative;
  final SectionGeometryTracker geometry;
  final ScrollController scrollController = ScrollController();
  final ValueNotifier<NarrativePosition> _narrativePosition = ValueNotifier(
    const NarrativePosition.initial(),
  );
  late final ReadingAnchorRestorer _restorer;
  late final SectionScroller _scroller;
  late final void Function() _disposePopState;

  late final List<String> sectionIds = List.unmodifiable(
    narrative.chapters.map((chapter) => chapter.id.value),
  );
  bool _reduceMotion = false;
  bool _geometryFrameScheduled = false;
  bool _positionFrameScheduled = false;
  bool _initialNavigationPending = false;
  bool _manualNavigation = false;
  bool _internalAnchorScroll = false;
  int _scrollRequestId = 0;
  String? _pendingSection;
  ReadingAnchor? _pendingReadingAnchor;

  ValueListenable<NarrativePosition> get narrativePosition =>
      _narrativePosition;
  ValueListenable<NarrativeAnchorSnapshot> get narrativeAnchors =>
      geometry.anchors;
  List<SectionGeometry> get sectionGeometries => geometry.sections;

  GlobalKey keyFor(SectionId id) => geometry.keyFor(id);
  GlobalKey anchorKeyFor(SectionId id) => geometry.anchorKeyFor(id);

  void _readInitialRoute() {
    final reload = history.takeReloadSection();
    final hash = history.hash;
    final target = sectionIds.contains(reload) ? reload : hash;
    if (target.isNotEmpty && !sectionIds.contains(target)) {
      history.replaceHash('home');
      return;
    }
    if (target.isEmpty || target == 'home') return;
    _pendingSection = target;
    _initialNavigationPending = true;
    setActiveSection(target);
  }

  void setReduceMotion(bool reduceMotion) => _reduceMotion = reduceMotion;

  void handleInitialDeepLink() {
    if (isClosed || _pendingSection == null) return;
    refreshSectionGeometry();
    _restorePendingSection();
  }

  void _restorePendingSection() {
    final target = _pendingSection;
    if (target == null || !scrollController.hasClients) return;
    if (geometry.sectionFor(target) == null) return;
    if (!_scroller.jumpTo(target)) return;
    _restorer.holdChapter(target);
    history.replaceHash(target);
    _pendingSection = null;
    _initialNavigationPending = false;
    _updateNarrativePosition();
  }

  void _onBrowserNavigation(String hash) {
    if (isClosed) return;
    _restorer.release();
    final valid = hash.isEmpty || sectionIds.contains(hash);
    final section = valid && hash.isNotEmpty ? hash : 'home';
    if (!valid) history.replaceHash('home');
    _scrollRequestId += 1;
    _manualNavigation = false;
    _pendingReadingAnchor = null;
    _pendingSection = section;
    _initialNavigationPending = true;
    setActiveSection(section);
    refreshSectionGeometry();
    _restorePendingSection();
  }

  @override
  void didChangeMetrics() => markGeometryDirty();

  void markGeometryDirty({bool preserveReadingAnchor = true}) {
    if (isClosed) return;
    if (preserveReadingAnchor && _pendingReadingAnchor == null) {
      _pendingReadingAnchor = _restorer.capture(_narrativePosition.value);
    }
    if (_geometryFrameScheduled) return;
    _geometryFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geometryFrameScheduled = false;
      if (isClosed) return;
      refreshSectionGeometry();
    });
  }

  void refreshSectionGeometry() {
    if (isClosed) return;
    final readingAnchor = _pendingReadingAnchor;
    _pendingReadingAnchor = null;
    geometry.measure(scrollController.hasClients ? scrollController.offset : 0);
    if (_pendingSection != null) {
      _restorePendingSection();
    } else if (_restorer.isHolding) {
      _internalAnchorScroll = true;
      try {
        _restorer.restoreHeld();
      } finally {
        _internalAnchorScroll = false;
      }
    } else if (readingAnchor != null) {
      _restorer.restore(readingAnchor);
    }
    _updateNarrativePosition();
  }

  void _handleScroll() {
    if (_restorer.isHolding && !_internalAnchorScroll) {
      _cancelReadingHold();
    }
    if (_positionFrameScheduled || !scrollController.hasClients) return;
    _positionFrameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _positionFrameScheduled = false;
      if (!isClosed) _updateNarrativePosition();
    });
  }

  void _updateNarrativePosition() {
    if (!scrollController.hasClients || geometry.sections.isEmpty) return;
    final position = scrollController.position;
    if (!position.hasViewportDimension || position.viewportDimension <= 0) {
      return;
    }
    final offset = scrollController.offset;
    final resolved = NarrativePositionResolver.resolve(
      offset: offset,
      viewportDimension: position.viewportDimension,
      topInset: AppDimensions.appBarHeightForScrollOffset(offset),
      sections: geometry.sections,
    );
    if (_narrativePosition.value != resolved) {
      _narrativePosition.value = resolved;
    }
    if (!_manualNavigation &&
        !_initialNavigationPending &&
        !_restorer.isHolding &&
        activeSection != resolved.activeSectionId) {
      setActiveSection(resolved.activeSectionId, write: HistoryWrite.replace);
    }
  }

  void scrollToSection(String sectionId, {bool syncUrl = true}) {
    if (isClosed || !scrollController.hasClients) return;
    _restorer.release();
    _pendingReadingAnchor = null;
    _pendingSection = null;
    _initialNavigationPending = false;
    refreshSectionGeometry();
    if (geometry.sectionFor(sectionId) == null) return;
    final requestId = ++_scrollRequestId;
    _manualNavigation = true;
    setActiveSection(
      sectionId,
      write: syncUrl ? HistoryWrite.push : HistoryWrite.none,
    );
    final future = _scroller.scrollTo(sectionId, reduceMotion: _reduceMotion);
    if (future != null) unawaited(_completeScroll(future, requestId));
  }

  Future<void> _completeScroll(Future<void> future, int requestId) async {
    await future;
    if (isClosed || requestId != _scrollRequestId) return;
    _manualNavigation = false;
    refreshSectionGeometry();
  }

  void _handlePointer(PointerEvent event) {
    if (event is PointerDownEvent || event is PointerSignalEvent) {
      _cancelReadingHold();
    }
  }

  bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) _cancelReadingHold();
    return false;
  }

  void _cancelReadingHold() {
    if (!_restorer.isHolding && _pendingSection == null) return;
    _restorer.release();
    _pendingReadingAnchor = null;
    _pendingSection = null;
    _initialNavigationPending = false;
    markGeometryDirty(preserveReadingAnchor: false);
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointer);
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _disposePopState();
    _narrativePosition.dispose();
    geometry.dispose();
    scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    return super.close();
  }
}
