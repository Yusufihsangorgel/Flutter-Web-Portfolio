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

import '../helpers/narrative_fixture.dart';
import '../helpers/portfolio_fixture.dart';

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

  Widget buildSubject({TextScaler textScaler = TextScaler.noScaling}) =>
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
                data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                child: const Scaffold(
                  body: SingleChildScrollView(child: ProjectsSection()),
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('renders every work item as a full-width atlas chapter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 200));

    for (final system in portfolio.systems) {
      expect(
        find.byKey(ValueKey('project-atlas-${system.id}')),
        findsOneWidget,
      );
      expect(find.text(system.name), findsOneWidget);
      expect(find.text(system.summary), findsOneWidget);
      if (system case final PortfolioFeaturedSystem featured) {
        expect(find.text(featured.challenge), findsOneWidget);
        expect(find.text(featured.approach), findsOneWidget);
        expect(find.text(featured.outcome), findsOneWidget);
      } else {
        expect(find.text(system.ownership), findsOneWidget);
        expect(find.text(system.decision), findsOneWidget);
      }
    }

    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.byType(AnimatedSize), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the content-authored palette for each project chapter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 200));

    for (final system in portfolio.systems) {
      final chapter = find.byKey(ValueKey('project-atlas-${system.id}'));
      final surface = find.descendant(
        of: chapter,
        matching: find.byType(ColoredBox),
      );
      expect(surface, findsOneWidget);
      final widget = tester.widget<ColoredBox>(surface);
      expect(widget.color, _hexColor(system.presentation.background));
    }
  });

  testWidgets('keeps real artifacts and project links in the document', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byType(Image),
      findsNWidgets(portfolio.supportingSystems.length),
    );
    final controls = tester
        .widgetList<CinematicFocusable>(find.byType(CinematicFocusable))
        .toList(growable: false);
    final expectedLinks = portfolio.systems.fold<int>(
      0,
      (total, system) => total + 1 + system.evidence.length,
    );
    expect(controls.length, greaterThanOrEqualTo(expectedLinks));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the atlas readable on a narrow mobile viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildSubject(textScaler: const TextScaler.linear(1.35)),
    );
    await tester.pump(const Duration(milliseconds: 200));

    for (final system in portfolio.systems) {
      expect(
        find.byKey(ValueKey('project-atlas-${system.id}')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });
}

Color _hexColor(String value) =>
    Color(int.parse('FF${value.substring(1)}', radix: 16));
