import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';

Widget _buildSubject(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AccessibleAction', () {
    testWidgets('onTap callback fires on tap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _buildSubject(
          AccessibleAction(
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
      bool? lastHoverState;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 1));
      addTearDown(mouse.removePointer);

      await tester.pumpWidget(
        _buildSubject(
          Center(
            child: AccessibleAction(
              onTap: () {},
              onHoverChanged: (hovered) => lastHoverState = hovered,
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      await mouse.moveTo(tester.getCenter(find.byType(AccessibleAction)));
      await tester.pump();
      expect(lastHoverState, isTrue);

      await mouse.moveTo(const Offset(1, 1));
      await tester.pump();
      expect(lastHoverState, isFalse);
    });

    testWidgets('onFocusChanged callback follows keyboard focus', (
      tester,
    ) async {
      final focusStates = <bool>[];
      await tester.pumpWidget(
        _buildSubject(
          AccessibleAction(
            onTap: () {},
            onFocusChanged: focusStates.add,
            child: const Text('Focus preview'),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(focusStates, contains(true));
    });

    testWidgets('keyboard Enter triggers onTap', (tester) async {
      var activated = false;

      await tester.pumpWidget(
        _buildSubject(
          AccessibleAction(
            onTap: () => activated = true,
            child: const Text('Focus me'),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(activated, isTrue);
    });

    testWidgets('keyboard Space triggers onTap', (tester) async {
      var activated = false;

      await tester.pumpWidget(
        _buildSubject(
          AccessibleAction(
            onTap: () => activated = true,
            child: const Text('Focus me'),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(activated, isTrue);
    });

    testWidgets('publishes one authoritative button name', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _buildSubject(
            AccessibleAction(
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
            hasFocusAction: true,
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
            AccessibleAction(
              onTap: () {},
              semanticLabel: 'Open live system',
              semanticRole: ActionSemanticRole.link,
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
            hasFocusAction: true,
            hasTapAction: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
    });
  });
}
