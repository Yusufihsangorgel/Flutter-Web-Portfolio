import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/widgets/text_scramble.dart';

void main() {
  group('TextScramble', () {
    testWidgets('renders with original text when not hovered', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextScramble(
              text: 'Hello World',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('widget exists', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextScramble(
              text: 'Test',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      );

      expect(find.byType(TextScramble), findsOneWidget);
    });
  });
}
