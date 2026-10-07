import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_style.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/project_palette.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dark band that introduces the featured case studies with their count.
final class AtlasDivider extends StatelessWidget {
  const AtlasDivider({super.key, required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    const foreground = AtlasColors.dividerInk;
    final horizontal = AtlasLayout.of(context).horizontalPadding;

    return ColoredBox(
      color: AtlasColors.dividerPaper,
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontal, 22, horizontal, 20),
        child: Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: foreground.withValues(alpha: AtlasAlpha.rule),
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: AtlasText.label(
                  size: 11,
                  color: foreground,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                count.toString().padLeft(2, '0'),
                style: AtlasText.label(
                  size: 11,
                  color: foreground.withValues(alpha: AtlasAlpha.secondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One labelled paragraph of a case narrative, separated by a hairline.
final class NarrativeBeat extends StatelessWidget {
  const NarrativeBeat({
    super.key,
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final ProjectPalette palette;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 12),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: palette.ink(AtlasAlpha.rule))),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AtlasText.label(
            size: 10,
            color: palette.foreground,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppFonts.inter(
            fontSize: 14,
            color: palette.ink(AtlasAlpha.body),
            height: 1.58,
          ),
        ),
      ],
    ),
  );
}

/// The project's evidence links followed by its technology list.
final class EvidenceLinks extends StatelessWidget {
  const EvidenceLinks({
    super.key,
    required this.system,
    required this.openLabel,
    required this.palette,
  });

  final PortfolioSystem system;
  final String openLabel;
  final ProjectPalette palette;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 16),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: palette.ink(AtlasAlpha.strongRule)),
      ),
    ),
    child: Wrap(
      spacing: 24,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final evidence in system.evidence)
          AtlasLink(
            evidence: evidence,
            semanticLabel: '$openLabel: ${system.name}, ${evidence.label}',
            palette: palette,
          ),
        Text(
          system.technologies.join(' · '),
          style: AtlasText.label(
            size: 10,
            weight: FontWeight.w600,
            color: palette.ink(AtlasAlpha.caption),
          ),
        ),
      ],
    ),
  );
}

/// An external evidence link that opens in a new browser tab.
final class AtlasLink extends StatelessWidget {
  const AtlasLink({
    super.key,
    required this.evidence,
    required this.semanticLabel,
    required this.palette,
  });

  /// Keeps a long label on one line inside narrow viewports.
  static const double maxWidth = 360;
  static const double viewportInset = 48;

  final PortfolioEvidence evidence;
  final String semanticLabel;
  final ProjectPalette palette;

  @override
  Widget build(BuildContext context) {
    final width = math.min(
      maxWidth,
      MediaQuery.sizeOf(context).width - viewportInset,
    );
    return AccessibleAction(
      onTap: () => launchUrl(evidence.url, webOnlyWindowName: '_blank'),
      semanticLabel: semanticLabel,
      semanticRole: ActionSemanticRole.link,
      focusColor: palette.accent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  evidence.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtlasText.label(size: 11, color: palette.foreground),
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
