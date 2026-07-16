import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:url_launcher/url_launcher.dart';

@immutable
final class ProjectAtlasLabels {
  const ProjectAtlasLabels({
    required this.challenge,
    required this.approach,
    required this.outcome,
    required this.ownership,
    required this.decision,
    required this.evidence,
    required this.openProject,
    required this.openEvidence,
  });

  final String challenge;
  final String approach;
  final String outcome;
  final String ownership;
  final String decision;
  final String evidence;
  final String openProject;
  final String openEvidence;
}

/// A full-width work atlas: every project is a chapter, never a card.
///
/// Project colours, visual grammar, labels, copy, and artifacts come from the
/// external content document. The Flutter layer only composes those authored
/// ingredients into a reusable sequence.
final class ProjectAtlas extends StatelessWidget {
  const ProjectAtlas({super.key, required this.systems, required this.labels});

  final List<PortfolioSystem> systems;
  final ProjectAtlasLabels labels;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var index = 0; index < systems.length; index++)
        _ProjectAtlasChapter(
          key: ValueKey('project-atlas-${systems[index].id}'),
          system: systems[index],
          index: index,
          labels: labels,
        ),
    ],
  );
}

final class _ProjectAtlasChapter extends StatelessWidget {
  const _ProjectAtlasChapter({
    super.key,
    required this.system,
    required this.index,
    required this.labels,
  });

  final PortfolioSystem system;
  final int index;
  final ProjectAtlasLabels labels;

  @override
  Widget build(BuildContext context) {
    final palette = _ProjectPalette.from(system.presentation);
    final width = MediaQuery.sizeOf(context).width;
    final tablet = width >= Breakpoints.tablet;
    final desktop = width >= Breakpoints.desktop;
    final horizontal = width > AppDimensions.maxContentWidth
        ? AppDimensions.sectionPaddingDesktop
        : tablet
        ? AppDimensions.sectionPaddingTablet
        : AppDimensions.sectionPaddingMobile;
    final minimumHeight = desktop
        ? (system is PortfolioFeaturedSystem ? 860.0 : 720.0)
        : tablet
        ? 780.0
        : 740.0;

    return Semantics(
      container: true,
      label:
          '${system.name}. ${system.kind}. ${system.year}. ${system.summary}',
      child: ColoredBox(
        color: palette.background,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minimumHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              desktop ? 52 : 38,
              horizontal,
              desktop ? 58 : 42,
            ),
            child: desktop
                ? _DesktopChapter(
                    system: system,
                    index: index,
                    labels: labels,
                    palette: palette,
                  )
                : _CompactChapter(
                    system: system,
                    index: index,
                    labels: labels,
                    palette: palette,
                  ),
          ),
        ),
      ),
    );
  }
}

final class _DesktopChapter extends StatelessWidget {
  const _DesktopChapter({
    required this.system,
    required this.index,
    required this.labels,
    required this.palette,
  });

  final PortfolioSystem system;
  final int index;
  final ProjectAtlasLabels labels;
  final _ProjectPalette palette;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ChapterRail(system: system, index: index, palette: palette),
      const SizedBox(height: 30),
      _ProjectTitle(system: system, palette: palette),
      const SizedBox(height: 42),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: SizedBox(
              height: system is PortfolioFeaturedSystem ? 700 : 540,
              child: _ProjectVisual(system: system, palette: palette),
            ),
          ),
          const SizedBox(width: 72),
          Expanded(
            flex: 4,
            child: _ProjectNarrative(
              system: system,
              labels: labels,
              palette: palette,
            ),
          ),
        ],
      ),
      const SizedBox(height: 34),
      _ProjectFooter(system: system, labels: labels, palette: palette),
    ],
  );
}

final class _CompactChapter extends StatelessWidget {
  const _CompactChapter({
    required this.system,
    required this.index,
    required this.labels,
    required this.palette,
  });

  final PortfolioSystem system;
  final int index;
  final ProjectAtlasLabels labels;
  final _ProjectPalette palette;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ChapterRail(system: system, index: index, palette: palette),
      _ProjectTitle(system: system, palette: palette),
      const SizedBox(height: 28),
      _ProjectVisual(system: system, palette: palette),
      const SizedBox(height: 30),
      _ProjectNarrative(system: system, labels: labels, palette: palette),
      const SizedBox(height: 28),
      _ProjectFooter(system: system, labels: labels, palette: palette),
    ],
  );
}

final class _ChapterRail extends StatelessWidget {
  const _ChapterRail({
    required this.system,
    required this.index,
    required this.palette,
  });

  final PortfolioSystem system;
  final int index;
  final _ProjectPalette palette;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(bottom: 13),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: palette.foreground.withValues(alpha: 0.3)),
      ),
    ),
    child: Row(
      children: [
        Text(
          '${index + 1}'.padLeft(2, '0'),
          style: AppFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: palette.accent,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Text(
            system.kind,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.foreground,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Text(
          system.year,
          style: AppFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.foreground.withValues(alpha: 0.72),
          ),
        ),
      ],
    ),
  );
}

final class _ProjectTitle extends StatelessWidget {
  const _ProjectTitle({required this.system, required this.palette});

  final PortfolioSystem system;
  final _ProjectPalette palette;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final fontSize = width >= Breakpoints.desktop
        ? (width * 0.061).clamp(66.0, 94.0)
        : (width * 0.115).clamp(42.0, 72.0);
    return Semantics(
      header: true,
      headingLevel: 3,
      label: system.name,
      excludeSemantics: true,
      child: ExcludeSemantics(
        child: Text(
          system.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.spaceGrotesk(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: palette.foreground,
            height: 0.94,
            letterSpacing: -fontSize * 0.047,
          ),
        ),
      ),
    );
  }
}

final class _ProjectVisual extends StatelessWidget {
  const _ProjectVisual({required this.system, required this.palette});

  final PortfolioSystem system;
  final _ProjectPalette palette;

  @override
  Widget build(BuildContext context) {
    if (system case final PortfolioSupportingSystem supporting) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final portrait =
              supporting.artifact.composition ==
              PortfolioArtifactComposition.portraitSplit;
          final narrow = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
          if (portrait && narrow) {
            return SizedBox(
              height: 470,
              child: _CompactPortraitArtifactVisual(
                system: supporting,
                palette: palette,
              ),
            );
          }
          final visual = _ArtifactVisual(system: supporting, palette: palette);
          if (constraints.hasBoundedHeight) return visual;
          return SizedBox(height: portrait ? 470 : 360, child: visual);
        },
      );
    }
    return AspectRatio(
      aspectRatio: 1.5,
      child: CustomPaint(
        painter: _ProjectSignalPainter(
          kind: system.presentation.visual.kind,
          labels: system.presentation.visual.labels,
          foreground: palette.foreground,
          accent: palette.accent,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

final class _CompactPortraitArtifactVisual extends StatelessWidget {
  const _CompactPortraitArtifactVisual({
    required this.system,
    required this.palette,
  });

  final PortfolioSupportingSystem system;
  final _ProjectPalette palette;

  @override
  Widget build(BuildContext context) {
    final artifact = system.artifact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          artifact.label,
          style: AppFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: palette.accent,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 22),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 7,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Semantics(
                    image: true,
                    label: artifact.alt,
                    excludeSemantics: true,
                    child: ExcludeSemantics(
                      child: Image.asset(
                        artifact.asset,
                        fit: BoxFit.contain,
                        alignment: AlignmentDirectional.centerStart,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    artifact.caption,
                    style: AppFonts.inter(
                      fontSize: 11,
                      color: palette.foreground.withValues(alpha: 0.74),
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _ArtifactVisual extends StatelessWidget {
  const _ArtifactVisual({required this.system, required this.palette});

  final PortfolioSupportingSystem system;
  final _ProjectPalette palette;

  @override
  Widget build(BuildContext context) {
    final artifact = system.artifact;
    final portrait =
        artifact.composition == PortfolioArtifactComposition.portraitSplit;
    final alignment = switch (artifact.alignment) {
      PortfolioArtifactAlignment.start => AlignmentDirectional.centerStart,
      PortfolioArtifactAlignment.center => Alignment.center,
      PortfolioArtifactAlignment.end => AlignmentDirectional.centerEnd,
    };
    final fit = switch (artifact.fit) {
      PortfolioArtifactFit.contain => BoxFit.contain,
      PortfolioArtifactFit.cover => BoxFit.cover,
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        PositionedDirectional(
          start: 0,
          top: 0,
          child: Text(
            artifact.label,
            style: AppFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: palette.accent,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 34, bottom: portrait ? 0 : 12),
          child: Align(
            alignment: alignment,
            child: Semantics(
              image: true,
              label: artifact.alt,
              excludeSemantics: true,
              child: ExcludeSemantics(
                child: Image.asset(
                  artifact.asset,
                  fit: fit,
                  alignment: alignment,
                  width: portrait ? 300 : double.infinity,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          end: 0,
          bottom: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              artifact.caption,
              textAlign: TextAlign.end,
              style: AppFonts.inter(
                fontSize: 11,
                color: palette.foreground.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final class _ProjectNarrative extends StatelessWidget {
  const _ProjectNarrative({
    required this.system,
    required this.labels,
    required this.palette,
  });

  final PortfolioSystem system;
  final ProjectAtlasLabels labels;
  final _ProjectPalette palette;

  @override
  Widget build(BuildContext context) {
    final beats = system is PortfolioFeaturedSystem
        ? <({String label, String value})>[
            (
              label: labels.challenge,
              value: (system as PortfolioFeaturedSystem).challenge,
            ),
            (
              label: labels.approach,
              value: (system as PortfolioFeaturedSystem).approach,
            ),
            (
              label: labels.outcome,
              value: (system as PortfolioFeaturedSystem).outcome,
            ),
          ]
        : <({String label, String value})>[
            (label: labels.ownership, value: system.ownership),
            (label: labels.decision, value: system.decision),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          system.summary,
          style: AppFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: palette.foreground,
            height: 1.28,
            letterSpacing: -0.45,
          ),
        ),
        const SizedBox(height: 28),
        for (var index = 0; index < beats.length; index++) ...[
          if (index > 0) const SizedBox(height: 22),
          _NarrativeBeat(
            label: beats[index].label,
            value: beats[index].value,
            palette: palette,
          ),
        ],
      ],
    );
  }
}

final class _NarrativeBeat extends StatelessWidget {
  const _NarrativeBeat({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final _ProjectPalette palette;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 12),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: palette.foreground.withValues(alpha: 0.28)),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: palette.accent,
            letterSpacing: 0.25,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppFonts.inter(
            fontSize: 14,
            color: palette.foreground.withValues(alpha: 0.82),
            height: 1.55,
          ),
        ),
      ],
    ),
  );
}

final class _ProjectFooter extends StatelessWidget {
  const _ProjectFooter({
    required this.system,
    required this.labels,
    required this.palette,
  });

  final PortfolioSystem system;
  final ProjectAtlasLabels labels;
  final _ProjectPalette palette;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 16),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: palette.foreground.withValues(alpha: 0.3)),
      ),
    ),
    child: Wrap(
      spacing: 24,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _AtlasLink(
          label: labels.openProject,
          semanticLabel: '${labels.openProject}: ${system.name}',
          url: system.url,
          palette: palette,
        ),
        for (final evidence in system.evidence)
          _AtlasLink(
            label: evidence.label,
            semanticLabel:
                '${labels.openEvidence}: ${system.name}, ${evidence.label}',
            url: evidence.url,
            palette: palette,
          ),
        Text(
          system.technologies.join(' · '),
          style: AppFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: palette.foreground.withValues(alpha: 0.68),
          ),
        ),
      ],
    ),
  );
}

final class _AtlasLink extends StatelessWidget {
  const _AtlasLink({
    required this.label,
    required this.semanticLabel,
    required this.url,
    required this.palette,
  });

  final String label;
  final String semanticLabel;
  final Uri url;
  final _ProjectPalette palette;

  @override
  Widget build(BuildContext context) {
    final maxWidth = math.min(360.0, MediaQuery.sizeOf(context).width - 48);
    return CinematicFocusable(
      onTap: () => launchUrl(url, webOnlyWindowName: '_blank'),
      semanticLabel: semanticLabel,
      semanticRole: CinematicControlRole.link,
      focusColor: palette.accent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: palette.foreground,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Icon(Icons.north_east_rounded, size: 15, color: palette.accent),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ProjectSignalPainter extends CustomPainter {
  const _ProjectSignalPainter({
    required this.kind,
    required this.labels,
    required this.foreground,
    required this.accent,
  });

  final PortfolioSystemVisualKind kind;
  final List<String> labels;
  final Color foreground;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = foreground.withValues(alpha: 0.5);
    final strong = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square
      ..color = accent;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = foreground;

    canvas.drawRect(Offset.zero & size, line);
    switch (kind) {
      case PortfolioSystemVisualKind.network:
        _drawNetwork(canvas, size, line, strong, fill);
        break;
      case PortfolioSystemVisualKind.flow:
        _drawFlow(canvas, size, line, strong, fill);
        break;
      case PortfolioSystemVisualKind.lanes:
        _drawLanes(canvas, size, line, strong, fill);
        break;
      case PortfolioSystemVisualKind.artifact:
        break;
    }
  }

  void _drawNetwork(
    Canvas canvas,
    Size size,
    Paint line,
    Paint strong,
    Paint fill,
  ) {
    final points = <Offset>[
      Offset(size.width * 0.15, size.height * 0.2),
      Offset(size.width * 0.72, size.height * 0.17),
      Offset(size.width * 0.42, size.height * 0.52),
      Offset(size.width * 0.82, size.height * 0.77),
    ];
    for (var index = 0; index < points.length; index++) {
      for (var next = index + 1; next < points.length; next++) {
        canvas.drawLine(points[index], points[next], line);
      }
    }
    for (var index = 0; index < points.length; index++) {
      canvas.drawCircle(points[index], index == 2 ? 12 : 7, fill);
      _drawLabel(
        canvas,
        labels[index % labels.length],
        points[index] + const Offset(14, 14),
      );
    }
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.9),
      Offset(size.width * 0.9, size.height * 0.9),
      strong,
    );
  }

  void _drawFlow(
    Canvas canvas,
    Size size,
    Paint line,
    Paint strong,
    Paint fill,
  ) {
    final step = size.width / (labels.length + 1);
    final y = size.height * 0.5;
    for (var index = 0; index < labels.length; index++) {
      final x = step * (index + 1);
      if (index > 0) {
        canvas.drawLine(Offset(x - step + 16, y), Offset(x - 16, y), line);
      }
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 20, height: 20),
        index.isEven ? fill : strong,
      );
      _drawLabel(canvas, labels[index], Offset(x - 26, y + 30));
    }
    canvas.drawLine(
      Offset(step, size.height * 0.18),
      Offset(step * labels.length, size.height * 0.18),
      strong,
    );
  }

  void _drawLanes(
    Canvas canvas,
    Size size,
    Paint line,
    Paint strong,
    Paint fill,
  ) {
    final laneHeight = size.height / (labels.length + 1);
    for (var index = 0; index < labels.length; index++) {
      final y = laneHeight * (index + 1);
      canvas.drawLine(
        Offset(size.width * 0.08, y),
        Offset(size.width * 0.92, y),
        index == labels.length - 1 ? strong : line,
      );
      final markerX = size.width * (0.22 + (index * 0.17) % 0.56);
      canvas.drawRect(
        Rect.fromLTWH(markerX, y - 6, math.max(18, size.width * 0.08), 12),
        fill,
      );
      _drawLabel(canvas, labels[index], Offset(size.width * 0.08, y - 25));
    }
  }

  void _drawLabel(Canvas canvas, String label, Offset offset) {
    TextPainter(
        text: TextSpan(
          text: label.toUpperCase(),
          style: TextStyle(
            color: foreground,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )
      ..layout(maxWidth: 140)
      ..paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_ProjectSignalPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.labels != labels ||
      oldDelegate.foreground != foreground ||
      oldDelegate.accent != accent;
}

@immutable
final class _ProjectPalette {
  const _ProjectPalette({
    required this.background,
    required this.foreground,
    required this.accent,
  });

  factory _ProjectPalette.from(PortfolioSystemPresentation value) =>
      _ProjectPalette(
        background: _hexColor(value.background),
        foreground: _hexColor(value.foreground),
        accent: _hexColor(value.accent),
      );

  final Color background;
  final Color foreground;
  final Color accent;
}

Color _hexColor(String value) =>
    Color(int.parse('FF${value.substring(1)}', radix: 16));
