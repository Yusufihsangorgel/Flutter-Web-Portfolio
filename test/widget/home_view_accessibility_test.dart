import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/features/render_quality/application/render_quality_controller.dart';
import 'package:flutter_web_portfolio/app/modules/home/home_view.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';
import 'package:flutter_web_portfolio/app/widgets/skip_to_content_link.dart';

import '../helpers/narrative_fixture.dart';
import '../helpers/portfolio_fixture.dart';
import '../support/fake_language_repository.dart';

const _skipLabel = 'Skip to content';

void main() {
  final subject = _HomeViewSubject();
  setUp(subject.initialize);
  _registerSectionOrder(subject);
  _registerSkipLinkFocus(subject);
  _registerMenuSemantics(subject);
  _registerSkipLinkActivation(subject);
}

class _HomeViewSubject {
  late LanguageCubit language;
  late AppScrollController scroll;
  late SceneDirector scene;
  late RenderQualityController quality;
  late PortfolioDocument portfolio;
  late NarrativeDocument narrative;

  Future<void> initialize() async {
    portfolio = loadPortfolioFixture(
      mutate: (json) {
        json['writing_sources'] = [
          {
            'id': 'blog',
            'label': 'Blog',
            'kind': 'rss',
            'url': 'https://example.com/writing/feed.xml',
            'profile_url': 'https://example.com/writing',
          },
        ];
        json['writing'] = [
          {
            'title': 'Sample article',
            'url': 'https://example.com/writing/sample',
            'source': 'blog',
            'date': '2026-09-01',
            'featured': true,
          },
        ];
      },
    );
    narrative = loadNarrativeFixture(activeSections: portfolio.activeSections);
    language = LanguageCubit(
      languageRepository: FakeLanguageRepository(
        documents: const {
          'en': {
            'accessibility': {'skip_to_content': _skipLabel},
          },
        },
      ),
    );
    await language.initialize();
    scroll = AppScrollController(narrative: narrative);
    scene = SceneDirector(scrollController: scroll);
    quality = RenderQualityController();
    addTearDown(() async {
      await quality.close();
      await scene.close();
      await scroll.close();
      await language.close();
    });
  }

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      withPortfolioFixtureAssets(
        child: MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: portfolio),
            RepositoryProvider.value(value: narrative),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: language),
              BlocProvider.value(value: scroll),
              BlocProvider.value(value: scene),
              BlocProvider.value(value: quality),
            ],
            child: const MaterialApp(home: HomeView()),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pressTab(WidgetTester tester) async {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  bool receivesPointerAtItsCenter(WidgetTester tester) {
    final link = find.byType(SkipToContentLink);
    final renderObjects = find
        .descendant(of: link, matching: find.byWidgetPredicate((_) => true))
        .evaluate()
        .map((element) => element.renderObject)
        .toSet();
    return tester
        .hitTestOnBinding(tester.getCenter(link))
        .path
        .any((entry) => renderObjects.contains(entry.target));
  }

  double opacityOfLink(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(SkipToContentLink),
          matching: find.byType(AnimatedOpacity),
        ),
      )
      .opacity;
}

void _registerSectionOrder(_HomeViewSubject subject) {
  testWidgets('lays out sections in document order with the skip link intact', (
    tester,
  ) async {
    await subject.pumpHome(tester);
    const ids = [
      'home',
      'experience',
      'proof',
      'projects',
      'packages',
      'writing',
      'about',
    ];
    final positions = [
      for (final id in ids)
        tester.getTopLeft(find.byKey(subject.scroll.keyFor(SectionId(id)))).dy,
    ];
    for (var index = 1; index < positions.length; index++) {
      expect(positions[index], greaterThan(positions[index - 1]));
    }
    expect(find.byType(SkipToContentLink), findsOneWidget);
    expect(subject.opacityOfLink(tester), 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

void _registerSkipLinkFocus(_HomeViewSubject subject) {
  testWidgets('the first Tab reveals and focuses the skip link above the '
      'page chrome', (tester) async {
    await subject.pumpHome(tester);
    final skipText = find.text(_skipLabel);

    expect(subject.opacityOfLink(tester), 0);
    expect(subject.receivesPointerAtItsCenter(tester), isFalse);

    await subject.pressTab(tester);

    expect(Focus.of(tester.element(skipText)).hasPrimaryFocus, isTrue);
    expect(subject.opacityOfLink(tester), 1);
    expect(skipText.hitTestable(), findsOneWidget);
    expect(subject.receivesPointerAtItsCenter(tester), isTrue);

    await subject.pressTab(tester);

    // The default test view is compact, where the menu button leads the bar.
    final menuButton = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == 'Open navigation menu',
    );
    expect(Focus.of(tester.element(menuButton)).hasPrimaryFocus, isTrue);
    expect(subject.opacityOfLink(tester), 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

void _registerMenuSemantics(_HomeViewSubject subject) {
  testWidgets('the compact menu button has exactly one accessible name', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await subject.pumpHome(tester);

    // Browsers join label and tooltip, so one of them must carry the name.
    final menu = tester
        .getSemantics(find.bySemanticsLabel('Open navigation menu'))
        .getSemanticsData();
    expect(menu.label, 'Open navigation menu');
    expect(menu.tooltip, isEmpty);
    expect(menu.flagsCollection.isButton, isTrue);
    final icon = find.byIcon(Icons.menu_rounded);
    final action = find.ancestor(
      of: icon,
      matching: find.byType(AccessibleAction),
    );
    expect(tester.getCenter(icon), tester.getCenter(action));
    // An icon-button target, so a pointer resting in the corner shows no tooltip.
    expect(tester.getSize(action), const Size.square(48));
    expect(tester.getRect(action).contains(Offset.zero), isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
  });
}

void _registerSkipLinkActivation(_HomeViewSubject subject) {
  testWidgets('activating the skip link moves focus into the main content', (
    tester,
  ) async {
    await subject.pumpHome(tester);
    await subject.pressTab(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'portfolio-main-content',
    );
    expect(subject.opacityOfLink(tester), 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
