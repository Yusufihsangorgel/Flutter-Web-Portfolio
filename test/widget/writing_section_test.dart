import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart'
    hide PortfolioLink;
import 'package:flutter_web_portfolio/app/domain/repositories/language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/writing/writing_section.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';
import 'package:flutter_web_portfolio/app/widgets/portfolio_link.dart';
import '../helpers/narrative_fixture.dart';
import '../helpers/portfolio_fixture.dart';

final class _WritingLanguageRepository implements LanguageRepository {
  @override
  Set<String> get supportedLanguages => const {'en'};

  @override
  Future<String> getSelectedLanguage() async => 'en';

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async => {
    'nav': {'writing': 'Writing'},
    'writing_section': {
      'title': 'Writing',
      'subtitle': 'Recent articles from every place I publish, newest first.',
      'all_writing': 'All writing',
      'open_article': 'Read article',
      'show_all': 'Show all {count}',
      'show_less': 'Show fewer',
    },
  };

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {}
}

late LanguageCubit _language;

void main() {
  setUp(() async {
    _language = LanguageCubit(languageRepository: _WritingLanguageRepository());
    await _language.initialize();
    addTearDown(_language.close);
  });
  _registerWritingCurationTests();
  _registerWritingFallbackTests();
  _registerWritingVisibilityTests();
  _registerNarrowWritingTests();
}

void _registerWritingCurationTests() {
  group('WritingSection curation', () {
    testWidgets('reveals compact remainder from an expanded keyboard action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      addTearDown(handle.dispose);
      await _pumpWriting(tester, _portfolioWithWriting());

      expect(find.text('Article number 0'), findsOneWidget);
      expect(find.text('Article number 1'), findsOneWidget);
      expect(find.text('Article number 2'), findsNothing);
      expect(_disclosure(expanded: false), findsOneWidget);
      expect(find.text('Show all 7'), findsOneWidget);
      _expectDisclosureState(tester, 'Show all 7', false);
      expect(find.textContaining('2026—08—07'), findsOneWidget);
      expect(find.byType(PortfolioLink), findsNWidgets(4));
      expect(_articleLink('Article number 0', 'Blog'), findsOneWidget);

      for (var index = 0; index < 3; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(find.text('Article number 6'), findsOneWidget);
      expect(_disclosure(expanded: true), findsOneWidget);
      expect(find.text('Show fewer'), findsOneWidget);
      _expectDisclosureState(tester, 'Show fewer', true);
      expect(find.byType(PortfolioLink), findsNWidgets(9));
      expect(tester.takeException(), isNull);
    });
  });
}

void _registerWritingFallbackTests() {
  group('WritingSection fallback list', () {
    testWidgets('keeps the full list present when no article is featured', (
      tester,
    ) async {
      await _pumpWriting(tester, _portfolioWithWriting(withFeatured: false));

      for (var index = 0; index < 7; index++) {
        expect(find.text('Article number $index'), findsOneWidget);
      }
      expect(_disclosure(expanded: false), findsNothing);
    });

    testWidgets('lays out under right-to-left directionality', (tester) async {
      await _pumpWriting(
        tester,
        _portfolioWithWriting(),
        textDirection: TextDirection.rtl,
      );

      expect(find.text('Article number 0'), findsOneWidget);
      expect(find.text('ALL WRITING'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

void _registerWritingVisibilityTests() {
  group('WritingSection visibility', () {
    testWidgets('is absent from the page and navigation when empty', (
      tester,
    ) async {
      final portfolio = loadPortfolioFixture();
      expect(portfolio.writing, isEmpty);
      expect(portfolio.activeSections, isNot(contains('writing')));

      final scroll = await _pumpWriting(tester, portfolio);

      expect(scroll.sectionIds, isNot(contains('writing')));
      expect(find.text('Writing'), findsNothing);
      expect(find.text('ALL WRITING'), findsNothing);
      expect(find.byType(PortfolioLink), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

void _registerNarrowWritingTests() {
  testWidgets(
    'fits featured, expanded and uncurated writing at 280px in LTR/RTL',
    (tester) async {
      tester.view.physicalSize = const Size(280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final direction in TextDirection.values) {
        for (final featured in [true, false]) {
          await _pumpWriting(
            tester,
            _portfolioWithWriting(withFeatured: featured),
            textDirection: direction,
            padding: const EdgeInsets.fromLTRB(24, 0, 68, 0),
          );
          expect(find.text('Article number 0'), findsOneWidget);
          expect(tester.takeException(), isNull);
          if (featured) {
            await tester.ensureVisible(find.text('Show all 7'));
            await tester.tap(find.text('Show all 7'));
            await tester.pump();
          }
          expect(find.text('Article number 6'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
  );
}

PortfolioDocument _portfolioWithWriting({bool withFeatured = true}) =>
    loadPortfolioFixture(
      mutate: (json) {
        json['writing_sources'] = _writingSources();
        json['writing'] = _writingEntries(withFeatured: withFeatured);
      },
    );

List<Map<String, dynamic>> _writingSources() => [
  {
    'id': 'blog',
    'label': 'Blog',
    'kind': 'rss',
    'url': 'https://example.com/writing/feed.xml',
    'profile_url': 'https://example.com/writing',
  },
  {
    'id': 'devto',
    'label': 'dev.to',
    'kind': 'devto',
    'url': 'https://example.com/devto/articles',
    'profile_url': 'https://example.com/devto',
  },
];

List<Map<String, dynamic>> _writingEntries({required bool withFeatured}) => [
  for (var index = 0; index < 7; index++)
    {
      'title': 'Article number $index',
      'url': 'https://example.com/writing/article-$index',
      'source': index.isEven ? 'blog' : 'devto',
      'date': '2026-08-${(7 - index).toString().padLeft(2, '0')}',
      'featured': withFeatured && index < 2,
    },
];

Future<AppScrollController> _pumpWriting(
  WidgetTester tester,
  PortfolioDocument portfolio, {
  TextDirection textDirection = TextDirection.ltr,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  final scroll = AppScrollController(
    narrative: loadNarrativeFixture(activeSections: portfolio.activeSections),
  );
  final scene = SceneDirector(scrollController: scroll);
  addTearDown(() async {
    await scene.close();
    await scroll.close();
  });
  await tester.pumpWidget(
    _subject(portfolio, scroll, scene, (
      direction: textDirection,
      padding: padding,
    )),
  );
  await tester.pump();
  return scroll;
}

Widget _subject(
  PortfolioDocument portfolio,
  AppScrollController scroll,
  SceneDirector scene,
  ({TextDirection direction, EdgeInsets padding}) layout,
) => MultiRepositoryProvider(
  providers: [
    RepositoryProvider.value(value: portfolio),
    RepositoryProvider.value(value: scroll.narrative),
  ],
  child: MultiBlocProvider(
    providers: [
      BlocProvider.value(value: _language),
      BlocProvider.value(value: scroll),
      BlocProvider.value(value: scene),
    ],
    child: MaterialApp(
      home: Directionality(
        textDirection: layout.direction,
        child: Scaffold(
          body: Padding(
            padding: layout.padding,
            child: const SingleChildScrollView(child: WritingSection()),
          ),
        ),
      ),
    ),
  ),
);

Finder _disclosure({required bool expanded}) => find.byWidgetPredicate(
  (widget) =>
      widget is AccessibleAction &&
      widget.semanticRole == ActionSemanticRole.button &&
      widget.expanded == expanded,
);

Finder _articleLink(String title, String source) => find.byWidgetPredicate(
  (widget) =>
      widget is PortfolioLink &&
      widget.semanticLabel?.contains(title) == true &&
      widget.semanticLabel?.contains(source) == true,
);

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
