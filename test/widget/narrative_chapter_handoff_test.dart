import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    Locale locale = const Locale('en'),
    String label = 'Experience',
  }) => MediaQuery(
    data: MediaQueryData(
      size: Size(width, 800),
      disableAnimations: reducedMotion,
    ),
    child: RepositoryProvider<NarrativeDocument>.value(
      value: narrative,
      child: Localizations(
        locale: locale,
        delegates: const <LocalizationsDelegate<dynamic>>[
          GlobalWidgetsLocalizations.delegate,
        ],
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
              chapterNumber: '01',
              label: label,
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('uses one cinematic responsive portal height', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(899, 800));
    await tester.pumpWidget(subject(width: 899));
    expect(
      tester.getSize(find.byKey(const ValueKey('handoff-home-experience'))),
      const Size(899, 220),
    );

    await tester.binding.setSurfaceSize(const Size(900, 800));
    await tester.pumpWidget(subject(width: 900));
    expect(
      tester.getSize(find.byKey(const ValueKey('handoff-home-experience'))),
      const Size(900, 280),
    );

    await tester.binding.setSurfaceSize(const Size(1200, 800));
    await tester.pumpWidget(subject(width: 1200));
    expect(
      tester.getSize(find.byKey(const ValueKey('handoff-home-experience'))),
      const Size(1200, 360),
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

  test('measures full translated labels at narrow portal widths', () {
    for (final width in [280.0, 320.0]) {
      final turkish = NarrativeHandoffTypography.resolve(
        size: Size(width, 220),
        chapterNumber: '01',
        label: 'Deneyim',
        locale: const Locale('tr'),
        textDirection: TextDirection.ltr,
      );
      expect(turkish.normalizedLabel, 'DENEYİM');
      expect(turkish.railSize.width, lessThanOrEqualTo(turkish.maxRailWidth));

      final rtl = NarrativeHandoffTypography.resolve(
        size: Size(width, 220),
        chapterNumber: '01',
        label: 'الخبرة المهنية',
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
      );
      expect(rtl.normalizedLabel, 'الخبرة المهنية');
      expect(rtl.railSize.width, lessThanOrEqualTo(rtl.maxRailWidth));
      expect(rtl.titleSize.width, lessThan(width - 40));
    }
  });

  testWidgets('renders Turkish and RTL labels without paint exceptions', (
    tester,
  ) async {
    for (final variant in [
      (
        locale: const Locale('tr'),
        direction: TextDirection.ltr,
        label: 'Deneyim',
      ),
      (
        locale: const Locale('ar'),
        direction: TextDirection.rtl,
        label: 'الخبرة المهنية',
      ),
    ]) {
      await tester.pumpWidget(
        subject(
          width: 280,
          locale: variant.locale,
          textDirection: variant.direction,
          label: variant.label,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('only notifies paint while this boundary reveal changes', (
    tester,
  ) async {
    position.value = const NarrativePosition(
      activeSectionId: 'proof',
      currentSectionId: 'proof',
      nextSectionId: 'proof',
      focalPoint: 3000,
      boundaryProgress: 0,
      documentProgress: 0.6,
    );
    await tester.pumpWidget(subject(width: 1200));

    final portal = find.byKey(const ValueKey('handoff-home-experience'));
    final customPaint = tester.widget<CustomPaint>(
      find.descendant(of: portal, matching: find.byType(CustomPaint)),
    );
    var notifications = 0;
    void listener() => notifications += 1;
    customPaint.painter!.addListener(listener);
    addTearDown(() => customPaint.painter!.removeListener(listener));

    position.value = const NarrativePosition(
      activeSectionId: 'proof',
      currentSectionId: 'proof',
      nextSectionId: 'proof',
      focalPoint: 3100,
      boundaryProgress: 0.8,
      documentProgress: 0.62,
    );
    expect(notifications, 0);

    position.value = const NarrativePosition(
      activeSectionId: 'home',
      currentSectionId: 'home',
      nextSectionId: 'experience',
      focalPoint: 500,
      boundaryProgress: 0.4,
      documentProgress: 0.1,
    );
    expect(notifications, 1);

    position.value = const NarrativePosition(
      activeSectionId: 'home',
      currentSectionId: 'home',
      nextSectionId: 'experience',
      focalPoint: 540,
      boundaryProgress: 0.6,
      documentProgress: 0.12,
    );
    expect(notifications, 2);
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
