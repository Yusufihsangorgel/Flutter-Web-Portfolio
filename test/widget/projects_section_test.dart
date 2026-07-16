import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/i_language_repository.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/projects_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/project_archive.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';

import '../helpers/portfolio_fixture.dart';
import '../helpers/narrative_fixture.dart';

final class _ProjectsLanguageRepository implements ILanguageRepository {
  @override
  Set<String> getSupportedLanguages() => const {'en'};

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
      'ownership': 'What I owned',
      'decision': 'Engineering focus',
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

  Widget buildSubject({bool disableAnimations = false}) =>
      MultiRepositoryProvider(
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
                ).copyWith(disableAnimations: disableAnimations),
                child: const Scaffold(
                  body: SingleChildScrollView(child: ProjectsSection()),
                ),
              ),
            ),
          ),
        ),
      );

  Widget buildArchiveSubject(
    List<PortfolioSupportingSystem> systems, {
    TextDirection textDirection = TextDirection.ltr,
    TextScaler textScaler = TextScaler.noScaling,
  }) => MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: Directionality(
          textDirection: textDirection,
          child: Scaffold(
            body: SingleChildScrollView(
              child: ProjectArchive(
                systems: systems,
                labels: const ProjectArchiveLabels(
                  scope: 'What I owned',
                  decision: 'Engineering focus',
                  openEvidence: 'Open evidence',
                ),
              ),
            ),
          ),
        ),
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
      expect(find.text(system.challenge), findsOneWidget);
      expect(find.text(system.approach), findsOneWidget);
      expect(find.text(system.outcome), findsOneWidget);
      expect(find.text(system.ownership), findsNothing);
      expect(find.text(system.decision), findsNothing);

      final challengeTop = tester.getTopLeft(find.text(system.challenge)).dy;
      final approachTop = tester.getTopLeft(find.text(system.approach)).dy;
      final outcomeTop = tester.getTopLeft(find.text(system.outcome)).dy;
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

    final controls = tester
        .widgetList<CinematicFocusable>(find.byType(CinematicFocusable))
        .toList(growable: false);
    final expectedControlCount =
        portfolio.systems.length +
        portfolio.featuredSystems.fold<int>(
          0,
          (count, system) =>
              count +
              system.evidence.where((item) => item.url != system.url).length,
        ) +
        portfolio.supportingSystems.first.evidence.length;

    expect(controls, hasLength(expectedControlCount));
    expect(
      controls.every(
        (control) => control.semanticLabel?.trim().isNotEmpty ?? false,
      ),
      isTrue,
    );
    expect(
      controls
          .where(
            (control) => control.semanticRole == CinematicControlRole.button,
          )
          .length,
      portfolio.supportingSystems.length,
    );
    expect(
      controls
          .where((control) => control.semanticRole == CinematicControlRole.link)
          .length,
      expectedControlCount - portfolio.supportingSystems.length,
    );
  });

  testWidgets('presents supporting work as an artifact-backed release ledger', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
        find.descendant(of: row, matching: find.textContaining(system.kind)),
        findsOneWidget,
      );
    }

    final supporting = portfolio.supportingSystems.toList(growable: false);
    final active = supporting.first;
    expect(
      find.byKey(ValueKey('project-artifact-${active.id}')),
      findsOneWidget,
    );
    expect(find.text(active.summary), findsOneWidget);
    expect(find.text(active.ownership), findsOneWidget);
    expect(find.text(active.decision), findsOneWidget);
    expect(find.text(active.artifact.caption), findsOneWidget);
    final activeHeader = tester
        .widgetList<CinematicFocusable>(
          find.descendant(
            of: find.byKey(ValueKey('project-archive-${active.id}')),
            matching: find.byType(CinematicFocusable),
          ),
        )
        .first;
    expect(activeHeader.semanticRole, CinematicControlRole.button);
    expect(activeHeader.selected, isTrue);
    expect(activeHeader.expanded, isTrue);
    final inactiveHeader = tester
        .widgetList<CinematicFocusable>(
          find.descendant(
            of: find.byKey(ValueKey('project-archive-${supporting[1].id}')),
            matching: find.byType(CinematicFocusable),
          ),
        )
        .first;
    expect(inactiveHeader.selected, isFalse);
    expect(inactiveHeader.expanded, isFalse);
    expect(
      find.byKey(ValueKey('project-artifact-${supporting[1].id}')),
      findsNothing,
    );

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

  testWidgets('desktop archive changes its evidence fold on activation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(seconds: 1));

    final supporting = portfolio.supportingSystems.toList(growable: false);
    expect(supporting.length, greaterThan(1));
    expect(find.text(supporting.first.summary), findsOneWidget);
    expect(find.text(supporting[1].summary), findsNothing);

    final secondRow = find.byKey(
      ValueKey('project-archive-${supporting[1].id}'),
    );
    await tester.ensureVisible(secondRow);
    await tester.pumpAndSettle();
    final anchorBeforeSelection = tester.getTopLeft(secondRow).dy;
    await tester.tap(secondRow);
    await tester.pumpAndSettle();

    expect(find.text(supporting.first.summary), findsNothing);
    expect(find.text(supporting[1].summary), findsOneWidget);
    expect(
      tester.getTopLeft(secondRow).dy,
      moreOrLessEquals(anchorBeforeSelection, epsilon: 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('focus does not change records until keyboard activation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final supporting = portfolio.supportingSystems.toList(growable: false);
    await tester.pumpWidget(buildArchiveSubject(supporting));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(
      find.byKey(ValueKey('project-artifact-${supporting.first.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('project-artifact-${supporting[1].id}')),
      findsNothing,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('project-artifact-${supporting.first.id}')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('project-artifact-${supporting[1].id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('avoids layout-mutating archive size transitions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AnimatedSize), findsNothing);
    expect(
      find.byKey(
        ValueKey('project-artifact-${portfolio.supportingSystems.first.id}'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('preserves the active record by id when content reorders', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final supporting = portfolio.supportingSystems.toList(growable: false);
    final selected = supporting[1];
    await tester.pumpWidget(buildArchiveSubject(supporting));
    await tester.pumpAndSettle();

    final selectedRow = find.byKey(ValueKey('project-archive-${selected.id}'));
    await tester.ensureVisible(selectedRow);
    await tester.pumpAndSettle();
    await tester.tap(selectedRow);
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('project-artifact-${selected.id}')),
      findsOneWidget,
    );

    final reordered = supporting.reversed.toList(growable: false);
    await tester.pumpWidget(buildArchiveSubject(reordered));
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('project-artifact-${selected.id}')),
      findsOneWidget,
    );

    final withoutSelected = reordered
        .where((system) => system.id != selected.id)
        .toList(growable: false);
    await tester.pumpWidget(buildArchiveSubject(withoutSelected));
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('project-artifact-${withoutSelected.first.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
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
      expect(find.text(system.challenge), findsOneWidget);
      expect(find.text(system.outcome), findsOneWidget);
    }
    for (final system in portfolio.supportingSystems) {
      expect(
        find.byKey(ValueKey('project-archive-${system.id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('project-artifact-${system.id}')),
        findsOneWidget,
      );
      expect(find.text(system.ownership), findsOneWidget);
      expect(find.text(system.decision), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(ValueKey('project-artifact-${system.id}')),
          matching: find.text(system.artifact.caption),
        ),
        findsOneWidget,
      );
      final artifactImage = tester.widget<Image>(
        find.descendant(
          of: find.byKey(ValueKey('project-artifact-${system.id}')),
          matching: find.byType(Image),
        ),
      );
      expect(artifactImage.semanticLabel, system.artifact.alt);
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('switches archive disclosure exactly at its local breakpoint', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final supporting = portfolio.supportingSystems.toList(growable: false);

    tester.view.physicalSize = const Size(719, 1000);
    await tester.pumpWidget(buildArchiveSubject(supporting));
    await tester.pumpAndSettle();
    for (final system in supporting) {
      expect(
        find.byKey(ValueKey('project-artifact-${system.id}')),
        findsOneWidget,
      );
    }

    tester.view.physicalSize = const Size(720, 1000);
    await tester.pumpWidget(buildArchiveSubject(supporting));
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('project-artifact-${supporting.first.id}')),
      findsOneWidget,
    );
    for (final system in supporting.skip(1)) {
      expect(
        find.byKey(ValueKey('project-artifact-${system.id}')),
        findsNothing,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the mobile ledger readable in RTL at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final supporting = portfolio.supportingSystems.toList(growable: false);

    await tester.pumpWidget(
      buildArchiveSubject(
        supporting,
        textDirection: TextDirection.rtl,
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();

    for (final system in supporting) {
      expect(find.text(system.name), findsOneWidget);
      expect(
        find.byKey(ValueKey('project-artifact-${system.id}')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
