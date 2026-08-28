import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reading order for package categories. Deliberately fixed rather than
/// derived from content order so the section groups the same way every time.
const _categoryOrder = [
  'native-ffi',
  'ai-llm',
  'server',
  'flutter-ui',
  'dev-tool',
];

const _categoryLabels = <String, String>{
  'native-ffi': 'Native & FFI',
  'ai-llm': 'AI & LLM',
  'server': 'Server-side Dart',
  'flutter-ui': 'Flutter UI',
  'dev-tool': 'Developer tools',
};

/// Localized copy shared by every package row.
final class _PackageLabels {
  const _PackageLabels({
    required this.pubPoints,
    required this.open,
    required this.maturity,
    required this.roadmap,
    required this.statusNames,
  });

  final String pubPoints;
  final String open;
  final String maturity;
  final String roadmap;

  /// Status keyword (`done`/`doing`/`next`/`waiting`) to localized word.
  final Map<String, String> statusNames;
}

/// Every published pub.dev package, grouped by category, each card carrying
/// its one measured proof line and a live roadmap with per-item status.
/// Bot-shaped vanity metrics (raw download counts) are deliberately absent.
class PackagesSection extends StatelessWidget {
  const PackagesSection({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) {
          final language = context.read<LanguageCubit>();
          final portfolio = context.read<PortfolioDocument>();
          final packages = portfolio.packages;
          if (packages.isEmpty) return const SizedBox.shrink();

          final perfect = packages
              .where((package) => package.pubPoints == 160)
              .length;
          final subtitle = language
              .getText(
                'packages_section.subtitle',
                defaultValue:
                    '{count} packages live on pub.dev, {perfect} of them at '
                    'a perfect 160/160 score. Each one ships a measured '
                    'claim, runnable examples, and the roadmap it is on.',
              )
              .replaceAll('{count}', '${packages.length}')
              .replaceAll('{perfect}', '$perfect');
          final labels = _PackageLabels(
            pubPoints: language.getText(
              'packages_section.pub_points',
              defaultValue: 'pub points',
            ),
            open: language.getText(
              'packages_section.open_package',
              defaultValue: 'Open on pub.dev',
            ),
            maturity: language.getText(
              'packages_section.maturity',
              defaultValue: 'maturity',
            ),
            roadmap: language.getText(
              'packages_section.roadmap',
              defaultValue: 'roadmap',
            ),
            statusNames: {
              'done': language.getText(
                'packages_section.status_done',
                defaultValue: 'shipped',
              ),
              'doing': language.getText(
                'packages_section.status_doing',
                defaultValue: 'in progress',
              ),
              'next': language.getText(
                'packages_section.status_next',
                defaultValue: 'next',
              ),
              'waiting': language.getText(
                'packages_section.status_waiting',
                defaultValue: 'waiting',
              ),
            },
          );

          final grouped = <String, List<PortfolioPackage>>{};
          for (final package in packages) {
            grouped.putIfAbsent(package.category, () => []).add(package);
          }
          final groups = [
            for (final category in _categoryOrder)
              if (grouped[category] case final entries? when entries.isNotEmpty)
                (label: _categoryLabels[category]!, packages: entries),
          ];

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SceneAccentBuilder(
                  builder: (context, accent) => NumberedSectionHeading(
                    number: context.read<NarrativeDocument>().sectionNumber(
                      SectionId.packages,
                    ),
                    title: language.getText(
                      'packages_section.title',
                      defaultValue: 'Published Packages',
                    ),
                    accent: accent,
                    anchorKey: context.read<AppScrollController>().anchorKeyFor(
                      SectionId.packages,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Text(
                    subtitle,
                    style: AppFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                SceneAccentBuilder(
                  builder: (context, accent) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var index = 0; index < groups.length; index++)
                        Padding(
                          padding: EdgeInsets.only(top: index == 0 ? 0 : 48),
                          child: _PackageCategoryGroup(
                            label: groups[index].label,
                            packages: groups[index].packages,
                            accent: accent,
                            labels: labels,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _PackageCategoryGroup extends StatelessWidget {
  const _PackageCategoryGroup({
    required this.label,
    required this.packages,
    required this.accent,
    required this.labels,
  });

  final String label;
  final List<PortfolioPackage> packages;
  final Color accent;
  final _PackageLabels labels;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        headingLevel: 3,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            Text(
              label,
              style: AppFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textBright,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              packages.length.toString().padLeft(2, '0'),
              style: AppFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: accent,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      for (var index = 0; index < packages.length; index++)
        _PackageRow(
          package: packages[index],
          accent: accent,
          labels: labels,
          isLast: index == packages.length - 1,
        ),
    ],
  );
}

class _PackageRow extends StatelessWidget {
  const _PackageRow({
    required this.package,
    required this.accent,
    required this.labels,
    required this.isLast,
  });

  final PortfolioPackage package;
  final Color accent;
  final _PackageLabels labels;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    final semanticLabel = [
      labels.open,
      package.name,
      package.description,
      ?package.proof,
      'v${package.version}, ${package.pubPoints} out of 160 '
          '${labels.pubPoints}',
      if (package.maturity case final maturity?) '${labels.maturity} $maturity',
      if (package.roadmap.isNotEmpty)
        '${labels.roadmap}: ${package.roadmap.map((item) => '${item.title} '
            '(${labels.statusNames[item.status]})').join(', ')}',
    ].join('. ');

    return AccessibleAction(
      onTap: () => _openPackage(package.url),
      semanticLabel: semanticLabel,
      semanticRole: ActionSemanticRole.link,
      focusColor: accent,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: compact ? 20 : 22),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            bottom: isLast
                ? BorderSide(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  )
                : BorderSide.none,
          ),
        ),
        child: compact
            ? _CompactPackageContent(
                package: package,
                accent: accent,
                labels: labels,
              )
            : _WidePackageContent(
                package: package,
                accent: accent,
                labels: labels,
              ),
      ),
    );
  }
}

class _WidePackageContent extends StatelessWidget {
  const _WidePackageContent({
    required this.package,
    required this.accent,
    required this.labels,
  });

  final PortfolioPackage package;
  final Color accent;
  final _PackageLabels labels;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PackageTitleLine(package: package, accent: accent, labels: labels),
            const SizedBox(height: 6),
            Text(
              package.description,
              style: AppFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.55,
              ),
            ),
            if (package.proof != null) ...[
              const SizedBox(height: 10),
              _ProofLine(proof: package.proof!, accent: accent),
            ],
          ],
        ),
      ),
      const SizedBox(width: 24),
      Expanded(
        flex: 2,
        child: _PackageRoadmap(
          package: package,
          accent: accent,
          labels: labels,
        ),
      ),
      const SizedBox(width: 18),
      Icon(Icons.north_east_rounded, size: 16, color: accent),
    ],
  );
}

class _CompactPackageContent extends StatelessWidget {
  const _CompactPackageContent({
    required this.package,
    required this.accent,
    required this.labels,
  });

  final PortfolioPackage package;
  final Color accent;
  final _PackageLabels labels;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: _PackageTitleLine(
              package: package,
              accent: accent,
              labels: labels,
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.north_east_rounded, size: 16, color: accent),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        package.description,
        style: AppFonts.inter(
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.55,
        ),
      ),
      if (package.proof != null) ...[
        const SizedBox(height: 10),
        _ProofLine(proof: package.proof!, accent: accent),
      ],
      const SizedBox(height: 12),
      _PackageRoadmap(package: package, accent: accent, labels: labels),
    ],
  );
}

/// Package name with its version/score line and, when declared, the maturity
/// rung as a small outlined chip. L5 — the only rung that means "a real
/// external user drives this package" — is the only one drawn in accent.
class _PackageTitleLine extends StatelessWidget {
  const _PackageTitleLine({
    required this.package,
    required this.accent,
    required this.labels,
  });

  final PortfolioPackage package;
  final Color accent;
  final _PackageLabels labels;

  @override
  Widget build(BuildContext context) {
    final maturity = package.maturity;
    final chipColor = package.maturity == 'L5'
        ? accent
        : AppColors.textSecondary;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 6,
      children: [
        Text(
          package.name,
          style: AppFonts.spaceGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textBright,
          ),
        ),
        Text(
          'v${package.version} · ${package.pubPoints}/160 ${labels.pubPoints}',
          style: AppFonts.jetBrainsMono(
            fontSize: 11,
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        if (maturity != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              border: Border.all(color: chipColor.withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              maturity,
              style: AppFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: chipColor,
                letterSpacing: 0.6,
              ),
            ),
          ),
      ],
    );
  }
}

/// The one measured claim that carries the package's case, set off by a
/// short accent tick so it reads as evidence rather than marketing copy.
class _ProofLine extends StatelessWidget {
  const _ProofLine({required this.proof, required this.accent});

  final String proof;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Container(width: 14, height: 2, color: accent),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          proof,
          style: AppFonts.jetBrainsMono(
            fontSize: 11,
            color: AppColors.textSecondary,
            height: 1.6,
            letterSpacing: 0.1,
          ),
        ),
      ),
    ],
  );
}

/// The package's live roadmap: every entry keeps its status visible, so a
/// visitor can see at a glance what shipped, what is moving now, and what
/// deliberately waits for a real user to ask.
class _PackageRoadmap extends StatelessWidget {
  const _PackageRoadmap({
    required this.package,
    required this.accent,
    required this.labels,
  });

  final PortfolioPackage package;
  final Color accent;
  final _PackageLabels labels;

  @override
  Widget build(BuildContext context) {
    if (package.roadmap.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labels.roadmap.toUpperCase(),
          style: AppFonts.jetBrainsMono(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < package.roadmap.length; index++) ...[
          if (index > 0) const SizedBox(height: 6),
          _RoadmapItemLine(
            item: package.roadmap[index],
            accent: accent,
            labels: labels,
          ),
        ],
      ],
    );
  }
}

class _RoadmapItemLine extends StatelessWidget {
  const _RoadmapItemLine({
    required this.item,
    required this.accent,
    required this.labels,
  });

  final PackageRoadmapItem item;
  final Color accent;
  final _PackageLabels labels;

  @override
  Widget build(BuildContext context) {
    final (Color markColor, bool filled) = switch (item.status) {
      'done' => (accent, true),
      'doing' => (accent, false),
      _ => (AppColors.textSecondary, false),
    };
    final dimmed = item.status == 'waiting';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? markColor : null,
              border: Border.all(
                color: markColor.withValues(alpha: dimmed ? 0.45 : 0.9),
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: item.title,
                  style: AppFonts.inter(
                    fontSize: 12.5,
                    color: dimmed
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
                TextSpan(
                  // Non-breaking spaces keep a two-word status ("in progress")
                  // on one line; wrapped, it reads as two separate labels.
                  text:
                      '  '
                      '${(labels.statusNames[item.status] ?? item.status).replaceAll(' ', ' ')}',
                  style: AppFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: item.status == 'doing'
                        ? accent
                        : AppColors.textSecondary.withValues(alpha: 0.75),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _openPackage(Uri uri) async =>
    launchUrl(uri, webOnlyWindowName: '_blank');
