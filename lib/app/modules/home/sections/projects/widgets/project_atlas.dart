import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_labels.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_parts.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/evidence_index.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/featured_case.dart';

export 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_labels.dart';

/// Professional case studies followed by a compact selected-work index.
///
/// Every colour, image, label, URL, and line of project copy comes from the
/// external content document. The renderer has no project-specific branches.
/// Artifact images load only as their entry approaches the viewport.
final class ProjectAtlas extends StatelessWidget {
  const ProjectAtlas({super.key, required this.systems, required this.labels});

  final List<PortfolioSystem> systems;
  final ProjectAtlasLabels labels;

  @override
  Widget build(BuildContext context) {
    final featured = systems.whereType<PortfolioFeaturedSystem>().toList(
      growable: false,
    );
    final supporting = systems.whereType<PortfolioSupportingSystem>().toList(
      growable: false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (featured.isNotEmpty)
          AtlasDivider(label: labels.selectedCases, count: featured.length),
        for (var index = 0; index < featured.length; index++)
          FeaturedCase(
            key: ValueKey('project-atlas-${featured[index].id}'),
            system: featured[index],
            index: index,
            labels: labels,
          ),
        if (supporting.isNotEmpty)
          EvidenceIndex(
            key: const ValueKey('project-evidence-index'),
            systems: supporting,
            labels: labels,
          ),
      ],
    );
  }
}
