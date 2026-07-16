import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';

import '../helpers/narrative_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('keeps measured content anchors stable in document space', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    final controller = AppScrollController(narrative: loadNarrativeFixture());
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await controller.close();
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: CustomScrollView(
          controller: controller.scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < controller.narrative.chapters.length;
                    index += 1
                  )
                    SizedBox(
                      key: controller.keyFor(
                        controller.narrative.chapters[index].id,
                      ),
                      height: 900,
                      child: Align(
                        alignment: Alignment(-0.7 + index * 0.3, 0),
                        child: SizedBox(
                          key: controller.anchorKeyFor(
                            controller.narrative.chapters[index].id,
                          ),
                          width: 24 + index * 4,
                          height: 24 + index * 4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    controller.refreshSectionGeometry();
    final before = controller.narrativeAnchors.value;

    expect(before.covers(controller.narrative.sectionIds), isTrue);
    expect(
      before.anchors.map((anchor) => anchor.documentCenter.dy),
      orderedEquals([450, 1350, 2250, 3150, 4050]),
    );

    controller.scrollController.jumpTo(1250);
    await tester.pump();
    controller.refreshSectionGeometry();
    final after = controller.narrativeAnchors.value;

    expect(after, before);
  });

  testWidgets('preserves the chapter-relative reading anchor through reflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    final controller = AppScrollController(narrative: loadNarrativeFixture());
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await controller.close();
      await tester.binding.setSurfaceSize(null);
    });

    Widget document(Map<SectionId, double> heights) => MaterialApp(
      home: CustomScrollView(
        controller: controller.scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                for (final chapter in controller.narrative.chapters)
                  SizedBox(
                    key: controller.keyFor(chapter.id),
                    height: heights[chapter.id],
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    final initialHeights = <SectionId, double>{
      SectionId.home: 900,
      SectionId.experience: 1000,
      SectionId.proof: 1100,
      SectionId.projects: 2200,
      SectionId.about: 1000,
    };
    await tester.pumpWidget(document(initialHeights));
    await tester.pump();
    controller.refreshSectionGeometry();
    controller.scrollController.jumpTo(3500);
    await tester.pump();
    await tester.pump();

    final before = controller.narrativePosition.value;
    final beforeGeometry = controller.sectionGeometries.firstWhere(
      (section) => section.id == before.activeSectionId,
    );
    final beforeLocalProgress =
        (before.focalPoint - beforeGeometry.top) / beforeGeometry.height;
    final beforeOffset = controller.scrollController.offset;
    expect(before.activeSectionId, 'projects');

    final reflowedHeights = <SectionId, double>{
      SectionId.home: 1300,
      SectionId.experience: 1300,
      SectionId.proof: 1100,
      SectionId.projects: 2600,
      SectionId.about: 1000,
    };
    await tester.pumpWidget(document(reflowedHeights));
    controller.markGeometryDirty();
    await tester.pump();
    await tester.pump();

    final after = controller.narrativePosition.value;
    final afterGeometry = controller.sectionGeometries.firstWhere(
      (section) => section.id == after.activeSectionId,
    );
    final afterLocalProgress =
        (after.focalPoint - afterGeometry.top) / afterGeometry.height;

    expect(after.activeSectionId, before.activeSectionId);
    expect(afterLocalProgress, closeTo(beforeLocalProgress, 0.01));
    expect(controller.scrollController.offset, greaterThan(beforeOffset + 600));
  });

  testWidgets(
    'keeps a chapter heading visible when its opening reflows on mobile',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      final controller = AppScrollController(narrative: loadNarrativeFixture());
      final projectsHeadingKey = GlobalKey();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await controller.close();
        await tester.binding.setSurfaceSize(null);
      });

      Widget document() => MaterialApp(
        home: CustomScrollView(
          controller: controller.scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 600;
                  final heights = <SectionId, double>{
                    SectionId.home: isCompact ? 1200 : 900,
                    SectionId.experience: isCompact ? 1500 : 900,
                    SectionId.proof: isCompact ? 1300 : 900,
                    SectionId.projects: isCompact ? 4000 : 1400,
                    SectionId.about: 1000,
                  };
                  return Column(
                    children: [
                      for (final chapter in controller.narrative.chapters)
                        SizedBox(
                          key: controller.keyFor(chapter.id),
                          height: heights[chapter.id],
                          child: chapter.id == SectionId.projects
                              ? Align(
                                  alignment: Alignment.topLeft,
                                  child: SizedBox(
                                    key: projectsHeadingKey,
                                    height: 80,
                                    width: 240,
                                  ),
                                )
                              : null,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );

      await tester.pumpWidget(document());
      await tester.pump();
      controller.refreshSectionGeometry();
      final projectsTop = controller.sectionGeometries
          .firstWhere((section) => section.id == 'projects')
          .top;
      controller.scrollController.jumpTo(projectsTop);
      await tester.pump();
      await tester.pump();

      final before = controller.narrativePosition.value;
      final beforeGeometry = controller.sectionGeometries.firstWhere(
        (section) => section.id == 'projects',
      );
      final beforeLocalOffset = before.focalPoint - beforeGeometry.top;
      expect(before.activeSectionId, 'projects');
      expect(
        tester.getTopLeft(find.byKey(projectsHeadingKey)).dy,
        closeTo(0, 1),
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pump();
      await tester.pump();

      final after = controller.narrativePosition.value;
      final afterGeometry = controller.sectionGeometries.firstWhere(
        (section) => section.id == 'projects',
      );
      final afterLocalOffset = after.focalPoint - afterGeometry.top;
      final headingRect = tester.getRect(find.byKey(projectsHeadingKey));

      expect(after.activeSectionId, 'projects');
      expect(afterLocalOffset, closeTo(beforeLocalOffset, 1));
      expect(headingRect.bottom, greaterThan(0));
      expect(headingRect.top, lessThan(100));
    },
  );
}
