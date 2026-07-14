import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/controllers/cursor_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/magnetic_button.dart';

void main() {
  group('MagneticButton', () {
    testWidgets('renders child widget', (tester) async {
      final cursor = CursorController();
      addTearDown(cursor.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: cursor,
          child: MaterialApp(
            home: Scaffold(
              body: MagneticButton(onTap: () {}, child: const Text('Magnetic')),
            ),
          ),
        ),
      );

      expect(find.text('Magnetic'), findsOneWidget);
    });

    testWidgets('onTap callback fires on tap', (tester) async {
      var tapped = false;
      final cursor = CursorController();
      addTearDown(cursor.close);

      await tester.pumpWidget(
        BlocProvider.value(
          value: cursor,
          child: MaterialApp(
            home: Scaffold(
              body: MagneticButton(
                onTap: () => tapped = true,
                child: const Text('Tap Me'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
