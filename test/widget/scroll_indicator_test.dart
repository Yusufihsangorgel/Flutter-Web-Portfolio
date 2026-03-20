import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_indicator.dart';

void main() {
  group('ScrollIndicator', () {
    testWidgets('renders widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScrollIndicator(delay: Duration.zero),
          ),
        ),
      );

      expect(find.byType(ScrollIndicator), findsOneWidget);

      // Remove the widget tree so repeating animation controllers are disposed,
      // then pump to flush any pending timers left by Future.delayed and repeat().
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('has Container elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScrollIndicator(delay: Duration.zero),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);

      // Dispose the widget tree and flush all pending timers
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
