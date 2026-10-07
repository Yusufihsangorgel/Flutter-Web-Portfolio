import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/artifact_stage.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_labels.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_parts.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_style.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/project_palette.dart';

/// One full-width professional case study on its content-authored palette.
final class FeaturedCase extends StatelessWidget {
  const FeaturedCase({
    super.key,
    required this.system,
    required this.index,
    required this.labels,
  });

  final PortfolioFeaturedSystem system;
  final int index;
  final ProjectAtlasLabels labels;

  @override
  Widget build(BuildContext context) {
    final palette = ProjectPalette.from(system.presentation);
    final layout = AtlasLayout.of(context);
    final horizontal = layout.horizontalPadding;
    final desktop = layout.desktop;
    final story = _CaseStory(system: system, labels: labels, palette: palette);

    return Semantics(
      container: true,
      label:
          '${system.name}. ${system.kind}. ${system.year}. ${system.summary}',
      child: ColoredBox(
        color: palette.background,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            desktop ? 52 : 38,
            horizontal,
            desktop ? 72 : 54,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CaseRail(
                system: system,
                marker:
                    '${labels.caseLabel.toUpperCase()} '
                    '${(index + 1).toString().padLeft(2, '0')}',
                palette: palette,
              ),
              SizedBox(height: desktop ? 42 : 30),
              CaseTitle(system: system, palette: palette),
              SizedBox(height: layout.tablet ? 44 : 30),
              if (desktop)
                _DesktopCaseBody(story: story, artifactFirst: index.isEven)
              else
                _CompactCaseBody(story: story),
              SizedBox(height: desktop ? 42 : 32),
              EvidenceLinks(
                system: system,
                openLabel: labels.openEvidence,
                palette: palette,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Case number, kind, and year above a hairline.
final class CaseRail extends StatelessWidget {
  const CaseRail({
    super.key,
    required this.system,
    required this.marker,
    required this.palette,
  });

  final PortfolioFeaturedSystem system;
  final String marker;
  final ProjectPalette palette;

  @override
  Widget build(BuildContext context) {
    final caseMarker = Text(
      marker,
      style: AtlasText.label(
        size: 11,
        color: palette.foreground,
        letterSpacing: 0.7,
      ),
    );
    final year = Text(
      system.year,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: AtlasText.label(
        size: 12,
        weight: FontWeight.w600,
        color: palette.ink(AtlasAlpha.meta),
      ),
    );
    final kind = Text(
      system.kind,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AtlasText.label(
        size: 12,
        weight: FontWeight.w600,
        color: palette.foreground,
      ),
    );

    return Container(
      padding: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.ink(AtlasAlpha.strongRule)),
        ),
      ),
      child: AtlasLayout.of(context).narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    caseMarker,
                    const SizedBox(width: 20),
                    Expanded(child: year),
                  ],
                ),
                const SizedBox(height: 9),
                kind,
              ],
            )
          : Row(
              children: [
                caseMarker,
                const SizedBox(width: 26),
                Expanded(child: kind),
                const SizedBox(width: 20),
                year,
              ],
            ),
    );
  }
}

/// The case name as a level-3 heading that scales with the viewport.
final class CaseTitle extends StatelessWidget {
  const CaseTitle({super.key, required this.system, required this.palette});

  final PortfolioFeaturedSystem system;
  final ProjectPalette palette;

  /// Font size for a viewport [width]: viewport-relative, clamped per layout.
  static double fontSizeFor(double width) => AtlasLayout.forWidth(width).desktop
      ? (width * 0.052).clamp(60.0, 82.0)
      : (width * 0.11).clamp(42.0, 66.0);

  @override
  Widget build(BuildContext context) {
    final fontSize = fontSizeFor(MediaQuery.sizeOf(context).width);

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
            height: 0.95,
            letterSpacing: -fontSize * 0.047,
          ),
        ),
      ),
    );
  }
}

/// The parts of a case that both body layouts arrange.
final class _CaseStory {
  const _CaseStory({
    required this.system,
    required this.labels,
    required this.palette,
  });

  final PortfolioFeaturedSystem system;
  final ProjectAtlasLabels labels;
  final ProjectPalette palette;

  Widget artifact() => ArtifactStage(
    system: system,
    palette: palette,
    rendering: ArtifactRendering.featured,
  );

  Widget narrative() =>
      CaseNarrative(system: system, labels: labels, palette: palette);
}

final class _DesktopCaseBody extends StatelessWidget {
  const _DesktopCaseBody({required this.story, required this.artifactFirst});

  final _CaseStory story;
  final bool artifactFirst;

  @override
  Widget build(BuildContext context) {
    final artifact = Expanded(
      flex: AtlasLayout.artifactFlex,
      child: story.artifact(),
    );
    final narrative = Expanded(
      flex: AtlasLayout.narrativeFlex,
      child: story.narrative(),
    );
    const gap = SizedBox(width: AtlasLayout.columnGap);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: artifactFirst
          ? [artifact, gap, narrative]
          : [narrative, gap, artifact],
    );
  }
}

final class _CompactCaseBody extends StatelessWidget {
  const _CompactCaseBody({required this.story});

  final _CaseStory story;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [story.artifact(), const SizedBox(height: 34), story.narrative()],
  );
}

/// Summary followed by the problem, approach, and result beats.
final class CaseNarrative extends StatelessWidget {
  const CaseNarrative({
    super.key,
    required this.system,
    required this.labels,
    required this.palette,
  });

  final PortfolioFeaturedSystem system;
  final ProjectAtlasLabels labels;
  final ProjectPalette palette;

  @override
  Widget build(BuildContext context) {
    final beats = <({String label, String value})>[
      (label: labels.challenge, value: system.challenge),
      (label: labels.approach, value: system.approach),
      (label: labels.outcome, value: system.outcome),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          system.summary,
          style: AppFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: palette.foreground,
            height: 1.25,
            letterSpacing: -0.55,
          ),
        ),
        const SizedBox(height: 30),
        for (var index = 0; index < beats.length; index++) ...[
          if (index > 0) const SizedBox(height: 24),
          NarrativeBeat(
            label: beats[index].label,
            value: beats[index].value,
            palette: palette,
          ),
        ],
      ],
    );
  }
}
