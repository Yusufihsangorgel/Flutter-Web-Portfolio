import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/controllers/cursor_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/border_light_card.dart';

void main() {
  group('BorderLightCard', () {
    testWidgets('renders child widget', (tester) async {
      final cursor = CursorController();
      addTearDown(cursor.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: cursor,
          child: const MaterialApp(
            home: Scaffold(body: BorderLightCard(child: Text('Card Content'))),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('has CustomPaint for glow effect', (tester) async {
      final cursor = CursorController();
      addTearDown(cursor.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: cursor,
          child: const MaterialApp(
            home: Scaffold(body: BorderLightCard(child: Text('Glow'))),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
