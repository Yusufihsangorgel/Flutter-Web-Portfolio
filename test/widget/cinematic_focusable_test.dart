import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';

Widget _buildSubject(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CinematicFocusable', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          CinematicFocusable(onTap: () {}, child: const Text('Hello')),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('onTap callback fires on tap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _buildSubject(
          CinematicFocusable(
            onTap: () => tapped = true,
            child: const Text('Tap me'),
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
        _buildSubject(
          Center(
            child: CinematicFocusable(
              onTap: () {},
              onHoverChanged: (hovered) => lastHoverState = hovered,
              child: const SizedBox(width: 200, height: 200),
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
        _buildSubject(
          CinematicFocusable(
            onTap: () => activated = true,
            child: const Text('Focus me'),
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
        _buildSubject(
          CinematicFocusable(
            onTap: () => activated = true,
            child: const Text('Focus me'),
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
        _buildSubject(
          CinematicFocusable(
            onTap: () {},
            borderRadius: BorderRadius.circular(16),
            child: const Text('Rounded'),
          ),
        ),
      );

      expect(find.text('Rounded'), findsOneWidget);
    });

    testWidgets('publishes one authoritative button name', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _buildSubject(
            CinematicFocusable(
              onTap: () {},
              semanticLabel: 'Launch system',
              child: const Text('VISIBLE LABEL'),
            ),
          ),
        );

        expect(find.bySemanticsLabel('Launch system'), findsOneWidget);
        expect(
          tester.getSemantics(find.bySemanticsLabel('Launch system')),
          matchesSemantics(
            label: 'Launch system',
            isButton: true,
            isFocusable: true,
            hasTapAction: true,
          ),
        );
        expect(find.bySemanticsLabel('VISIBLE LABEL'), findsNothing);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('can expose a selected link role', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _buildSubject(
            CinematicFocusable(
              onTap: () {},
              semanticLabel: 'Open live system',
              semanticRole: CinematicControlRole.link,
              selected: true,
              child: const Icon(Icons.open_in_new),
            ),
          ),
        );

        expect(
          tester.getSemantics(find.bySemanticsLabel('Open live system')),
          matchesSemantics(
            label: 'Open live system',
            isLink: true,
            hasSelectedState: true,
            isSelected: true,
            isFocusable: true,
            hasTapAction: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
    });
  });
}
