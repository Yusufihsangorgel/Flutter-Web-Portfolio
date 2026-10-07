import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/packages/packages_section.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';
import '../helpers/narrative_fixture.dart';
import '../helpers/portfolio_fixture.dart';

final class _PackagesLanguageRepository implements LanguageRepository {
  _PackagesLanguageRepository(this._packagesCopy);

  final Map<String, String> _packagesCopy;

  @override
  Set<String> get supportedLanguages => const {'en'};

  @override
  Future<String> getSelectedLanguage() async => 'en';

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async => {
    'nav': {'packages': 'Packages'},
    'packages_section': _packagesCopy,
  };

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {}
}

void main() {
  late LanguageCubit language;

  Future<void> useLanguage([Map<String, String> copy = const {}]) async {
    language = LanguageCubit(
      languageRepository: _PackagesLanguageRepository(copy),
    );
    await language.initialize();
    addTearDown(language.close);
  }

  group('PackagesSection maturity', () {
    setUp(useLanguage);

    testWidgets('shows each level as "Maturity n of 5"', (tester) async {
      await _pumpSection(tester, language);

      expect(find.text('Maturity 3 of 5'), findsOneWidget);
      expect(find.text('Maturity 5 of 5'), findsOneWidget);
      expect(_rowLabelContaining('Maturity 3 of 5'), findsOneWidget);
      expect(_rowLabelContaining('Maturity 5 of 5'), findsOneWidget);
    });

    testWidgets('never renders a letter level', (tester) async {
      await _pumpSection(tester, language);

      final letterLevel = RegExp(r'\bL[1-5]\b');
      final visibleText = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '');

      expect(visibleText.where(letterLevel.hasMatch), isEmpty);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is AccessibleAction &&
              letterLevel.hasMatch(widget.semanticLabel ?? ''),
        ),
        findsNothing,
      );
    });

    testWidgets('omits the label for a package without a level', (
      tester,
    ) async {
      await _pumpSection(
        tester,
        language,
        mutate: (json) {
          final packages = json['packages']! as List<dynamic>;
          (packages[1] as Map<String, dynamic>).remove('maturity_level');
        },
      );

      expect(find.text('Maturity 3 of 5'), findsOneWidget);
      expect(find.text('Maturity 5 of 5'), findsNothing);
    });
  });

  group('PackagesSection localized wording', () {
    setUp(() => useLanguage({'maturity_level': 'Reife {level} von {max}'}));

    testWidgets('takes the maturity wording from the language catalog', (
      tester,
    ) async {
      await _pumpSection(tester, language);

      expect(find.text('Reife 3 von 5'), findsOneWidget);
      expect(find.text('Maturity 3 of 5'), findsNothing);
    });
  });

  group('PackagesSection groups', () {
    setUp(useLanguage);

    testWidgets('renders every package under its category heading', (
      tester,
    ) async {
      await _pumpSection(tester, language);

      expect(find.text('Server-side Dart'), findsOneWidget);
      expect(find.text('Flutter UI'), findsOneWidget);
      expect(find.text('example_task_queue'), findsOneWidget);
      expect(find.text('example_ui_kit'), findsOneWidget);
    });
  });
}

Finder _rowLabelContaining(String text) => find.byWidgetPredicate(
  (widget) =>
      widget is AccessibleAction &&
      widget.semanticRole == ActionSemanticRole.link &&
      widget.semanticLabel?.contains(text) == true,
);

Future<void> _pumpSection(
  WidgetTester tester,
  LanguageCubit language, {
  void Function(Map<String, dynamic> json)? mutate,
}) async {
  final portfolio = loadPortfolioFixture(mutate: mutate);
  final scroll = AppScrollController(
    narrative: loadNarrativeFixture(activeSections: portfolio.activeSections),
  );
  final scene = SceneDirector(scrollController: scroll);
  addTearDown(() async {
    await scene.close();
    await scroll.close();
  });

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PortfolioDocument>.value(value: portfolio),
        RepositoryProvider.value(value: scroll.narrative),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: language),
          BlocProvider.value(value: scroll),
          BlocProvider.value(value: scene),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: PackagesSection())),
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}
