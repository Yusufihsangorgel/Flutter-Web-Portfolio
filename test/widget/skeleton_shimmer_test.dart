import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/widgets/skeleton_shimmer.dart';

void main() {
  group('SkeletonShimmer', () {
    testWidgets('renders with given dimensions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonShimmer(width: 200, height: 40),
          ),
        ),
      );
      expect(find.byType(SkeletonShimmer), findsOneWidget);
    });

    testWidgets('uses custom borderRadius', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonShimmer(width: 100, height: 20, borderRadius: 16.0),
          ),
        ),
      );
      expect(find.byType(SkeletonShimmer), findsOneWidget);
    });

    testWidgets('animation runs continuously', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonShimmer(width: 100, height: 20),
          ),
        ),
      );
      // Pump a few frames to verify animation does not crash
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SkeletonShimmer), findsOneWidget);
    });

    testWidgets('default borderRadius is 8.0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonShimmer(width: 150, height: 30),
          ),
        ),
      );

      final widget = tester.widget<SkeletonShimmer>(
        find.byType(SkeletonShimmer),
      );
      expect(widget.borderRadius, 8.0);
    });

    testWidgets('stores width and height correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonShimmer(width: 250, height: 50),
          ),
        ),
      );

      final widget = tester.widget<SkeletonShimmer>(
        find.byType(SkeletonShimmer),
      );
      expect(widget.width, 250);
      expect(widget.height, 50);
    });
  });
}
