import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/writing/writing_section.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';
import '../helpers/portfolio_fixture.dart';
import '../helpers/narrative_fixture.dart';

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
    },
  };

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {}
}

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
    'url': 'https://dev.to/api/articles?username=example&per_page=100',
    'profile_url': 'https://dev.to/example',
  },
];

/// Seven entries, already newest-first, so a test can prove only the first
/// six render without the widget re-sorting anything itself.
List<Map<String, dynamic>> _sevenWritingEntries() => [
  for (var index = 0; index < 7; index++)
    {
      'title': 'Article number $index',
      'url': 'https://example.com/writing/article-$index',
      'source': index.isEven ? 'blog' : 'devto',
      'date': '2026-08-${(7 - index).toString().padLeft(2, '0')}',
    },
];

void main() {
  late LanguageCubit language;

  setUp(() async {
    language = LanguageCubit(languageRepository: _WritingLanguageRepository());
    await language.initialize();
    addTearDown(() async {
      await language.close();
    });
  });

  PortfolioDocument buildPortfolio({required bool includeWriting}) =>
      loadPortfolioFixture(
        mutate: (json) {
          if (!includeWriting) return;
          json['writing_sources'] = _writingSources();
          json['writing'] = _sevenWritingEntries();
        },
      );

  Widget buildSubject({
    required PortfolioDocument portfolio,
    required AppScrollController scrollController,
    required SceneDirector sceneDirector,
    TextDirection textDirection = TextDirection.ltr,
  }) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: portfolio),
      RepositoryProvider.value(value: scrollController.narrative),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: language),
        BlocProvider.value(value: scrollController),
        BlocProvider.value(value: sceneDirector),
      ],
      child: MaterialApp(
        home: Directionality(
          textDirection: textDirection,
          child: const Scaffold(
            body: SingleChildScrollView(child: WritingSection()),
          ),
        ),
      ),
    ),
  );

  group('WritingSection', () {
    testWidgets(
      'renders the newest six entries as links naming their source and date',
      (tester) async {
        final portfolio = buildPortfolio(includeWriting: true);
        final scroll = AppScrollController(
          narrative: loadNarrativeFixture(
            activeSections: portfolio.activeSections,
          ),
        );
        final scene = SceneDirector(scrollController: scroll);
        addTearDown(() async {
          await scene.close();
          await scroll.close();
        });

        await tester.pumpWidget(
          buildSubject(
            portfolio: portfolio,
            scrollController: scroll,
            sceneDirector: scene,
          ),
        );
        await tester.pump();

        for (var index = 0; index < 6; index++) {
          expect(find.text('Article number $index'), findsOneWidget);
        }
        expect(find.text('Article number 6'), findsNothing);
        expect(find.textContaining('2026—08—07'), findsOneWidget);
        expect(find.text('ALL WRITING'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is AccessibleAction &&
                widget.semanticRole == ActionSemanticRole.link,
          ),
          // Six article rows plus one profile link per declared source.
          findsNWidgets(6 + 2),
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is AccessibleAction &&
                widget.semanticRole == ActionSemanticRole.link &&
                widget.semanticLabel?.contains('Article number 0') == true &&
                widget.semanticLabel?.contains('Blog') == true,
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'hides the section and omits it from navigation when writing is empty',
      (tester) async {
        final portfolio = buildPortfolio(includeWriting: false);
        expect(portfolio.writing, isEmpty);
        expect(portfolio.activeSections, isNot(contains('writing')));

        final scroll = AppScrollController(
          narrative: loadNarrativeFixture(
            activeSections: portfolio.activeSections,
          ),
        );
        final scene = SceneDirector(scrollController: scroll);
        addTearDown(() async {
          await scene.close();
          await scroll.close();
        });

        // The nav strip and command palette both read AppScrollController's
        // sectionIds directly, so proving it here proves the nav entry.
        expect(scroll.sectionIds, isNot(contains('writing')));

        await tester.pumpWidget(
          buildSubject(
            portfolio: portfolio,
            scrollController: scroll,
            sceneDirector: scene,
          ),
        );
        await tester.pump();

        expect(find.text('Writing'), findsNothing);
        expect(find.text('ALL WRITING'), findsNothing);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is AccessibleAction &&
                widget.semanticRole == ActionSemanticRole.link,
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('lays out correctly under right-to-left directionality', (
      tester,
    ) async {
      final portfolio = buildPortfolio(includeWriting: true);
      final scroll = AppScrollController(
        narrative: loadNarrativeFixture(
          activeSections: portfolio.activeSections,
        ),
      );
      final scene = SceneDirector(scrollController: scroll);
      addTearDown(() async {
        await scene.close();
        await scroll.close();
      });

      await tester.pumpWidget(
        buildSubject(
          portfolio: portfolio,
          scrollController: scroll,
          sceneDirector: scene,
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pump();

      expect(find.text('Article number 0'), findsOneWidget);
      expect(find.text('ALL WRITING'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
