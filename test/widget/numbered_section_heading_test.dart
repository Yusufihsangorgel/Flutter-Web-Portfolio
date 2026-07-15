import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';

void main() {
  group('NumberedSectionHeading', () {
    testWidgets('renders number text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NumberedSectionHeading(
              number: '01',
              title: 'About',
              accent: Colors.cyan,
            ),
          ),
        ),
      );

      expect(find.text('01'), findsOneWidget);
    });

    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NumberedSectionHeading(
              number: '02',
              title: 'Experience',
              accent: Colors.cyan,
            ),
          ),
        ),
      );

      expect(find.text('Experience'), findsOneWidget);
    });

    testWidgets('has divider line', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NumberedSectionHeading(
              number: '03',
              title: 'Projects',
              accent: Colors.cyan,
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('chapter-divider')), findsOneWidget);
    });

    testWidgets('exposes one level-two heading', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: NumberedSectionHeading(
                number: '04',
                title: 'Evidence',
                accent: Colors.cyan,
              ),
            ),
          ),
        );

        final data = tester
            .getSemantics(find.bySemanticsLabel('Evidence'))
            .getSemanticsData();
        expect(data.flagsCollection.isHeader, isTrue);
        expect(data.headingLevel, 2);
        expect(find.bySemanticsLabel('04.'), findsNothing);
      } finally {
        semantics.dispose();
      }
    });
  });
}
