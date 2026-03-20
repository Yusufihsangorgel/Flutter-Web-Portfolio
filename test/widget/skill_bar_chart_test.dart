import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/widgets/skill_bar_chart.dart';

void main() {
  group('SkillBarChart', () {
    testWidgets('renders with given categories', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 1.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillBarChart(
              categories: const ['Mobile', 'Backend', 'DevOps'],
              proficiencies: const [0.9, 0.7, 0.5],
              accent: Colors.blue,
              animation: controller,
            ),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Backend'), findsOneWidget);
      expect(find.text('DevOps'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('shows percentage labels', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 1.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillBarChart(
              categories: const ['Flutter'],
              proficiencies: const [0.9],
              accent: Colors.blue,
              animation: controller,
            ),
          ),
        ),
      );

      // At full animation, 0.9 * 100 = 90%
      expect(find.text('90%'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('has CustomPaint', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        value: 1.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillBarChart(
              categories: const ['Mobile'],
              proficiencies: const [0.8],
              accent: Colors.blue,
              animation: controller,
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);

      controller.dispose();
    });
  });
}
