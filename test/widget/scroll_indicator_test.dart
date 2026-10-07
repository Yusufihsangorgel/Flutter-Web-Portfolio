import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_indicator.dart';

void main() {
  group('ScrollIndicator', () {
    testWidgets('honors its entrance delay before completing the fade', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScrollIndicator(delay: Duration(milliseconds: 300)),
          ),
        ),
      );

      Opacity opacity() => tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity().opacity, 0);

      await tester.pump(const Duration(milliseconds: 299));
      expect(opacity().opacity, 0);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(seconds: 2));
      expect(opacity().opacity, 1);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('becomes static and semantic-free for reduced motion', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(body: ScrollIndicator(delay: Duration.zero)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1));

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      final initialDot = tester.widget<Positioned>(find.byType(Positioned));
      expect(opacity.opacity, 1);
      expect(initialDot.top, 20);
      expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      final settledDot = tester.widget<Positioned>(find.byType(Positioned));
      expect(settledDot.top, initialDot.top);

      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    });

    testWidgets('pauses its repeating animation while outside the viewport', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 300));
      final controller = ScrollController();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
        await tester.binding.setSurfaceSize(null);
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: controller,
              child: const Column(
                children: [
                  SizedBox(height: 700),
                  SizedBox(
                    height: 80,
                    child: ScrollIndicator(delay: Duration.zero),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final initialTop = tester.widget<Positioned>(find.byType(Positioned)).top;
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester.widget<Positioned>(find.byType(Positioned)).top,
        initialTop,
      );

      controller.jumpTo(450);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester.widget<Positioned>(find.byType(Positioned)).top,
        isNot(initialTop),
      );
    });
  });
}
