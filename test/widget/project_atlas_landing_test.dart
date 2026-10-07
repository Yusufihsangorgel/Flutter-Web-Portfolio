import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll/section_geometry_tracker.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll/section_scroller.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/project_atlas.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';

import '../helpers/narrative_fixture.dart';
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

void main() {
  testWidgets(
    'loads the first case when a deep link lands on the first frame',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final portfolio = loadPortfolioFixture();
      final narrative = loadNarrativeFixture();
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final geometry = SectionGeometryTracker(narrative);
      addTearDown(geometry.dispose);
      final scroller = SectionScroller(controller, geometry);

      // Lands like the home view: a post-frame callback registered before the
      // atlas builds measures the chapters and jumps to Work.
      await tester.pumpWidget(
        withPortfolioFixtureAssets(
          child: MaterialApp(
            home: Scaffold(
              body: _LandOnFirstFrame(
                onFirstFrame: () {
                  geometry.measure(controller.offset);
                  expect(scroller.jumpTo(SectionId.projects.value), isTrue);
                },
                child: CustomScrollView(
                  controller: controller,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final chapter in narrative.chapters)
                            KeyedSubtree(
                              key: geometry.keyFor(chapter.id),
                              child: chapter.id == SectionId.projects
                                  ? ProjectAtlas(
                                      systems: portfolio.systems,
                                      labels: _labels,
                                    )
                                  : const SizedBox(height: 2400),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(controller.offset, greaterThan(0), reason: 'the deep link landed');

      await tester.pump();
      await tester.pump();
      expect(
        _workAssets(tester),
        contains(portfolio.featuredSystems.first.artifact.asset),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

final class _LandOnFirstFrame extends StatefulWidget {
  const _LandOnFirstFrame({required this.onFirstFrame, required this.child});

  final VoidCallback onFirstFrame;
  final Widget child;

  @override
  State<_LandOnFirstFrame> createState() => _LandOnFirstFrameState();
}

final class _LandOnFirstFrameState extends State<_LandOnFirstFrame> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFirstFrame());
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
