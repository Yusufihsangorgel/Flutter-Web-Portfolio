import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/i_language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/proof_section.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import '../helpers/portfolio_fixture.dart';
import '../helpers/narrative_fixture.dart';

final class _ProofLanguageRepository implements ILanguageRepository {
  @override
  Set<String> getSupportedLanguages() => const {'en'};

  @override
  Future<String> getSelectedLanguage() async => 'en';

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async => {
    'nav': {'proof': 'Open Source'},
    'proof_section': {
      'title': 'Open Source',
      'summary':
          '{merged} changes accepted upstream; {review} more under review.',
      'featured_label': 'Featured contribution',
      'accepted_title': 'Accepted upstream',
      'review_title': 'In review',
      'problem_label': 'The failure',
      'change_label': 'The patch',
      'open_pull_request': 'View pull request',
      'status_merged': 'Merged',
      'status_under_review': 'Under review',
      'event_lab_label': 'Event order lab',
      'event_lab_without_patch': 'Without patch',
      'event_lab_with_patch': 'With patch',
      'event_lab_replay': 'Replay sequence',
      'event_lab_sequence': 'Event sequence',
      'event_lab_risk': 'Risk',
      'event_lab_step': 'Step',
    },
  };

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {}
}

void main() {
  late LanguageCubit language;
  late PortfolioDocument portfolio;
  late AppScrollController scroll;
  late SceneDirector scene;

  setUp(() async {
    portfolio = loadPortfolioFixture();
    scroll = AppScrollController(narrative: loadNarrativeFixture());
    scene = SceneDirector(scrollController: scroll);
    language = LanguageCubit(languageRepository: _ProofLanguageRepository());
    await language.initialize();
    addTearDown(() async {
      await scene.close();
      await scroll.close();
      await language.close();
    });
    expect(scroll.activeSection, 'home');
  });

  Widget buildSubject({
    bool reducedMotion = false,
    TextDirection textDirection = TextDirection.ltr,
  }) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: portfolio),
      RepositoryProvider.value(value: scroll.narrative),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: language),
        BlocProvider.value(value: scroll),
        BlocProvider.value(value: scene),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reducedMotion),
            child: Directionality(
              textDirection: textDirection,
              child: const Scaffold(
                body: SingleChildScrollView(child: ProofSection()),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('renders verified open-source contributions', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Open Source'), findsOneWidget);
    expect(find.text('Featured contribution'.toUpperCase()), findsOneWidget);
    expect(find.text('Accepted upstream'), findsOneWidget);
    expect(find.text('In review'), findsOneWidget);
    for (final contribution in portfolio.contributions) {
      expect(find.text(contribution.title), findsOneWidget);
    }
    expect(find.text('View pull request'), findsOneWidget);
    expect(find.text('First Frame Lab'), findsOneWidget);
    expect(find.textContaining('Blank handoff window'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CinematicFocusable &&
            widget.semanticRole == CinematicControlRole.link,
      ),
      findsNWidgets(portfolio.contributions.length),
    );
    expect(find.textContaining('testimonial'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('replays event progress and stops cleanly after the final step', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.ensureVisible(find.text('With patch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('With patch'));
    await tester.pump();

    final browserFrame = find.byKey(
      const ValueKey('event-lab-event-browser_frame'),
    );
    final inactiveBorder = _animatedBorderColor(tester, browserFrame);

    await tester.pump(const Duration(milliseconds: 900));
    final activeBorder = _animatedBorderColor(tester, browserFrame);
    expect(activeBorder, isNot(inactiveBorder));

    await tester.tap(find.text('Replay sequence'));
    await tester.pump();
    expect(_animatedBorderColor(tester, browserFrame), inactiveBorder);

    await tester.pump(const Duration(seconds: 2));
    expect(_animatedBorderColor(tester, browserFrame), activeBorder);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion applies the complete sequence immediately', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(reducedMotion: true));
    await tester.pump();
    await tester.ensureVisible(find.text('With patch'));
    await tester.pump();
    await tester.tap(find.text('With patch'));
    await tester.pump();

    final first = find.byKey(
      const ValueKey('event-lab-event-framework_signal'),
    );
    final browserFrame = find.byKey(
      const ValueKey('event-lab-event-browser_frame'),
    );
    expect(
      _animatedBorderColor(tester, browserFrame),
      _animatedBorderColor(tester, first),
    );
    expect(
      tester.widget<AnimatedContainer>(browserFrame).duration,
      Duration.zero,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancels an active replay when the lab leaves the tree', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.ensureVisible(find.text('Replay sequence'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replay sequence'));
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('compares the baseline and patched event order on demand', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.textContaining('Blank handoff window'), findsOneWidget);
    expect(find.text('Next browser animation frame'), findsNothing);

    await tester.ensureVisible(find.text('With patch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('With patch'));
    await tester.pump();

    expect(find.textContaining('Blank handoff window'), findsNothing);
    expect(find.text('Next browser animation frame'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CinematicFocusable &&
            widget.semanticLabel == 'With patch' &&
            widget.selected == true,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('omits the lab when contribution metadata does not declare it', (
    tester,
  ) async {
    portfolio = loadPortfolioFixture(
      mutate: (json) {
        final contributions = json['contributions']! as List<dynamic>;
        contributions
            .cast<Map<String, dynamic>>()
            .firstWhere((entry) => entry['featured'] == true)
            .remove('event_order_lab');
      },
    );

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('First Frame Lab'), findsNothing);
    expect(find.byKey(const Key('contribution-event-order-lab')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('configures the content-selected contribution as a link', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(seconds: 1));

    final featured = portfolio.featuredContribution!;
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CinematicFocusable &&
            widget.semanticRole == CinematicControlRole.link &&
            widget.semanticLabel?.contains('View pull request') == true &&
            widget.semanticLabel?.contains(featured.title) == true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps every contribution visible on a narrow viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(seconds: 1));
    for (final contribution in portfolio.contributions) {
      expect(find.text(contribution.title), findsOneWidget);
    }
    expect(find.text('First Frame Lab'), findsOneWidget);
    expect(find.textContaining('Blank handoff window'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the horizontal sequence ordered from the right in RTL', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(760, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildSubject(textDirection: TextDirection.rtl, reducedMotion: true),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('First Frame Lab'));
    await tester.pump();

    final first = find.byKey(
      const ValueKey('event-lab-event-framework_signal'),
    );
    final last = find.byKey(
      const ValueKey('event-lab-event-scene_render_complete'),
    );
    expect(
      tester.getTopLeft(first).dx,
      greaterThan(tester.getTopLeft(last).dx),
    );
    expect(tester.takeException(), isNull);
  });
}

Color _animatedBorderColor(WidgetTester tester, Finder finder) {
  final container = tester.widget<AnimatedContainer>(finder);
  final decoration = container.decoration! as BoxDecoration;
  final border = decoration.border! as Border;
  return border.top.color;
}
