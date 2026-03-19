import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/widgets/footer.dart';

void main() {
  group('PortfolioFooter', () {
    testWidgets('renders copyright text with current year', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PortfolioFooter())),
      );

      final year = DateTime.now().year.toString();
      expect(find.textContaining(year), findsOneWidget);
      expect(find.textContaining('Yusuf Ihsan Gorgel'), findsOneWidget);
    });

    testWidgets('renders social link buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PortfolioFooter())),
      );

      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('LinkedIn'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('renders Flutter logo and built with text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PortfolioFooter())),
      );

      expect(find.byType(FlutterLogo), findsOneWidget);
      expect(find.text('Built with Flutter'), findsOneWidget);
    });
  });
}
