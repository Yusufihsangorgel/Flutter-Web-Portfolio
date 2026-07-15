import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:url_launcher/url_launcher.dart';

@immutable
final class ProjectChapterLabels {
  const ProjectChapterLabels({
    required this.challenge,
    required this.approach,
    required this.outcome,
    required this.evidence,
    required this.openProject,
    required this.openEvidence,
  });

  final String challenge;
  final String approach;
  final String outcome;
  final String evidence;
  final String openProject;
  final String openEvidence;
}

/// A featured project rendered as an editorial case-study chapter.
///
/// The chapter keeps the same reading order at every viewport size. Wider
/// screens introduce a restrained offset instead of reversing the content or
/// arranging it as a card grid.
final class EditorialProjectChapter extends StatelessWidget {
  const EditorialProjectChapter({
    super.key,
    required this.system,
    required this.index,
    required this.labels,
  });

  final PortfolioSystem system;
  final int index;
  final ProjectChapterLabels labels;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1040;
      final introduction = _ProjectIntroduction(
        system: system,
        index: index,
        openLabel: labels.openProject,
      );
      final narrative = _ProjectNarrative(system: system, labels: labels);

      return Container(
        padding: EdgeInsetsDirectional.only(
          start: wide && index.isOdd ? 68 : 0,
          top: wide ? 78 : 54,
          bottom: wide ? 78 : 54,
        ),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x33F2F0E9))),
        ),
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: index.isOdd ? 8 : 9, child: introduction),
                  const SizedBox(width: 86),
                  Expanded(flex: index.isOdd ? 12 : 11, child: narrative),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [introduction, const SizedBox(height: 52), narrative],
              ),
      );
    },
  );
}

final class _ProjectIntroduction extends StatelessWidget {
  const _ProjectIntroduction({
    required this.system,
    required this.index,
    required this.openLabel,
  });

  final PortfolioSystem system;
  final int index;
  final String openLabel;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${index + 1}'.padLeft(2, '0'),
              style: AppFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.heroAccent,
                letterSpacing: 0.7,
              ),
            ),
            Text(
              system.year,
              style: AppFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              system.kind,
              style: AppFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Semantics(
          header: true,
          headingLevel: 3,
          label: system.name,
          excludeSemantics: true,
          child: ExcludeSemantics(
            child: Text(
              system.name,
              style: AppFonts.spaceGrotesk(
                fontSize: compact ? 42 : 60,
                fontWeight: FontWeight.w600,
                color: AppColors.textBright,
                height: 0.98,
                letterSpacing: compact ? -1.4 : -2.1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 25),
        Text(
          system.summary,
          style: AppFonts.inter(
            fontSize: 16,
            color: AppColors.textPrimary,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 28),
        _TextLink(
          label: openLabel,
          semanticLabel: '$openLabel: ${system.name}',
          url: system.url,
        ),
      ],
    );
  }
}

final class _ProjectNarrative extends StatelessWidget {
  const _ProjectNarrative({required this.system, required this.labels});

  final PortfolioSystem system;
  final ProjectChapterLabels labels;

  @override
  Widget build(BuildContext context) {
    final independentEvidence = system.evidence
        .where((item) => item.url != system.url)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NarrativeBeat(
          key: ValueKey('project-beat-${system.id}-challenge'),
          label: labels.challenge,
          value: system.challenge!,
        ),
        const SizedBox(height: 34),
        _NarrativeBeat(
          key: ValueKey('project-beat-${system.id}-approach'),
          label: labels.approach,
          value: system.approach!,
        ),
        const SizedBox(height: 34),
        _NarrativeBeat(
          key: ValueKey('project-beat-${system.id}-outcome'),
          label: labels.outcome,
          value: system.outcome!,
        ),
        if (independentEvidence.isNotEmpty) ...[
          const SizedBox(height: 46),
          _EvidenceIndex(
            evidence: independentEvidence,
            projectId: system.id,
            projectName: system.name,
            labels: labels,
          ),
        ],
      ],
    );
  }
}

final class _NarrativeBeat extends StatelessWidget {
  const _NarrativeBeat({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 18,
        height: 1,
        margin: const EdgeInsetsDirectional.only(top: 10, end: 14),
        color: AppColors.heroAccent,
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: AppFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textBright,
                height: 1.52,
                letterSpacing: -0.25,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

final class _EvidenceIndex extends StatelessWidget {
  const _EvidenceIndex({
    required this.evidence,
    required this.projectId,
    required this.projectName,
    required this.labels,
  });

  final List<PortfolioEvidence> evidence;
  final String projectId;
  final String projectName;
  final ProjectChapterLabels labels;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        labels.evidence,
        style: AppFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
      const SizedBox(height: 14),
      DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x33F2F0E9))),
        ),
        child: Column(
          children: [
            for (var index = 0; index < evidence.length; index++)
              _EvidenceLink(
                key: ValueKey('project-evidence-$projectId-$index'),
                evidence: evidence[index],
                projectName: projectName,
                openLabel: labels.openEvidence,
              ),
          ],
        ),
      ),
    ],
  );
}

final class _EvidenceLink extends StatelessWidget {
  const _EvidenceLink({
    super.key,
    required this.evidence,
    required this.projectName,
    required this.openLabel,
  });

  final PortfolioEvidence evidence;
  final String projectName;
  final String openLabel;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: () => launchUrl(evidence.url, webOnlyWindowName: '_blank'),
    semanticLabel:
        '$openLabel: $projectName, ${evidence.label}, ${evidence.kind}',
    semanticRole: CinematicControlRole.link,
    focusColor: AppColors.heroAccent,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x24F2F0E9))),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  evidence.label,
                  style: AppFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBright,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Flexible(
                child: Text(
                  evidence.kind,
                  textAlign: TextAlign.end,
                  style: AppFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.north_east_rounded,
                size: 16,
                color: AppColors.heroAccent,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final class _TextLink extends StatelessWidget {
  const _TextLink({
    required this.label,
    required this.semanticLabel,
    required this.url,
  });

  final String label;
  final String semanticLabel;
  final Uri url;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: () => launchUrl(url, webOnlyWindowName: '_blank'),
    semanticLabel: semanticLabel,
    semanticRole: CinematicControlRole.link,
    focusColor: AppColors.heroAccent,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textBright,
              ),
            ),
            const SizedBox(width: 9),
            const Icon(
              Icons.north_east_rounded,
              size: 17,
              color: AppColors.heroAccent,
            ),
          ],
        ),
      ),
    ),
  );
}
