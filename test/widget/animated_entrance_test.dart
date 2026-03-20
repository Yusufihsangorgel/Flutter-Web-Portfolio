import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/widgets/animated_entrance.dart';

void main() {
  group('AnimatedEntrance', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedEntrance(
              child: Text('Hello'),
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('starts with zero opacity', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedEntrance(
              child: Text('Fading'),
            ),
          ),
        ),
      );

      // Before any animation frames, opacity should be 0
      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.0);
    });

    testWidgets('fadeInDown factory renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedEntrance.fadeInDown(
              child: Text('Down'),
            ),
          ),
        ),
      );

      expect(find.text('Down'), findsOneWidget);
      expect(find.byType(AnimatedEntrance), findsOneWidget);
    });

    testWidgets('fadeInUp factory renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedEntrance.fadeInUp(
              child: Text('Up'),
            ),
          ),
        ),
      );

      expect(find.text('Up'), findsOneWidget);
      expect(find.byType(AnimatedEntrance), findsOneWidget);
    });

    testWidgets('fadeInLeft factory renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedEntrance.fadeInLeft(
              child: Text('Left'),
            ),
          ),
        ),
      );

      expect(find.text('Left'), findsOneWidget);
      expect(find.byType(AnimatedEntrance), findsOneWidget);
    });

    testWidgets('fadeInRight factory renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedEntrance.fadeInRight(
              child: Text('Right'),
            ),
          ),
        ),
      );

      expect(find.text('Right'), findsOneWidget);
      expect(find.byType(AnimatedEntrance), findsOneWidget);
    });
  });
}
