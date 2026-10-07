import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/widgets/navigation_overlay.dart';
import 'package:flutter_web_portfolio/app/widgets/portfolio_link.dart';

import '../helpers/narrative_fixture.dart';
import '../support/fake_language_repository.dart';

Widget _buildSubject(AppScrollController scroll, LanguageCubit language) =>
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: scroll),
        BlocProvider.value(value: language),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => NavigationOverlay.show(context),
              child: const Text('Open navigation'),
            ),
          ),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppScrollController scroll;
  late LanguageCubit language;

  setUp(() async {
    scroll = AppScrollController(narrative: loadNarrativeFixture());
    language = LanguageCubit(languageRepository: FakeLanguageRepository());
    await language.initialize();
    addTearDown(() async {
      await language.close();
      await scroll.close();
    });
  });

  testWidgets('opens, exposes section links, and closes', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_buildSubject(scroll, language));
    await tester.tap(find.text('Open navigation'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationOverlay), findsOneWidget);
    expect(
      find.byType(PortfolioLink),
      findsNWidgets(scroll.sectionIds.length - 1),
    );
    final section = scroll.sectionIds.firstWhere((id) => id != 'home');
    final label = '${section[0].toUpperCase()}${section.substring(1)}';
    final link = tester.getSemantics(find.bySemanticsLabel(label));
    expect(link.getSemanticsData().flagsCollection.isLink, isTrue);
    expect(link.getSemanticsData().linkUrl.toString(), startsWith('#/'));

    // Browsers join label and tooltip, so one of them must carry the name.
    final close = tester
        .getSemantics(find.bySemanticsLabel('Close'))
        .getSemanticsData();
    expect(close.label, 'Close');
    expect(close.tooltip, isEmpty);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationOverlay), findsNothing);
    semantics.dispose();
  });
}
