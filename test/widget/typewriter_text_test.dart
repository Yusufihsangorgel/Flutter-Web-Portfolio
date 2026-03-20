import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/widgets/typewriter_text.dart';

void main() {
  group('TypewriterText', () {
    testWidgets('renders the widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypewriterText(
              text: 'Hello',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );

      expect(find.byType(TypewriterText), findsOneWidget);

      // Dispose widget tree and flush pending timers
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('shows cursor character initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypewriterText(
              text: 'Hello',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );

      // After first pump the cursor should be visible
      await tester.pump();

      // The cursor character "|" should appear somewhere in the text
      expect(find.textContaining('|'), findsOneWidget);

      // Dispose widget tree and flush pending timers
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('eventually shows full text after enough pumps',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypewriterText(
              text: 'Hi',
              style: TextStyle(fontSize: 16),
              minCharDelay: Duration(milliseconds: 10),
              maxCharDelay: Duration(milliseconds: 10),
            ),
          ),
        ),
      );

      // Pump enough time for all characters to appear plus blink cycles
      // 2 chars * 10ms each + 6 blinks * 400ms = ~2.5s
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.textContaining('Hi'), findsOneWidget);

      // Dispose widget tree and flush pending timers
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
