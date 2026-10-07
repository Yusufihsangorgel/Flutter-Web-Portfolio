import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart'
    hide PortfolioLink;
import 'package:flutter_web_portfolio/app/features/language/application/language_context.dart';
import 'package:flutter_web_portfolio/app/widgets/portfolio_link.dart';

class PackageCategoryList extends StatelessWidget {
  const PackageCategoryList({
    super.key,
    required this.packages,
    required this.accent,
    required this.compact,
  });

  final List<PortfolioPackage> packages;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final grouped = <PortfolioPackageCategory, List<PortfolioPackage>>{};
    for (final package in packages) {
      grouped.putIfAbsent(package.category, () => []).add(package);
    }
    final categories = PortfolioPackageCategory.values
        .where((category) => grouped[category]?.isNotEmpty ?? false)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < categories.length; index++)
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 48),
            child: _PackageCategoryGroup(
              category: categories[index],
              packages: grouped[categories[index]]!,
              accent: accent,
              compact: compact,
            ),
          ),
      ],
    );
  }
}

class _PackageCategoryGroup extends StatelessWidget {
  const _PackageCategoryGroup({
    required this.category,
    required this.packages,
    required this.accent,
    required this.compact,
  });

  final PortfolioPackageCategory category;
  final List<PortfolioPackage> packages;
  final Color accent;
  final bool compact;

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
              _categoryLabel(context, category),
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
      for (var index = 0; index < packages.length; index++) ...[
        if (index > 0) const SizedBox(height: 12),
        _PackageRow(package: packages[index], accent: accent, compact: compact),
      ],
    ],
  );
}

class _PackageRow extends StatelessWidget {
  const _PackageRow({
    required this.package,
    required this.accent,
    required this.compact,
  });

  final PortfolioPackage package;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    return PortfolioLink(
      uri: package.url,
      semanticLabel: _packageLabel(context, package, compact),
      focusColor: accent,
      child: Container(
        padding: EdgeInsets.all(compact ? 16 : 22),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.25),
          ),
        ),
        child: compact
            ? _CompactPackage(package: package, accent: accent)
            : _DetailedPackage(
                package: package,
                accent: accent,
                narrow: narrow,
              ),
      ),
    );
  }
}

String _packageLabel(
  BuildContext context,
  PortfolioPackage package,
  bool compact,
) => [
  '${context.strings.packagesSectionOpenPackage}: ${package.name}',
  package.description,
  '${package.version}, ${package.pubPoints}/160 '
      '${context.strings.packagesSectionPubPoints}',
  if (!compact) ...[
    ?package.proof,
    if (package.roadmap.isNotEmpty)
      '${context.strings.packagesSectionRoadmap}: '
          '${package.roadmap.map((item) => '${item.title} '
              '(${_roadmapStatus(context, item.status)})').join(', ')}',
  ],
].join('. ');

String _roadmapStatus(BuildContext context, String status) => switch (status) {
  'done' => context.strings.packagesSectionStatusDone,
  'doing' => context.strings.packagesSectionStatusDoing,
  'next' => context.strings.packagesSectionStatusNext,
  'waiting' => context.strings.packagesSectionStatusWaiting,
  _ => status,
};

class _DetailedPackage extends StatelessWidget {
  const _DetailedPackage({
    required this.package,
    required this.accent,
    required this.narrow,
  });

  final PortfolioPackage package;
  final Color accent;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final summary = _PackageSummary(package: package, accent: accent);
    final roadmap = _PackageRoadmap(package: package, accent: accent);
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [summary, const SizedBox(height: 18), roadmap],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: summary),
        const SizedBox(width: 28),
        Expanded(flex: 2, child: roadmap),
        const SizedBox(width: 18),
        Icon(Icons.north_east_rounded, size: 16, color: accent),
      ],
    );
  }
}

class _PackageSummary extends StatelessWidget {
  const _PackageSummary({required this.package, required this.accent});

  final PortfolioPackage package;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _PackageTitle(package: package, accent: accent),
      const SizedBox(height: 8),
      Text(
        package.description,
        style: AppFonts.inter(
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.55,
        ),
      ),
      if (package.proof case final proof?) ...[
        const SizedBox(height: 12),
        _ProofLine(proof: proof, accent: accent),
      ],
    ],
  );
}

class _PackageTitle extends StatelessWidget {
  const _PackageTitle({required this.package, required this.accent});

  final PortfolioPackage package;
  final Color accent;

  @override
  Widget build(BuildContext context) => Wrap(
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
        '${package.version} · ${package.pubPoints}/160 '
        '${context.strings.packagesSectionPubPoints}',
        style: AppFonts.jetBrainsMono(
          fontSize: 11,
          color: AppColors.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    ],
  );
}

class _CompactPackage extends StatelessWidget {
  const _CompactPackage({required this.package, required this.accent});

  final PortfolioPackage package;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PackageTitle(package: package, accent: accent),
            const SizedBox(height: 6),
            Text(
              package.description,
              style: AppFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Icon(Icons.north_east_rounded, size: 16, color: accent),
    ],
  );
}

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
          ),
        ),
      ),
    ],
  );
}

class _PackageRoadmap extends StatelessWidget {
  const _PackageRoadmap({required this.package, required this.accent});

  final PortfolioPackage package;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (package.roadmap.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.strings.packagesSectionRoadmap.toUpperCase(),
          style: AppFonts.jetBrainsMono(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in package.roadmap)
          _RoadmapLine(item: item, accent: accent),
      ],
    );
  }
}

class _RoadmapLine extends StatelessWidget {
  const _RoadmapLine({required this.item, required this.accent});

  final PackageRoadmapItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final status = _roadmapStatus(context, item.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: item.title,
              style: AppFonts.inter(
                fontSize: 12.5,
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
            TextSpan(
              text: '  ${status.replaceAll(' ', ' ')}',
              style: AppFonts.jetBrainsMono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: item.status == 'doing'
                    ? accent
                    : AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _categoryLabel(
  BuildContext context,
  PortfolioPackageCategory category,
) => switch (category) {
  PortfolioPackageCategory.nativeFfi =>
    context.strings.packagesSectionCategoryNativeFfi,
  PortfolioPackageCategory.aiLlm =>
    context.strings.packagesSectionCategoryAiLlm,
  PortfolioPackageCategory.server =>
    context.strings.packagesSectionCategoryServer,
  PortfolioPackageCategory.flutterUi =>
    context.strings.packagesSectionCategoryFlutterUi,
  PortfolioPackageCategory.devTool =>
    context.strings.packagesSectionCategoryDevTool,
};
