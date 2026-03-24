import 'dart:math' as math;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// 1. MorphPageTransition
// ---------------------------------------------------------------------------

/// A shared-element-style morph: a "source" widget's bounds morph into the
/// full-page destination.  Wrap the tapped element in a [MorphPageTransition]
/// builder to get a [Rect] that interpolates from source to full-screen.
///
/// Usage:
/// ```dart
/// Navigator.of(context).push(
///   MorphPageTransition(
///     sourceRect: _getSourceRect(),
///     page: const DetailPage(),
///   ),
/// );
/// ```
class MorphPageTransition extends PageRouteBuilder {
  MorphPageTransition({
    required this.sourceRect,
    required Widget page,
    this.borderRadius = 16.0,
    Duration duration = const Duration(milliseconds: 500),
    Duration reverseDuration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOutCubicEmphasized,
    super.settings,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          transitionsBuilder: (context, animation, _, child) {
            final curved = CurvedAnimation(parent: animation, curve: curve);
            final screenSize = MediaQuery.sizeOf(context);
            final fullRect =
                Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);

            return AnimatedBuilder(
              animation: curved,
              builder: (_, __) {
                final rect =
                    Rect.lerp(sourceRect, fullRect, curved.value) ?? fullRect;
                final radius = BorderRadius.circular(
                  borderRadius * (1 - curved.value),
                );
                return Stack(
                  children: [
                    Positioned(
                      left: rect.left,
                      top: rect.top,
                      width: rect.width,
                      height: rect.height,
                      child: ClipRRect(
                        borderRadius: radius,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                            width: screenSize.width,
                            height: screenSize.height,
                            child: Opacity(
                              opacity: curved.value.clamp(0.0, 1.0),
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );

  /// The bounding rectangle of the source widget in global coordinates.
  final Rect sourceRect;

  /// The border radius applied to the morph container at t=0.
  final double borderRadius;
}

// ---------------------------------------------------------------------------
// 2. CurtainPageTransition
// ---------------------------------------------------------------------------

/// Two halves of the old page slide apart like curtains, revealing the new
/// page underneath.
class CurtainPageTransition extends PageRouteBuilder {
  CurtainPageTransition({
    required Widget page,
    this.direction = Axis.horizontal,
    Duration duration = const Duration(milliseconds: 600),
    Duration reverseDuration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOutCubic,
    super.settings,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          opaque: false,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: curve);

            return Stack(
              children: [
                // Incoming page underneath
                FadeTransition(
                  opacity: curved,
                  child: child,
                ),

                // Outgoing curtains on top
                if (animation.status != AnimationStatus.completed)
                  AnimatedBuilder(
                    animation: curved,
                    builder: (_, __) => _CurtainOverlay(
                      progress: curved.value,
                      axis: direction,
                    ),
                  ),
              ],
            );
          },
        );

  /// Whether curtains split horizontally (left/right) or vertically
  /// (top/bottom).
  final Axis direction;
}

class _CurtainOverlay extends StatelessWidget {
  const _CurtainOverlay({required this.progress, required this.axis});

  final double progress;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final color = Theme.of(context).scaffoldBackgroundColor;

    if (axis == Axis.horizontal) {
      final halfWidth = size.width / 2;
      return Stack(
        children: [
          // Left curtain
          Positioned(
            left: -halfWidth * progress,
            top: 0,
            width: halfWidth,
            height: size.height,
            child: ColoredBox(color: color),
          ),
          // Right curtain
          Positioned(
            right: -halfWidth * progress,
            top: 0,
            width: halfWidth,
            height: size.height,
            child: ColoredBox(color: color),
          ),
        ],
      );
    } else {
      final halfHeight = size.height / 2;
      return Stack(
        children: [
          Positioned(
            left: 0,
            top: -halfHeight * progress,
            width: size.width,
            height: halfHeight,
            child: ColoredBox(color: color),
          ),
          Positioned(
            left: 0,
            bottom: -halfHeight * progress,
            width: size.width,
            height: halfHeight,
            child: ColoredBox(color: color),
          ),
        ],
      );
    }
  }
}

// ---------------------------------------------------------------------------
// 3. CircularRevealPageTransition
// ---------------------------------------------------------------------------

/// Circular clip path expands from a given origin point (e.g. the tap
/// position) to reveal the new page.
///
/// ```dart
/// Navigator.of(context).push(
///   CircularRevealPageTransition(
///     page: const NextPage(),
///     origin: tapGlobalPosition,
///   ),
/// );
/// ```
class CircularRevealPageTransition extends PageRouteBuilder {
  CircularRevealPageTransition({
    required Widget page,
    this.origin,
    Duration duration = const Duration(milliseconds: 600),
    Duration reverseDuration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOutCubic,
    super.settings,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          opaque: false,
          transitionsBuilder: (context, animation, _, child) {
            final curved = CurvedAnimation(parent: animation, curve: curve);
            final screenSize = MediaQuery.sizeOf(context);
            final center = origin ??
                Offset(screenSize.width / 2, screenSize.height / 2);

            // Maximum radius needed to cover the entire screen from origin.
            final maxRadius = math.sqrt(
              math.max(
                    math.pow(center.dx, 2) +
                        math.pow(center.dy, 2),
                    math.pow(screenSize.width - center.dx, 2) +
                        math.pow(center.dy, 2),
                  )
                  .toDouble(),
            );
            final maxRadius2 = math.sqrt(
              math.max(
                    math.pow(center.dx, 2) +
                        math.pow(screenSize.height - center.dy, 2),
                    math.pow(screenSize.width - center.dx, 2) +
                        math.pow(screenSize.height - center.dy, 2),
                  )
                  .toDouble(),
            );
            final finalRadius = math.max(maxRadius, maxRadius2);

            return AnimatedBuilder(
              animation: curved,
              builder: (_, __) => ClipPath(
                clipper: _CircleClipper(
                  center: center,
                  radius: finalRadius * curved.value,
                ),
                child: child,
              ),
            );
          },
        );

  /// The global position from which the circle expands.  Defaults to screen
  /// center if not provided.
  final Offset? origin;
}

class _CircleClipper extends CustomClipper<Path> {
  _CircleClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(_CircleClipper oldClipper) => radius != oldClipper.radius;
}

// ---------------------------------------------------------------------------
// 4. DiagonalSlidePageTransition
// ---------------------------------------------------------------------------

/// Content slides in diagonally with a subtle rotation.
class DiagonalSlidePageTransition extends PageRouteBuilder {
  DiagonalSlidePageTransition({
    required Widget page,
    this.rotationAngle = 0.03,
    Duration duration = const Duration(milliseconds: 500),
    Duration reverseDuration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOutCubicEmphasized,
    super.settings,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          transitionsBuilder: (context, animation, _, child) {
            final curved = CurvedAnimation(parent: animation, curve: curve);
            final screenSize = MediaQuery.sizeOf(context);

            return AnimatedBuilder(
              animation: curved,
              builder: (_, __) {
                final dx = screenSize.width * (1 - curved.value) * 0.5;
                final dy = screenSize.height * (1 - curved.value) * 0.3;
                final angle = rotationAngle * (1 - curved.value);

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translateByDouble(dx, dy, 0, 1)
                    ..rotateZ(angle),
                  child: Opacity(
                    opacity: curved.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
            );
          },
        );

  /// Maximum rotation in radians at the start of the transition.
  final double rotationAngle;
}

// ---------------------------------------------------------------------------
// 5. PixelDissolvePageTransition
// ---------------------------------------------------------------------------

/// Old page dissolves into a grid of "pixels" that fade out while the new
/// page fades in underneath.
class PixelDissolvePageTransition extends PageRouteBuilder {
  PixelDissolvePageTransition({
    required Widget page,
    this.gridSize = 12,
    Duration duration = const Duration(milliseconds: 700),
    Duration reverseDuration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOut,
    super.settings,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          opaque: false,
          transitionsBuilder: (context, animation, _, child) {
            final curved = CurvedAnimation(parent: animation, curve: curve);

            return Stack(
              children: [
                // Incoming page fades in
                FadeTransition(opacity: curved, child: child),

                // Dissolving overlay
                if (animation.status != AnimationStatus.completed)
                  AnimatedBuilder(
                    animation: curved,
                    builder: (_, __) => CustomPaint(
                      size: MediaQuery.sizeOf(context),
                      painter: _PixelDissolvePainter(
                        progress: curved.value,
                        gridSize: gridSize,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                  ),
              ],
            );
          },
        );

  /// Number of cells per row in the dissolve grid.
  final int gridSize;
}

class _PixelDissolvePainter extends CustomPainter {
  _PixelDissolvePainter({
    required this.progress,
    required this.gridSize,
    required this.color,
  });

  final double progress;
  final int gridSize;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / gridSize;
    final rows = (size.height / cellWidth).ceil();
    final random = math.Random(42); // Fixed seed for deterministic pattern.

    // Pre-compute a random threshold for each cell.  Cells whose threshold
    // is below `progress` have dissolved (are not drawn).
    final paint = Paint()..color = color;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < gridSize; col++) {
        final threshold = random.nextDouble();
        if (threshold >= progress) {
          // This cell is still "alive" -- draw it.
          final opacity = ((1.0 - progress / threshold) * 1.5).clamp(0.0, 1.0);
          paint.color = color.withValues(alpha: opacity);
          canvas.drawRect(
            Rect.fromLTWH(
              col * cellWidth,
              row * cellWidth,
              cellWidth + 0.5, // Slight overlap to avoid sub-pixel gaps.
              cellWidth + 0.5,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PixelDissolvePainter oldDelegate) =>
      progress != oldDelegate.progress;
}

// ---------------------------------------------------------------------------
// Convenience: GetX-compatible custom transition helpers
// ---------------------------------------------------------------------------

/// Provides a [GetPage]-compatible [customTransition] wrapper for any of the
/// page transitions above.
///
/// Example with GetX routing:
/// ```dart
/// GetPage(
///   name: '/detail',
///   page: () => const DetailPage(),
///   customTransition: GetxPageTransition(
///     builder: (page) => CircularRevealPageTransition(page: page),
///   ),
/// );
/// ```
class GetxPageTransition {
  GetxPageTransition({required this.builder});

  /// A function that receives the destination page widget and returns a
  /// [PageRouteBuilder] (one of the transitions defined in this file).
  final PageRouteBuilder Function(Widget page) builder;
}
