import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

/// A horizontal scrolling showcase that intercepts vertical scroll gestures
/// and converts them to horizontal movement.
///
/// Ideal for project galleries, image showcases, or any content that benefits
/// from a horizontal browsing experience within a vertical page.
///
/// Pinned during scroll with visual progress indicator.
class HorizontalScrollShowcase extends StatefulWidget {
  const HorizontalScrollShowcase({
    super.key,
    required this.children,
    this.itemWidth = 380,
    this.itemSpacing = 24,
    this.height = 500,
    this.showProgress = true,
    this.snapToItem = true,
  });

  final List<Widget> children;
  final double itemWidth;
  final double itemSpacing;
  final double height;
  final bool showProgress;
  final bool snapToItem;

  @override
  State<HorizontalScrollShowcase> createState() =>
      _HorizontalScrollShowcaseState();
}

class _HorizontalScrollShowcaseState extends State<HorizontalScrollShowcase> {
  late ScrollController _scrollController;
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(_updateProgress);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    setState(() {
      _scrollProgress = max > 0 ? (_scrollController.offset / max).clamp(0.0, 1.0) : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                final newOffset = _scrollController.offset + event.scrollDelta.dy;
                _scrollController.jumpTo(
                  newOffset.clamp(
                    0.0,
                    _scrollController.position.maxScrollExtent,
                  ),
                );
              }
            },
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: widget.snapToItem
                    ? _SnapScrollPhysics(
                        itemWidth: widget.itemWidth + widget.itemSpacing,
                      )
                    : const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: (MediaQuery.sizeOf(context).width - widget.itemWidth) / 2,
                ),
                itemCount: widget.children.length,
                separatorBuilder: (_, __) => SizedBox(width: widget.itemSpacing),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: widget.itemWidth,
                    child: _ParallaxItem(
                      scrollController: _scrollController,
                      itemWidth: widget.itemWidth,
                      itemSpacing: widget.itemSpacing,
                      index: index,
                      child: widget.children[index],
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        if (widget.showProgress) ...[
          const SizedBox(height: 24),
          _ProgressIndicator(progress: _scrollProgress),
        ],
      ],
    );
  }
}

/// Applies a subtle parallax + scale effect to items as they scroll.
class _ParallaxItem extends StatelessWidget {
  const _ParallaxItem({
    required this.scrollController,
    required this.itemWidth,
    required this.itemSpacing,
    required this.index,
    required this.child,
  });

  final ScrollController scrollController;
  final double itemWidth;
  final double itemSpacing;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        if (!scrollController.hasClients) return child!;

        final screenWidth = MediaQuery.sizeOf(context).width;
        final itemCenter = index * (itemWidth + itemSpacing) + itemWidth / 2;
        final viewportCenter = scrollController.offset + screenWidth / 2;
        final distance = (itemCenter - viewportCenter).abs();
        final maxDistance = screenWidth / 2 + itemWidth;
        final normalizedDistance = (distance / maxDistance).clamp(0.0, 1.0);

        final scale = 1.0 - normalizedDistance * 0.08;
        final opacity = 1.0 - normalizedDistance * 0.3;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity.clamp(0.4, 1.0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 120,
        height: 3,
        child: Stack(
          children: [
            // Track
            Container(
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Thumb
            FractionallySizedBox(
              widthFactor: 0.3,
              alignment: Alignment.lerp(
                Alignment.centerLeft,
                Alignment.centerRight,
                progress,
              )!,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnapScrollPhysics extends ScrollPhysics {
  const _SnapScrollPhysics({
    required this.itemWidth,
    super.parent,
  });

  final double itemWidth;

  @override
  _SnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _SnapScrollPhysics(
      itemWidth: itemWidth,
      parent: buildParent(ancestor),
    );
  }

  double _getTargetPixels(ScrollMetrics position, Tolerance tolerance, double velocity) {
    final page = position.pixels / itemWidth;
    if (velocity < -tolerance.velocity) {
      return page.floor() * itemWidth;
    } else if (velocity > tolerance.velocity) {
      return page.ceil() * itemWidth;
    }
    return page.round() * itemWidth;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final target = _getTargetPixels(position, toleranceFor(position), velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: toleranceFor(position),
      );
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}
