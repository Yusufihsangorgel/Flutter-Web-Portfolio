import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';

void main() {
  group('CinematicFocusable', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CinematicFocusable(
              onTap: () {},
              child: const Text('Hello'),
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('onTap callback fires on tap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CinematicFocusable(
              onTap: () => tapped = true,
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('onHoverChanged callback is wired up', (tester) async {
      // FocusableActionDetector.onShowHoverHighlight needs the mouse tracker
      // pipeline which requires RendererBinding initialization and specific
      // pointer event ordering. We verify the callback is correctly plumbed
      // by confirming the FocusableActionDetector is present and configured.
      bool? lastHoverState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CinematicFocusable(
                onTap: () {},
                onHoverChanged: (hovered) => lastHoverState = hovered,
                child: const SizedBox(width: 200, height: 200),
              ),
            ),
          ),
        ),
      );

      // Verify FocusableActionDetector is in the tree
      final detector = tester.widget<FocusableActionDetector>(
        find.byType(FocusableActionDetector),
      );
      expect(detector, isNotNull);
      expect(detector.onShowHoverHighlight, isNotNull);

      // Directly invoke the callback to verify it routes to onHoverChanged
      detector.onShowHoverHighlight!(true);
      expect(lastHoverState, isTrue);

      detector.onShowHoverHighlight!(false);
      expect(lastHoverState, isFalse);
    });

    testWidgets('keyboard Enter triggers onTap', (tester) async {
      var activated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CinematicFocusable(
              onTap: () => activated = true,
              child: const Text('Focus me'),
            ),
          ),
        ),
      );

      // Focus the widget by tabbing into it
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Press Enter to activate
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(activated, isTrue);
    });

    testWidgets('keyboard Space triggers onTap', (tester) async {
      var activated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CinematicFocusable(
              onTap: () => activated = true,
              child: const Text('Focus me'),
            ),
          ),
        ),
      );

      // Focus the widget by tabbing into it
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Press Space to activate
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(activated, isTrue);
    });

    testWidgets('renders with custom borderRadius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CinematicFocusable(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: const Text('Rounded'),
            ),
          ),
        ),
      );

      expect(find.text('Rounded'), findsOneWidget);
    });
  });
}
