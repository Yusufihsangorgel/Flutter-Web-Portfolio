import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_style.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/evidence_index_model.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/featured_case.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/project_atlas.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/viewport_proximity_gate.dart';

import '../helpers/portfolio_fixture.dart';

const _labels = ProjectAtlasLabels(
  challenge: 'The problem',
  approach: 'The approach',
  outcome: 'The result',
  ownership: 'What I owned',
  decision: 'Engineering focus',
  selectedCases: 'Case studies',
  evidenceIndex: 'More work',
  evidenceIntro: 'Released products and open-source projects.',
  shippedProducts: 'Shipped products',
  openEngineering: 'Open engineering',
  selectEvidence: 'Choose a project',
  openEvidence: 'View project',
  caseLabel: 'Case',
  indexLabel: 'Index',
);

/// Landscape board and portrait crop sizes produced by the work renderer.
const _boardWidth = 1600;
const _compactBoardWidth = 900;

void main() {
  late PortfolioDocument portfolio;

  setUp(() => portfolio = loadPortfolioFixture());

  Future<ScrollController> pumpAtlas(
    WidgetTester tester, {
    required Size size,
    double leading = 0,
    List<PortfolioSystem>? systems,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      withPortfolioFixtureAssets(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: leading),
                  ProjectAtlas(
                    systems: systems ?? portfolio.systems,
                    labels: _labels,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return controller;
  }

  group('AtlasLayout', () {
    test('switches layouts at the shared breakpoints', () {
      const mobile = AtlasLayout.forWidth(390);
      expect(
        [mobile.narrow, mobile.tablet, mobile.desktop],
        [true, false, false],
      );
      expect(mobile.usesCompactArtifacts, isTrue);
      expect(const AtlasLayout.forWidth(899).usesCompactArtifacts, isTrue);
      expect(const AtlasLayout.forWidth(900).usesCompactArtifacts, isFalse);
      expect(const AtlasLayout.forWidth(1199).desktop, isFalse);
      expect(const AtlasLayout.forWidth(1200).desktop, isTrue);
    });

    test('pads content like the surrounding chapters', () {
      double padding(double width) =>
          AtlasLayout.forWidth(width).horizontalPadding;
      expect(padding(899), AppDimensions.sectionPaddingMobile);
      expect(padding(900), AppDimensions.sectionPaddingTablet);
      expect(padding(1400), AppDimensions.sectionPaddingTablet);
      expect(padding(1401), AppDimensions.sectionPaddingDesktop);
    });

    test('clamps the case title to the layout range', () {
      expect(CaseTitle.fontSizeFor(360), 42);
      expect(CaseTitle.fontSizeFor(899), 66);
      expect(CaseTitle.fontSizeFor(1200), closeTo(62.4, 0.001));
      expect(CaseTitle.fontSizeFor(2560), 82);
    });
  });

  group('lazy artifact loading', () {
    testWidgets('requests no work image until its entry nears the viewport', (
      tester,
    ) async {
      final controller = await pumpAtlas(
        tester,
        size: const Size(1440, 900),
        leading: 4000,
      );
      expect(_workAssets(tester), isEmpty);

      controller.jumpTo(1000);
      await tester.pump();
      expect(_workAssets(tester), isEmpty);

      controller.jumpTo(3000);
      await tester.pump();
      final featured = portfolio.featuredSystems.first.artifact.asset;
      expect(_workAssets(tester), contains(featured));

      controller.jumpTo(0);
      await tester.pump();
      expect(_workAssets(tester), contains(featured), reason: 'stays loaded');
      expect(tester.takeException(), isNull);
    });

    testWidgets('builds immediately without an enclosing scroll view', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ViewportProximityGate(
            builder: (_) => const Text('loaded'),
            placeholder: const Text('waiting'),
          ),
        ),
      );
      expect(find.text('loaded'), findsOneWidget);
      expect(find.text('waiting'), findsNothing);
    });

    testWidgets('loads an entry revealed by a resize without scrolling', (
      tester,
    ) async {
      await pumpAtlas(tester, size: const Size(1440, 400), leading: 1200);
      expect(_workAssets(tester), isEmpty);

      tester.view.physicalSize = const Size(1440, 2400);
      await tester.pump();
      await tester.pump();
      expect(_workAssets(tester), isNotEmpty);
    });
  });

  group('evidence selection', () {
    test('falls back to the first system for an unknown id', () {
      final systems = portfolio.supportingSystems.toList();
      expect(
        EvidenceIndexModel.resolve(systems, systems.last.id),
        systems.last,
      );
      expect(EvidenceIndexModel.resolve(systems, 'removed'), systems.first);
    });

    testWidgets('resets the preview when the selected system disappears', (
      tester,
    ) async {
      final supporting = portfolio.supportingSystems.toList();
      final first = supporting.first;
      final last = supporting.last;
      await pumpAtlas(tester, size: const Size(1440, 2400));

      final row = find.byKey(ValueKey('evidence-row-${last.id}'));
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pump();
      expect(find.byKey(ValueKey('selected-evidence-${last.id}')), findsOne);

      await pumpAtlas(
        tester,
        size: const Size(1440, 2400),
        systems: [
          ...portfolio.featuredSystems,
          ...supporting.where((system) => system.id != last.id),
        ],
      );
      expect(find.byKey(ValueKey('selected-evidence-${first.id}')), findsOne);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('ships work boards at most twice their largest rendered width', (
    tester,
  ) async {
    var primary = 0.0;
    for (final width in const <double>[900, 1199, 1200, 1400, 1401, 1920]) {
      primary = math.max(primary, await _widestArtifact(tester, width));
    }
    var compact = 0.0;
    for (final width in const <double>[390, 600, 899]) {
      compact = math.max(compact, await _widestArtifact(tester, width));
    }

    expect(primary, greaterThanOrEqualTo(_boardWidth / 2));
    expect(compact, greaterThanOrEqualTo(_compactBoardWidth / 2));
  });
}

Future<double> _widestArtifact(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    withPortfolioFixtureAssets(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProjectAtlas(
              systems: loadPortfolioFixture().systems,
              labels: _labels,
            ),
          ),
        ),
      ),
    ),
  );
  final position = tester
      .state<ScrollableState>(find.byType(Scrollable))
      .position;
  while (position.pixels < position.maxScrollExtent) {
    position.jumpTo(math.min(position.pixels + 600, position.maxScrollExtent));
    await tester.pump();
  }
  await tester.pump();
  return tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => tester.getSize(find.byWidget(image)).width)
      .fold<double>(0, math.max);
}

Set<String> _workAssets(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((image) => image.image)
    .map(
      (provider) => provider is ResizeImage ? provider.imageProvider : provider,
    )
    .whereType<AssetImage>()
    .map((image) => image.assetName)
    .where((name) => name.startsWith('assets/work/'))
    .toSet();
