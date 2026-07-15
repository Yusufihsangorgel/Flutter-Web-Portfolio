import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/i_language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/projects_section.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';

import '../helpers/portfolio_fixture.dart';
import '../helpers/narrative_fixture.dart';

final class _ProjectsLanguageRepository implements ILanguageRepository {
  @override
  Map<String, String> getSupportedLanguages() => const {'en': 'EN'};

  @override
  Future<String> getSelectedLanguage() async => 'en';

  @override
  Future<Map<String, dynamic>> getTranslations(String languageCode) async => {
    'projects_section': {
      'title': 'Selected Work',
      'subtitle': 'Products and maintained tools.',
      'archive': 'More work',
      'challenge': 'The problem',
      'approach': 'The approach',
      'outcome': 'The result',
      'evidence': 'Evidence',
      'open_project': 'Open project',
      'open_evidence': 'Open evidence',
    },
  };

  @override
  Future<void> saveSelectedLanguage(String languageCode) async {}
}

void main() {
  late PortfolioDocument portfolio;
  late LanguageCubit language;
  late AppScrollController scroll;
  late SceneDirector scene;

  setUp(() async {
    portfolio = loadPortfolioFixture();
    scroll = AppScrollController(narrative: loadNarrativeFixture());
    scene = SceneDirector(scrollController: scroll);
    language = LanguageCubit(languageRepository: _ProjectsLanguageRepository());
    await language.initialize();
    addTearDown(() async {
      await scene.close();
      await scroll.close();
      await language.close();
    });
  });

  Widget buildSubject() => MultiRepositoryProvider(
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
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: ProjectsSection())),
      ),
    ),
  );

  testWidgets('renders featured work as problem-to-evidence chapters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(seconds: 1));

    final featured = portfolio.featuredSystems.toList(growable: false);
    expect(featured, hasLength(3));

    for (final system in featured) {
      expect(
        find.byKey(ValueKey('project-chapter-${system.id}')),
        findsOneWidget,
      );
      expect(find.text(system.challenge!), findsOneWidget);
      expect(find.text(system.approach!), findsOneWidget);
      expect(find.text(system.outcome!), findsOneWidget);
      expect(find.text(system.ownership), findsNothing);
      expect(find.text(system.decision), findsNothing);

      final challengeTop = tester.getTopLeft(find.text(system.challenge!)).dy;
      final approachTop = tester.getTopLeft(find.text(system.approach!)).dy;
      final outcomeTop = tester.getTopLeft(find.text(system.outcome!)).dy;
      expect(challengeTop, lessThan(approachTop));
      expect(approachTop, lessThan(outcomeTop));

      final independentEvidence = system.evidence
          .where((item) => item.url != system.url)
          .toList(growable: false);
      for (var index = 0; index < independentEvidence.length; index++) {
        final evidence = independentEvidence[index];
        final evidenceFinder = find.byKey(
          ValueKey('project-evidence-${system.id}-$index'),
        );
        expect(evidenceFinder, findsOneWidget);
        expect(find.text(evidence.label), findsOneWidget);
        expect(tester.getSize(evidenceFinder).height, greaterThanOrEqualTo(52));
      }
    }

    expect(
      tester.getTopLeft(find.text(featured[1].name)).dx,
      greaterThan(tester.getTopLeft(find.text(featured.first.name)).dx + 40),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps project and evidence destinations keyboard-accessible', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(seconds: 1));

    final links = tester.widgetList<CinematicFocusable>(
      find.byType(CinematicFocusable),
    );
    final expectedLinkCount =
        portfolio.systems.length +
        portfolio.featuredSystems.fold<int>(
          0,
          (count, system) =>
              count +
              system.evidence.where((item) => item.url != system.url).length,
        );

    expect(links, hasLength(expectedLinkCount));
    expect(
      links.every(
        (link) =>
            link.semanticRole == CinematicControlRole.link &&
            (link.semanticLabel?.trim().isNotEmpty ?? false),
      ),
      isTrue,
    );
  });

  testWidgets('presents supporting work as a compact typographic archive', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(seconds: 1));

    for (final system in portfolio.supportingSystems) {
      final row = find.byKey(ValueKey('project-archive-${system.id}'));
      expect(row, findsOneWidget);
      expect(
        find.descendant(of: row, matching: find.text(system.name)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text(system.kind)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text(system.summary)),
        findsOneWidget,
      );
    }

    final boxDecorations = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>();
    expect(
      boxDecorations.every(
        (decoration) => decoration.boxShadow?.isEmpty ?? true,
      ),
      isTrue,
    );
  });

  testWidgets('keeps every chapter and archive row readable on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(seconds: 1));

    for (final system in portfolio.featuredSystems) {
      expect(find.text(system.name), findsOneWidget);
      expect(find.text(system.challenge!), findsOneWidget);
      expect(find.text(system.outcome!), findsOneWidget);
    }
    for (final system in portfolio.supportingSystems) {
      expect(
        find.byKey(ValueKey('project-archive-${system.id}')),
        findsOneWidget,
      );
    }

    expect(tester.takeException(), isNull);
  });
}
