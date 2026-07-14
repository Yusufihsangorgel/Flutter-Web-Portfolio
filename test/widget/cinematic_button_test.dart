import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/controllers/sound_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_button.dart';

Widget _buildSubject(Widget child) => BlocProvider(
  create: (_) => SoundController(),
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  group('CinematicButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        _buildSubject(CinematicButton(label: 'Click Me', onTap: () {})),
      );

      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('onTap callback fires', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _buildSubject(
          CinematicButton(label: 'Tap Here', onTap: () => tapped = true),
        ),
      );

      await tester.tap(find.text('Tap Here'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
