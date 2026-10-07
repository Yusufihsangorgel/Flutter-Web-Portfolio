import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart'
    hide PortfolioLink;
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/packages/packages_section.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';
import 'package:flutter_web_portfolio/app/widgets/portfolio_link.dart';

import '../helpers/narrative_fixture.dart';
import '../helpers/portfolio_fixture.dart';
import '../support/fake_language_repository.dart';

late LanguageCubit _language;

Future<void> _useLanguage([Map<String, String> copy = const {}]) async {
  _language = LanguageCubit(
    languageRepository: FakeLanguageRepository(
      documents: {
        'en': {
          'nav': {'packages': 'Packages'},
          'packages_section': {
            'title': 'Published Packages',
            'subtitle': '{count} packages, {perfect} perfect scores.',
            'subtitle_no_perfect': '{count} packages with measured claims.',
            'pub_points': 'pub points',
            'open_package': 'Open package',
            'maturity_level': 'Maturity {level} of {max}',
            'roadmap': 'Roadmap',
            'status_done': 'shipped',
            'status_doing': 'in progress',
            'status_next': 'next',
            'status_waiting': 'waiting',
            'category_native_ffi': 'Native & FFI',
            'category_ai_llm': 'AI & LLM',
            'category_server': 'Server-side Dart',
            'category_flutter_ui': 'Flutter UI',
            'category_dev_tool': 'Developer tools',
            'show_all': 'Show all {count}',
            'show_less': 'Show fewer',
            ...copy,
          },
        },
      },
    ),
  );
  await _language.initialize();
  addTearDown(_language.close);
}

void main() {
  _registerPackageSummaryTests();
  _registerPackageCurationTests();
  _registerPackageCategoryTests();
  _registerPackageSemanticsTests();
}

void _registerPackageSummaryTests() {
  group('PackagesSection summary', () {
    setUp(_useLanguage);

    testWidgets('does not render maturity badges', (tester) async {
      await _pumpSection(tester, _language);

      expect(find.textContaining('Maturity'), findsNothing);
      expect(find.textContaining(RegExp(r'\bL[1-5]\b')), findsNothing);
    });

    testWidgets('omits the perfect-score clause when its count is zero', (
      tester,
    ) async {
      await _pumpSection(
        tester,
        _language,
        mutate: (json) {
          for (final package in json['packages']! as List<dynamic>) {
            (package as Map<String, dynamic>)['pub_points'] = 100;
          }
        },
      );

      expect(find.text('2 packages with measured claims.'), findsOneWidget);
      expect(find.textContaining('perfect scores'), findsNothing);
    });
  });
}

void _registerPackageCurationTests() {
  group('PackagesSection curation', () {
    setUp(_useLanguage);
    testWidgets(
      'shows featured first and reveals the remainder from keyboard',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await _pumpSection(tester, _language);

          expect(find.text('example_task_queue'), findsOneWidget);
          expect(find.text('example_ui_kit'), findsNothing);
          expect(_disclosure(expanded: false), findsOneWidget);
          expect(find.text('Show all 2'), findsOneWidget);
          _expectDisclosureState(tester, 'Show all 2', false);

          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();

          expect(find.text('example_ui_kit'), findsOneWidget);
          expect(_disclosure(expanded: true), findsOneWidget);
          expect(find.text('Show fewer'), findsOneWidget);
          _expectDisclosureState(tester, 'Show fewer', true);
          expect(find.byType(PortfolioLink), findsNWidgets(2));
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets('keeps the full list present when no package is featured', (
      tester,
    ) async {
      await _pumpSection(
        tester,
        _language,
        mutate: (json) {
          for (final package in json['packages']! as List<dynamic>) {
            (package as Map<String, dynamic>)['featured'] = false;
          }
        },
      );

      expect(find.text('example_task_queue'), findsOneWidget);
      expect(find.text('example_ui_kit'), findsOneWidget);
      expect(_disclosure(expanded: false), findsNothing);
    });
  });
}

void _registerPackageCategoryTests() {
  group('PackagesSection package categories', () {
    setUp(_useLanguage);

    testWidgets('renders every valid category with localized headings', (
      tester,
    ) async {
      await _pumpSection(tester, _language, mutate: _useEveryCategory);

      expect(find.text('Native & FFI'), findsOneWidget);
      expect(find.text('AI & LLM'), findsOneWidget);
      expect(find.text('Server-side Dart'), findsOneWidget);
      expect(find.text('Flutter UI'), findsOneWidget);
      expect(find.text('Developer tools'), findsOneWidget);
    });
  });
}

void _registerPackageSemanticsTests() {
  group('PackagesSection semantics', () {
    setUp(_useLanguage);

    testWidgets('keeps visible package details in the accessible link name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await _pumpSection(
          tester,
          _language,
          mutate: (json) {
            final entry =
                (json['packages']! as List<dynamic>).first
                    as Map<String, dynamic>;
            entry['proof'] = 'Measured package result';
            entry['roadmap'] = [
              {'title': 'Runnable example', 'status': 'done'},
            ];
          },
        );
        final node = tester
            .getSemantics(
              find.bySemanticsLabel(
                RegExp(r'Open package: example_task_queue'),
              ),
            )
            .getSemanticsData();
        expect(node.flagsCollection.isLink, isTrue);
        expect(node.linkUrl, loadPortfolioFixture().packages.first.url);
        for (final text in [
          loadPortfolioFixture().packages.first.description,
          '0.1.0',
          '160/160 pub points',
          'Measured package result',
          'Roadmap',
          'Runnable example',
          'shipped',
        ]) {
          expect(node.label, contains(text));
        }
      } finally {
        handle.dispose();
      }
    });
  });
}

Finder _disclosure({required bool expanded}) => find.byWidgetPredicate(
  (widget) =>
      widget is AccessibleAction &&
      widget.semanticRole == ActionSemanticRole.button &&
      widget.expanded == expanded,
);

void _useEveryCategory(Map<String, dynamic> json) {
  const categories = [
    'native-ffi',
    'ai-llm',
    'server',
    'flutter-ui',
    'dev-tool',
  ];
  final packages = json['packages']! as List<dynamic>;
  final template = packages.first as Map<String, dynamic>;
  packages
    ..clear()
    ..addAll([
      for (var index = 0; index < categories.length; index++)
        {
          ...template,
          'id': 'package-$index',
          'name': 'package-$index',
          'url': 'https://example.com/packages/$index',
          'repository': 'https://example.com/repositories/$index',
          'category': categories[index],
          'featured': false,
        },
    ]);
}

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

void _expectDisclosureState(WidgetTester tester, String label, bool expanded) {
  final node = tester
      .getSemantics(find.bySemanticsLabel(label))
      .getSemanticsData();
  expect(node.flagsCollection.isButton, isTrue);
  expect(
    node.flagsCollection.isExpanded,
    expanded ? Tristate.isTrue : Tristate.isFalse,
  );
}
