import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';

void main() {
  group('ScrollFadeIn', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScrollFadeIn(child: Text('Hello'))),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('starts with zero opacity', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScrollFadeIn(child: Text('Fade me'))),
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

    testWidgets('reveals after a programmatic jump settles layout', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: controller,
              child: const Column(
                children: [
                  SizedBox(height: 900),
                  ScrollFadeIn(
                    child: SizedBox(height: 200, child: Text('Target')),
                  ),
                  SizedBox(height: 900),
                ],
              ),
            ),
          ),
        ),
      );

      final targetOpacity = find.ancestor(
        of: find.text('Target'),
        matching: find.byType(Opacity),
      );
      expect(tester.widget<Opacity>(targetOpacity).opacity, 0);

      controller.jumpTo(850);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.widget<Opacity>(targetOpacity).opacity, 1);
    });
  });
}
