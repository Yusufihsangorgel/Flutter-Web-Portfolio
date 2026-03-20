import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/widgets/animated_counter.dart';

void main() {
  group('AnimatedCounter', () {
    testWidgets('renders with initial value 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(endValue: 50),
          ),
        ),
      );

      // At frame 0 the animation has not started, value is 0
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('animates to endValue after pump', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(endValue: 42),
          ),
        ),
      );

      // Advance past the default 1200ms animation duration
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('shows integer without decimals', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(endValue: 7),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      // Should display "7", not "7.0"
      expect(find.text('7'), findsOneWidget);
      expect(find.text('7.0'), findsNothing);
    });

    testWidgets('re-triggers on value change', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(endValue: 10),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('10'), findsOneWidget);

      // Rebuild with a new endValue
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(endValue: 20),
          ),
        ),
      );

      // Animation resets to 0 on value change
      expect(find.text('0'), findsOneWidget);

      // Advance past animation
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('20'), findsOneWidget);
    });
  });
}
