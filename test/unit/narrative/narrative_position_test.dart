import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/narrative/application/narrative_position.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/section_geometry.dart';

void main() {
  const viewport = 1000.0;
  const topInset = 80.0;
  const focalOffset = topInset + (viewport - topInset) * 0.28;

  double offsetForFocal(double focalPoint) => focalPoint - focalOffset;

  NarrativePosition resolve(
    double focalPoint,
    List<SectionGeometry> sections, {
    double viewportDimension = viewport,
    double inset = topInset,
  }) => NarrativePositionResolver.resolve(
    offset:
        focalPoint -
        inset -
        (viewportDimension - inset).clamp(0.0, double.infinity) * 0.28,
    viewportDimension: viewportDimension,
    topInset: inset,
    sections: sections,
  );

  group('NarrativePosition', () {
    test('initial position is the canonical home state', () {
      expect(
        const NarrativePosition.initial(),
        const NarrativePosition(
          activeSectionId: 'home',
          currentSectionId: 'home',
          nextSectionId: 'home',
          focalPoint: 0,
          boundaryProgress: 0,
          documentProgress: 0,
        ),
      );
      expect(
        const NarrativePosition.initial().hashCode,
        const NarrativePosition(
          activeSectionId: 'home',
          currentSectionId: 'home',
          nextSectionId: 'home',
          focalPoint: 0,
          boundaryProgress: 0,
          documentProgress: 0,
        ).hashCode,
      );
    });
  });

  group('NarrativePositionResolver', () {
    test('returns the initial position for an empty document', () {
      expect(
        NarrativePositionResolver.resolve(
          offset: 400,
          viewportDimension: viewport,
          topInset: topInset,
          sections: const [],
        ),
        const NarrativePosition.initial(),
      );
    });

    test('keeps a single chapter stable while progress follows its bounds', () {
      const sections = [SectionGeometry(id: 'about', top: 200, height: 800)];

      final middle = resolve(600, sections);

      expect(middle.activeSectionId, 'about');
      expect(middle.currentSectionId, 'about');
      expect(middle.nextSectionId, 'about');
      expect(middle.boundaryProgress, 0);
      expect(middle.documentProgress, 0.5);
    });

    test('resolves the exact start, midpoint, and end of a boundary', () {
      const sections = [
        SectionGeometry(id: 'home', top: 0, height: 1000),
        SectionGeometry(id: 'about', top: 1000, height: 1000),
      ];

      final start = NarrativePositionResolver.resolve(
        offset: offsetForFocal(840),
        viewportDimension: viewport,
        topInset: topInset,
        sections: sections,
      );
      final midpoint = NarrativePositionResolver.resolve(
        offset: offsetForFocal(1000),
        viewportDimension: viewport,
        topInset: topInset,
        sections: sections,
      );
      final end = NarrativePositionResolver.resolve(
        offset: offsetForFocal(1160),
        viewportDimension: viewport,
        topInset: topInset,
        sections: sections,
      );

      expect(start.boundaryProgress, 0);
      expect(start.activeSectionId, 'home');
      expect(midpoint.boundaryProgress, 0.5);
      expect(midpoint.activeSectionId, 'about');
      expect(end.boundaryProgress, 1);
      expect(end.activeSectionId, 'about');
      for (final position in [start, midpoint, end]) {
        expect(position.currentSectionId, 'home');
        expect(position.nextSectionId, 'about');
      }
    });

    test(
      'keeps the physical handoff window independent of section heights',
      () {
        const sections = [
          SectionGeometry(id: 'home', top: 0, height: 400),
          SectionGeometry(id: 'about', top: 400, height: 4000),
          SectionGeometry(id: 'projects', top: 4400, height: 120),
        ];

        final firstStart = resolve(
          320,
          sections,
          viewportDimension: 500,
          inset: 0,
        );
        final firstEnd = resolve(
          480,
          sections,
          viewportDimension: 500,
          inset: 0,
        );
        final secondStart = resolve(
          4320,
          sections,
          viewportDimension: 500,
          inset: 0,
        );
        final secondEnd = resolve(
          4480,
          sections,
          viewportDimension: 500,
          inset: 0,
        );

        expect(firstStart.boundaryProgress, 0);
        expect(firstEnd.boundaryProgress, 1);
        expect(secondStart.boundaryProgress, 0);
        expect(secondEnd.boundaryProgress, 1);
        expect(secondStart.currentSectionId, 'about');
        expect(secondStart.nextSectionId, 'projects');
      },
    );

    test('is stable before the first and after the final handoff window', () {
      const sections = [
        SectionGeometry(id: 'home', top: 0, height: 1000),
        SectionGeometry(id: 'about', top: 1000, height: 1000),
      ];

      final before = resolve(500, sections);
      final after = resolve(1500, sections);

      expect(before.currentSectionId, 'home');
      expect(before.nextSectionId, 'home');
      expect(before.boundaryProgress, 0);
      expect(after.currentSectionId, 'about');
      expect(after.nextSectionId, 'about');
      expect(after.boundaryProgress, 0);
    });

    test('derives adjacency from the supplied optional chapter sequence', () {
      const sections = [
        SectionGeometry(id: 'home', top: 0, height: 800),
        SectionGeometry(id: 'about', top: 800, height: 1200),
        SectionGeometry(id: 'projects', top: 2000, height: 1600),
      ];

      final handoff = resolve(2000, sections);

      expect(handoff.currentSectionId, 'about');
      expect(handoff.nextSectionId, 'projects');
      expect(handoff.activeSectionId, 'projects');
      expect(handoff.boundaryProgress, 0.5);
    });

    test('document progress ends at the last section bottom', () {
      const sections = [
        SectionGeometry(id: 'home', top: 100, height: 900),
        SectionGeometry(id: 'about', top: 1000, height: 1500),
      ];

      expect(resolve(100, sections).documentProgress, 0);
      expect(resolve(2500, sections).documentProgress, 1);
      expect(resolve(9000, sections).documentProgress, 1);
    });

    test('document progress is monotonic and clamped', () {
      const sections = [
        SectionGeometry(id: 'home', top: 0, height: 700),
        SectionGeometry(id: 'about', top: 700, height: 1300),
        SectionGeometry(id: 'projects', top: 2000, height: 900),
      ];
      final positions = [
        for (final focal in [-500.0, 0.0, 350.0, 900.0, 1800.0, 2900.0, 5000.0])
          resolve(focal, sections),
      ];

      for (var index = 0; index < positions.length; index += 1) {
        expect(positions[index].documentProgress, inInclusiveRange(0, 1));
        if (index > 0) {
          expect(
            positions[index].documentProgress,
            greaterThanOrEqualTo(positions[index - 1].documentProgress),
          );
        }
      }
    });

    test('fails fast for invalid, duplicate, or unordered geometry', () {
      final invalidDocuments = <List<SectionGeometry>>[
        const [SectionGeometry(id: '', top: 0, height: 100)],
        const [SectionGeometry(id: 'home', top: 0, height: 0)],
        const [SectionGeometry(id: 'home', top: double.nan, height: 100)],
        const [
          SectionGeometry(id: 'home', top: 0, height: 100),
          SectionGeometry(id: 'home', top: 100, height: 100),
        ],
        const [
          SectionGeometry(id: 'about', top: 200, height: 100),
          SectionGeometry(id: 'home', top: 100, height: 100),
        ],
        const [
          SectionGeometry(id: 'home', top: 0, height: 200),
          SectionGeometry(id: 'about', top: 100, height: 200),
        ],
      ];

      for (final sections in invalidDocuments) {
        expect(
          () => NarrativePositionResolver.resolve(
            offset: 0,
            viewportDimension: viewport,
            topInset: topInset,
            sections: sections,
          ),
          throwsArgumentError,
        );
      }
    });

    test('fails fast for invalid viewport inputs', () {
      const sections = [SectionGeometry(id: 'home', top: 0, height: 100)];

      expect(
        () => NarrativePositionResolver.resolve(
          offset: double.nan,
          viewportDimension: viewport,
          topInset: topInset,
          sections: sections,
        ),
        throwsArgumentError,
      );
      expect(
        () => NarrativePositionResolver.resolve(
          offset: 0,
          viewportDimension: 0,
          topInset: topInset,
          sections: sections,
        ),
        throwsArgumentError,
      );
      expect(
        () => NarrativePositionResolver.resolve(
          offset: 0,
          viewportDimension: viewport,
          topInset: -1,
          sections: sections,
        ),
        throwsArgumentError,
      );
    });
  });
}
