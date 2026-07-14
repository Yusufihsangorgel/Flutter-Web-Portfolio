import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/widgets/animated_stats.dart';

void main() {
  testWidgets('shows the final value immediately for reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: AnimatedStatCard(
              value: 12,
              suffix: '+',
              label: 'Shipped projects',
            ),
          ),
        ),
      ),
    );

    expect(find.text('12+', findRichText: true), findsOneWidget);
    expect(find.bySemanticsLabel('12+ Shipped projects'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
