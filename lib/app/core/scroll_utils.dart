import 'package:flutter/material.dart';

/// Scroll and viewport utility functions.
///
/// These are pure helpers with no dependency on GetX so they can be called
/// from anywhere (widgets, controllers, tests).
final class ScrollUtils {
  const ScrollUtils._();

  // ---------------------------------------------------------------------------
  // scrollToSection
  // ---------------------------------------------------------------------------

  /// Smoothly scrolls the [Scrollable] ancestor of [key] so that the widget
  /// identified by [key] is visible in the viewport.
  ///
  /// Falls back to [Scrollable.ensureVisible] which handles nested scroll
  /// views, slivers, and custom viewports.
  ///
  /// Returns a [Future] that completes when the animation finishes.
  static Future<void> scrollToSection(
    GlobalKey key, {
    Duration duration = const Duration(milliseconds: 800),
    Curve curve = Curves.easeInOut,
    double alignment = 0.0,
  }) async {
    final context = key.currentContext;
    if (context == null) return;

    await Scrollable.ensureVisible(
      context,
      duration: duration,
      curve: curve,
      alignment: alignment,
    );
  }

  /// Overload that accepts a [ScrollController] and a target pixel offset
  /// instead of a [GlobalKey].
  static Future<void> scrollToOffset(
    ScrollController controller,
    double offset, {
    Duration duration = const Duration(milliseconds: 800),
    Curve curve = Curves.easeInOut,
  }) async {
    if (!controller.hasClients) return;

    final clamped = offset.clamp(
      controller.position.minScrollExtent,
      controller.position.maxScrollExtent,
    );

    await controller.animateTo(clamped, duration: duration, curve: curve);
  }

  // ---------------------------------------------------------------------------
  // isInViewport
  // ---------------------------------------------------------------------------

  /// Returns `true` if the widget identified by [key] is at least partially
  /// visible in the viewport (i.e. its render box overlaps the visible area).
  ///
  /// [margin] lets you consider a widget "in viewport" when it is within
  /// [margin] pixels of the visible edge (useful for pre-loading / animating
  /// elements before they scroll into view).
  static bool isInViewport(GlobalKey key, {double margin = 0.0}) {
    final context = key.currentContext;
    if (context == null) return false;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;

    final position = box.localToGlobal(Offset.zero);
    final size = box.size;

    // Use the nearest Scrollable's viewport or fall back to screen height.
    final viewportHeight =
        MediaQuery.maybeOf(context)?.size.height ?? 800.0;

    final top = position.dy;
    final bottom = top + size.height;

    // Widget is in viewport if its bottom edge is below the top of the screen
    // (minus margin) and its top edge is above the bottom (plus margin).
    return bottom > -margin && top < viewportHeight + margin;
  }

  // ---------------------------------------------------------------------------
  // getViewportProgress
  // ---------------------------------------------------------------------------

  /// Returns how far [key]'s widget has progressed through the viewport as a
  /// value between 0.0 and 1.0.
  ///
  /// - 0.0 → the widget's top edge has just entered the bottom of the viewport.
  /// - 0.5 → the widget is centred in the viewport.
  /// - 1.0 → the widget's bottom edge has just left the top of the viewport.
  ///
  /// Returns `null` if the key is not mounted or not in the viewport.
  static double? getViewportProgress(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;

    final position = box.localToGlobal(Offset.zero);
    final size = box.size;
    final viewportHeight =
        MediaQuery.maybeOf(context)?.size.height ?? 800.0;

    // Total distance the widget travels from "bottom of viewport" to
    // "top of viewport".
    final totalTravel = viewportHeight + size.height;
    if (totalTravel <= 0) return null;

    // Distance already travelled: when the widget's top is at the bottom of
    // the viewport, travelled == 0.
    final travelled = viewportHeight - position.dy;

    return (travelled / totalTravel).clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------------
  // getSectionProgress
  // ---------------------------------------------------------------------------

  /// Returns a normalised progress value (0.0–1.0) indicating how far a
  /// section has been scrolled through.
  ///
  /// - 0.0 → the section's top aligns with the current scroll offset.
  /// - 1.0 → the section's bottom aligns with the current scroll offset.
  ///
  /// [controller] must have at least one attached scroll position.
  ///
  /// This is a pure arithmetic helper that does not query render objects, so it
  /// can be called cheaply inside scroll listeners.
  static double getSectionProgress(
    ScrollController controller,
    double sectionTop,
    double sectionHeight,
  ) {
    if (!controller.hasClients || sectionHeight <= 0) return 0.0;

    final scrollOffset = controller.offset;
    final progress = (scrollOffset - sectionTop) / sectionHeight;

    return progress.clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------------
  // Convenience: combined elastic + snap physics
  // ---------------------------------------------------------------------------

  /// Builds a combined [ScrollPhysics] chain suitable for a full-page
  /// portfolio layout.  Import `scroll_physics.dart` to use the custom physics
  /// classes directly for more control.
  static ScrollPhysics portfolioPhysics() =>
      const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
}
