import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';

void main() {
  group('ScrollFadeIn', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScrollFadeIn(
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
            body: ScrollFadeIn(
              child: Text('Fade me'),
            ),
          ),
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, equals(0.0));
    });

    testWidgets('accepts custom duration and offset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScrollFadeIn(
              duration: Duration(seconds: 2),
              offset: 100,
              child: Text('Custom'),
            ),
          ),
        ),
      );

      expect(find.text('Custom'), findsOneWidget);
    });
  });
}
