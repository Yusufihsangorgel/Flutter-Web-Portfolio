import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/features/engineering_lab/presentation/engineering_lab.dart';

void main() {
  testWidgets('renders truthful runtime and implementation sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EngineeringLab(
            localeCount: 7,
            currentLocale: 'en',
            activeSection: 'projects',
          ),
        ),
      ),
    );

    expect(find.text('ENGINEERING LAB / LIVE'), findsOneWidget);
    expect(find.text('Flutter scheduler telemetry'), findsOneWidget);
    expect(find.text('What is actually running'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(
      find.text('HTML boot/recovery surface · product UI in Flutter'),
      findsOneWidget,
    );
    expect(find.text('#/projects'), findsOneWidget);
  });

  testWidgets('stays scrollable on a narrow mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EngineeringLab(localeCount: 7, currentLocale: 'en'),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
