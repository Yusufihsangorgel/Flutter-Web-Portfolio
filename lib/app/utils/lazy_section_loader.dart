import 'package:flutter/material.dart';

/// Configuration for a single lazy-loaded section.
class LazySection {
  /// Creates a section descriptor.
  ///
  /// [builder] builds the actual section content.
  /// [estimatedHeight] is used for the placeholder before the section loads.
  /// [key] optionally identifies the section for programmatic scrolling.
  const LazySection({
    required this.builder,
    required this.estimatedHeight,
    this.key,
  });

  /// Builds the real section widget.
  final WidgetBuilder builder;

  /// Placeholder height shown before the section enters the load zone.
  final double estimatedHeight;

  /// Optional key for identification.
  final Key? key;
}

/// Lazily builds sections as they approach the viewport, preventing all
/// sections from rendering simultaneously on initial load.
///
/// Each section outside the viewport renders as a lightweight placeholder
/// with a fixed height. Sections within [preloadDistance] of the viewport
/// edge begin building and fade in smoothly.
///
/// Wrap your scroll view's children with this widget:
/// ```dart
/// LazySectionLoader(
///   scrollController: _scrollController,
///   sections: [
///     LazySection(builder: (_) => HomeSection(), estimatedHeight: 800),
///     LazySection(builder: (_) => AboutSection(), estimatedHeight: 600),
///     // ...
///   ],
/// )
/// ```
class LazySectionLoader extends StatefulWidget {
  const LazySectionLoader({
    super.key,
    required this.sections,
    this.scrollController,
    this.preloadDistance = 500.0,
    this.fadeDuration = const Duration(milliseconds: 400),
    this.fadeCurve = Curves.easeOut,
  });

  /// The sections to lazily load.
  final List<LazySection> sections;

  /// The scroll controller driving the parent scrollable. If null, the widget
  /// will attempt to find an ancestor [Scrollable].
  final ScrollController? scrollController;

  /// How far ahead of the viewport edge to start building sections (px).
  final double preloadDistance;

  /// Duration of the fade-in animation when a section loads.
  final Duration fadeDuration;

  /// Curve of the fade-in animation.
  final Curve fadeCurve;

  @override
  State<LazySectionLoader> createState() => _LazySectionLoaderState();
}

class _LazySectionLoaderState extends State<LazySectionLoader> {
  /// Tracks which sections have been activated (built at least once).
  late List<bool> _activated;

  ScrollController? _effectiveController;

  @override
  void initState() {
    super.initState();
    _activated = List.filled(widget.sections.length, false);
    // Activate the first section immediately so the hero is always visible.
    if (_activated.isNotEmpty) {
      _activated[0] = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detachListener();
    _effectiveController =
        widget.scrollController ?? Scrollable.maybeOf(context)?.widget.controller;
    _effectiveController?.addListener(_onScroll);
    // Run an initial check in case sections are already in view.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void didUpdateWidget(LazySectionLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sections.length != widget.sections.length) {
      final prev = _activated;
      _activated = List.generate(
        widget.sections.length,
        (i) => i < prev.length ? prev[i] : false,
      );
      if (_activated.isNotEmpty && !_activated[0]) {
        _activated[0] = true;
      }
    }
    if (oldWidget.scrollController != widget.scrollController) {
      _detachListener();
      _effectiveController = widget.scrollController;
      _effectiveController?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _detachListener();
    super.dispose();
  }

  void _detachListener() {
    _effectiveController?.removeListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    final controller = _effectiveController;
    if (controller == null || !controller.hasClients) return;

    final viewportTop = controller.offset;
    final viewportBottom =
        viewportTop + controller.position.viewportDimension;
    final loadZoneTop = viewportTop - widget.preloadDistance;
    final loadZoneBottom = viewportBottom + widget.preloadDistance;

    // Compute cumulative offsets for each section based on estimated heights.
    var cumulativeOffset = 0.0;
    var changed = false;

    for (var i = 0; i < widget.sections.length; i++) {
      final sectionTop = cumulativeOffset;
      final sectionBottom = sectionTop + widget.sections[i].estimatedHeight;
      cumulativeOffset = sectionBottom;

      if (_activated[i]) continue;

      // Section overlaps with the load zone.
      if (sectionBottom >= loadZoneTop && sectionTop <= loadZoneBottom) {
        _activated[i] = true;
        changed = true;
      }
    }

    if (changed && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(widget.sections.length, (index) {
          final section = widget.sections[index];
          return _LazySectionSlot(
            key: section.key ?? ValueKey('lazy_section_$index'),
            isActivated: _activated[index],
            estimatedHeight: section.estimatedHeight,
            fadeDuration: widget.fadeDuration,
            fadeCurve: widget.fadeCurve,
            builder: section.builder,
          );
        }),
      );
}

/// Renders either a placeholder or the real section wrapped in a
/// [RepaintBoundary] and fade-in animation.
class _LazySectionSlot extends StatefulWidget {
  const _LazySectionSlot({
    super.key,
    required this.isActivated,
    required this.estimatedHeight,
    required this.fadeDuration,
    required this.fadeCurve,
    required this.builder,
  });

  final bool isActivated;
  final double estimatedHeight;
  final Duration fadeDuration;
  final Curve fadeCurve;
  final WidgetBuilder builder;

  @override
  State<_LazySectionSlot> createState() => _LazySectionSlotState();
}

class _LazySectionSlotState extends State<_LazySectionSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _hasBuilt = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: widget.fadeCurve,
    );

    if (widget.isActivated) {
      _activate();
    }
  }

  @override
  void didUpdateWidget(_LazySectionSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActivated && widget.isActivated) {
      _activate();
    }
  }

  void _activate() {
    if (_hasBuilt) return;
    _hasBuilt = true;
    // Start fade-in on the next frame so the first build is included.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasBuilt) {
      // Lightweight placeholder preserving scroll extent.
      return SizedBox(height: widget.estimatedHeight);
    }

    return RepaintBoundary(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.builder(context),
      ),
    );
  }
}
