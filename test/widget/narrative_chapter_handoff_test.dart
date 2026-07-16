import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/narrative/application/narrative_position.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/widgets/narrative_chapter_handoff.dart';

import '../helpers/narrative_fixture.dart';

void main() {
  late ValueNotifier<NarrativePosition> position;
  late NarrativeDocument narrative;

  setUp(() {
    position = ValueNotifier(const NarrativePosition.initial());
    narrative = loadNarrativeFixture();
    addTearDown(position.dispose);
  });

  Widget subject({
    required double width,
    TextDirection textDirection = TextDirection.ltr,
    bool reducedMotion = false,
  }) => MediaQuery(
    data: MediaQueryData(
      size: Size(width, 800),
      disableAnimations: reducedMotion,
    ),
    child: RepositoryProvider<NarrativeDocument>.value(
      value: narrative,
      child: Directionality(
        textDirection: textDirection,
        child: Align(
          alignment: Alignment.topLeft,
          child: NarrativeChapterHandoff(
            from: const NarrativeChapter(
              id: SectionId.home,
              motif: NarrativeMotif.origin,
            ),
            to: const NarrativeChapter(
              id: SectionId.experience,
              motif: NarrativeMotif.timeline,
            ),
            position: position,
          ),
        ),
      ),
    ),
  );

  testWidgets('uses one restrained responsive boundary height', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(899, 800));
    await tester.pumpWidget(subject(width: 899));
    expect(
      tester.getSize(find.byKey(const ValueKey('handoff-home-experience'))),
      const Size(899, 72),
    );

    await tester.binding.setSurfaceSize(const Size(900, 800));
    await tester.pumpWidget(subject(width: 900));
    expect(
      tester.getSize(find.byKey(const ValueKey('handoff-home-experience'))),
      const Size(900, 112),
    );
  });

  testWidgets('stays decorative in LTR, RTL, and reduced motion', (
    tester,
  ) async {
    for (final direction in TextDirection.values) {
      await tester.pumpWidget(
        subject(width: 1200, textDirection: direction, reducedMotion: true),
      );
      final bridge = find.byKey(const ValueKey('handoff-home-experience'));
      expect(bridge, findsOneWidget);
      expect(
        find.descendant(of: bridge, matching: find.byType(Text)),
        findsNothing,
      );
      expect(
        find.descendant(of: bridge, matching: find.byType(GestureDetector)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    }
  });

  test('keeps past boundaries revealed and future boundaries quiet', () {
    final chapters = narrative.chapters;
    final home = chapters[0];
    final experience = chapters[1];
    final projects = chapters[3];
    final about = chapters[4];

    const activeBoundary = NarrativePosition(
      activeSectionId: 'home',
      currentSectionId: 'home',
      nextSectionId: 'experience',
      focalPoint: 800,
      boundaryProgress: 0.4,
      documentProgress: 0.18,
    );
    expect(
      NarrativeHandoffReveal.resolve(
        snapshot: activeBoundary,
        chapterOrder: chapters,
        from: home,
        to: experience,
        reducedMotion: false,
      ),
      0.4,
    );

    const laterBoundary = NarrativePosition(
      activeSectionId: 'proof',
      currentSectionId: 'proof',
      nextSectionId: 'projects',
      focalPoint: 3200,
      boundaryProgress: 0.25,
      documentProgress: 0.68,
    );
    expect(
      NarrativeHandoffReveal.resolve(
        snapshot: laterBoundary,
        chapterOrder: chapters,
        from: home,
        to: experience,
        reducedMotion: false,
      ),
      1,
    );
    expect(
      NarrativeHandoffReveal.resolve(
        snapshot: laterBoundary,
        chapterOrder: chapters,
        from: projects,
        to: about,
        reducedMotion: false,
      ),
      0,
    );
  });

  test('reduced motion exposes the complete static handoff', () {
    expect(
      NarrativeHandoffReveal.resolve(
        snapshot: const NarrativePosition.initial(),
        chapterOrder: narrative.chapters,
        from: narrative.chapters[3],
        to: narrative.chapters[4],
        reducedMotion: true,
      ),
      1,
    );
  });
}
