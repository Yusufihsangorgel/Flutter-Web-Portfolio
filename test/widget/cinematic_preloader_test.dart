import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_preloader.dart';

void main() {
  setUp(CinematicPreloader.resetSessionFlag);
  tearDown(CinematicPreloader.resetSessionFlag);

  testWidgets('bypasses the intro when reduced motion is enabled', (
    tester,
  ) async {
    var completionCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: CinematicPreloader(
            minimumDuration: const Duration(minutes: 1),
            exitDuration: const Duration(minutes: 1),
            onLoadingComplete: () => completionCount++,
            child: const Text('Portfolio content'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Portfolio content'), findsOneWidget);
    expect(completionCount, 1);

    await tester.pump();
    expect(completionCount, 1);
  });
}
