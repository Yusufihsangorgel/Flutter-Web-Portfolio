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
      'selected_cases': 'Professional cases',
      'evidence_index': 'Evidence index',
      'evidence_intro': 'Released products and source-backed records.',
      'shipped_products': 'Shipped products',
      'open_engineering': 'Open engineering',
      'select_evidence': 'Select evidence',
      'challenge': 'The problem',
      'approach': 'The approach',
      'outcome': 'The result',
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

  testWidgets('renders professional cases followed by one evidence index', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 200));

    for (final system in portfolio.featuredSystems) {
      expect(
        find.byKey(ValueKey('project-atlas-${system.id}')),
        findsOneWidget,
      );
      expect(find.text(system.name), findsOneWidget);
      expect(find.text(system.summary), findsOneWidget);
      expect(find.text(system.challenge), findsOneWidget);
      expect(find.text(system.approach), findsOneWidget);
      expect(find.text(system.outcome), findsOneWidget);
    }
    for (final system in portfolio.supportingSystems) {
      expect(find.text(system.name), findsWidgets);
      expect(find.text(system.spotlight), findsWidgets);
    }

    expect(
      find.byKey(const ValueKey('project-evidence-index')),
      findsOneWidget,
    );
    expect(find.text('Evidence index'), findsOneWidget);
    expect(find.byType(ExpansionTile), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the content-authored palette for each professional case', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 200));

    for (final system in portfolio.featuredSystems) {
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

  testWidgets('keeps real artifacts and evidence links in the document', (
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
      findsAtLeastNWidgets(portfolio.featuredSystems.length + 1),
    );
    final controls = tester
        .widgetList<CinematicFocusable>(find.byType(CinematicFocusable))
        .toList(growable: false);
    final expectedLinks =
        portfolio.featuredSystems.fold<int>(
          0,
          (total, system) => total + system.evidence.length,
        ) +
        portfolio.supportingSystems.first.evidence.length;
    expect(controls.length, greaterThanOrEqualTo(expectedLinks));
    expect(tester.takeException(), isNull);
  });

  testWidgets('changes the reading pane from a source-authored index row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 200));

    final initial = portfolio.supportingSystems.first;
    final target = portfolio.supportingSystems.firstWhere(
      (system) => system.id == 'queue-inspector',
    );
    expect(_assetNames(tester), contains(initial.artifact.asset));

    final targetRow = find.text(target.name).first;
    await tester.ensureVisible(targetRow);
    await tester.pump();
    await tester.tap(targetRow);
    await tester.pumpAndSettle();

    expect(_assetNames(tester), contains(target.artifact.asset));
    expect(_assetNames(tester), isNot(contains(initial.artifact.asset)));
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

    for (final system in portfolio.featuredSystems) {
      expect(
        find.byKey(ValueKey('project-atlas-${system.id}')),
        findsOneWidget,
      );
    }
    for (final system in portfolio.supportingSystems) {
      expect(find.text(system.name), findsWidgets);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows compact portrait artifacts on a narrow mobile viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 200));

    final assets = _assetNames(tester);
    for (final system in portfolio.featuredSystems) {
      final compact = system.artifact.compact;
      if (compact == null) continue;
      expect(assets, contains(compact.asset), reason: system.id);
      expect(assets, isNot(contains(system.artifact.asset)), reason: system.id);
    }

    final selected = portfolio.supportingSystems.first;
    final selectedCompact = selected.artifact.compact;
    if (selectedCompact != null) {
      expect(assets, contains(selectedCompact.asset), reason: selected.id);
      expect(
        assets,
        isNot(contains(selected.artifact.asset)),
        reason: selected.id,
      );
    }
    expect(tester.takeException(), isNull);
  });
}

Color _hexColor(String value) =>
    Color(int.parse('FF${value.substring(1)}', radix: 16));

Set<String> _assetNames(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((image) => image.image)
    .whereType<AssetImage>()
    .map((image) => image.assetName)
    .toSet();
