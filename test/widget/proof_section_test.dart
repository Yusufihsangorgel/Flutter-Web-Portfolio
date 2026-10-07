import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart'
    hide PortfolioLink;
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/proof_section.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';
import 'package:flutter_web_portfolio/app/widgets/portfolio_link.dart';

import '../helpers/narrative_fixture.dart';
import '../helpers/portfolio_fixture.dart';
import '../support/fake_language_repository.dart';

const _proofTranslations = <String, dynamic>{
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

void main() {
  final subject = _ProofSubject();
  setUp(subject.initialize);
  _registerZeroCountSummaries(subject);
  _registerContributionRendering(subject);
  _registerReplayCompletion(subject);
  _registerReducedMotion(subject);
  _registerReplayDisposal(subject);
  _registerSequenceComparison(subject);
  _registerMissingLab(subject);
  _registerFeaturedLink(subject);
  _registerNarrowContributions(subject);
  _registerRtlSequence(subject);
}

class _ProofSubject {
  late LanguageCubit language;
  late PortfolioDocument portfolio;
  late AppScrollController scroll;
  late SceneDirector scene;

  Future<void> initialize() async {
    portfolio = loadPortfolioFixture();
    scroll = AppScrollController(narrative: loadNarrativeFixture());
    scene = SceneDirector(scrollController: scroll);
    language = LanguageCubit(
      languageRepository: FakeLanguageRepository(
        documents: const {'en': _proofTranslations},
      ),
    );
    await language.initialize();
    addTearDown(() async {
      await scene.close();
      await scroll.close();
      await language.close();
    });
    expect(scroll.activeSection, 'home');
  }

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
}

void _registerZeroCountSummaries(_ProofSubject subject) {
  testWidgets(
    'omits zero counts from accepted-only and review-only summaries',
    (tester) async {
      for (final status in ['merged', 'under_review']) {
        subject.portfolio = loadPortfolioFixture(
          mutate: (json) {
            final entries = json['contributions']! as List<dynamic>;
            for (final entry in entries.cast<Map<String, dynamic>>()) {
              entry['status'] = status;
            }
          },
        );
        await tester.pumpWidget(subject.buildSubject(reducedMotion: true));
        expect(find.textContaining('0 more under review'), findsNothing);
        expect(find.textContaining('0 changes accepted'), findsNothing);
        expect(find.textContaining('0 changes under review'), findsNothing);
        final count = subject.portfolio.contributions.length;
        final expectedSummary = status == 'merged'
            ? '$count changes accepted upstream.'
            : '$count changes under review.';
        expect(find.text(expectedSummary), findsOneWidget);
        final links = tester.widgetList<PortfolioLink>(
          find.byType(PortfolioLink),
        );
        expect(
          links.map((link) => link.uri),
          containsAll(
            subject.portfolio.contributions.map((entry) => entry.url),
          ),
        );
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
}

void _registerContributionRendering(_ProofSubject subject) {
  testWidgets('renders verified open-source contributions', (tester) async {
    await tester.pumpWidget(subject.buildSubject());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Open Source'), findsOneWidget);
    expect(find.text('Featured contribution'.toUpperCase()), findsOneWidget);
    expect(find.text('Accepted upstream'), findsOneWidget);
    expect(find.text('In review'), findsOneWidget);
    for (final contribution in subject.portfolio.contributions) {
      expect(find.text(contribution.title), findsOneWidget);
    }
    expect(find.text('View pull request'), findsOneWidget);
    expect(find.text('First Frame Lab'), findsOneWidget);
    expect(find.textContaining('Blank handoff window'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AccessibleAction &&
            widget.semanticRole == ActionSemanticRole.link,
      ),
      findsNWidgets(subject.portfolio.contributions.length),
    );
    expect(tester.takeException(), isNull);
  });
}

void _registerReplayCompletion(_ProofSubject subject) {
  testWidgets('replays event progress and stops cleanly after the final step', (
    tester,
  ) async {
    await tester.pumpWidget(subject.buildSubject());
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
}

void _registerReducedMotion(_ProofSubject subject) {
  testWidgets('reduced motion applies the complete sequence immediately', (
    tester,
  ) async {
    await tester.pumpWidget(subject.buildSubject(reducedMotion: true));
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
}

void _registerReplayDisposal(_ProofSubject subject) {
  testWidgets('cancels an active replay when the lab leaves the tree', (
    tester,
  ) async {
    await tester.pumpWidget(subject.buildSubject());
    await tester.pump();
    await tester.ensureVisible(find.text('Replay sequence'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replay sequence'));
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}

void _registerSequenceComparison(_ProofSubject subject) {
  testWidgets('compares the baseline and patched event order on demand', (
    tester,
  ) async {
    await tester.pumpWidget(subject.buildSubject());
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
            widget is AccessibleAction &&
            widget.semanticLabel == 'With patch' &&
            widget.selected == true,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

void _registerMissingLab(_ProofSubject subject) {
  testWidgets('omits the lab when contribution metadata does not declare it', (
    tester,
  ) async {
    subject.portfolio = loadPortfolioFixture(
      mutate: (json) {
        final contributions = json['contributions']! as List<dynamic>;
        contributions
            .cast<Map<String, dynamic>>()
            .firstWhere((entry) => entry['featured'] == true)
            .remove('event_order_lab');
      },
    );

    await tester.pumpWidget(subject.buildSubject());
    await tester.pump();

    expect(find.text('First Frame Lab'), findsNothing);
    expect(find.byKey(const Key('contribution-event-order-lab')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

void _registerFeaturedLink(_ProofSubject subject) {
  testWidgets('configures the content-selected contribution as a link', (
    tester,
  ) async {
    await tester.pumpWidget(subject.buildSubject());
    await tester.pump(const Duration(seconds: 1));

    final featured = subject.portfolio.featuredContribution!;
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AccessibleAction &&
            widget.semanticRole == ActionSemanticRole.link &&
            widget.semanticLabel?.contains('View pull request') == true &&
            widget.semanticLabel?.contains(featured.title) == true,
      ),
      findsOneWidget,
    );
  });
}

void _registerNarrowContributions(_ProofSubject subject) {
  testWidgets('keeps every contribution visible on a narrow viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject.buildSubject());
    await tester.pump(const Duration(seconds: 1));
    for (final contribution in subject.portfolio.contributions) {
      expect(find.text(contribution.title), findsOneWidget);
    }
    expect(find.text('First Frame Lab'), findsOneWidget);
    expect(find.textContaining('Blank handoff window'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _registerRtlSequence(_ProofSubject subject) {
  testWidgets('keeps the horizontal sequence ordered from the right in RTL', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(760, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      subject.buildSubject(
        textDirection: TextDirection.rtl,
        reducedMotion: true,
      ),
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
