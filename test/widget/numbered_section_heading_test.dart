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
              title: 'About Me',
              accent: Colors.cyan,
            ),
          ),
        ),
      );

      expect(find.text('01.'), findsOneWidget);
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

      // The divider is a Container with height 1 and width 100
      final containers = tester.widgetList<Container>(
        find.byType(Container),
      );

      final hasDivider = containers.any((container) {
        final constraints = container.constraints;
        if (constraints != null) {
          return constraints.maxHeight == 1 && constraints.maxWidth == 100;
        }
        return false;
      });

      expect(hasDivider, isTrue);
    });
  });
}
