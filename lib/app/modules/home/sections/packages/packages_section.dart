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

/// Localized copy shared by every package row's metrics line.
final class _PackageLabels {
  const _PackageLabels({
    required this.pubPoints,
    required this.downloads,
    required this.likes,
    required this.open,
  });

  final String pubPoints;
  final String downloads;
  final String likes;
  final String open;
}

/// Every published pub.dev package, grouped by category with real metrics.
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

          final totalDownloads = packages.fold<int>(
            0,
            (sum, package) => sum + package.downloads,
          );
          final subtitle = language
              .getText(
                'packages_section.subtitle',
                defaultValue:
                    '{count} packages live on pub.dev, every one at a '
                    'perfect 160/160 score. Together they see about '
                    '{downloads} downloads a month.',
              )
              .replaceAll('{count}', '${packages.length}')
              .replaceAll('{downloads}', _groupThousands(totalDownloads));
          final labels = _PackageLabels(
            pubPoints: language.getText(
              'packages_section.pub_points',
              defaultValue: 'pub points',
            ),
            downloads: language.getText(
              'packages_section.downloads',
              defaultValue: 'downloads / mo',
            ),
            likes: language.getText(
              'packages_section.likes',
              defaultValue: 'likes',
            ),
            open: language.getText(
              'packages_section.open_package',
              defaultValue: 'Open on pub.dev',
            ),
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
    final metricsText =
        'v${package.version}, ${package.pubPoints} out of 160 '
        '${labels.pubPoints}, ${package.downloads} ${labels.downloads}, '
        '${package.likes} ${labels.likes}';
    final semanticLabel = [
      labels.open,
      package.name,
      package.description,
      metricsText,
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
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        flex: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package.name,
              style: AppFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textBright,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              package.description,
              style: AppFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 24),
      Expanded(
        flex: 2,
        child: _PackageMetrics(
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
            child: Text(
              package.name,
              style: AppFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textBright,
              ),
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
      const SizedBox(height: 12),
      _PackageMetrics(package: package, accent: accent, labels: labels),
    ],
  );
}

class _PackageMetrics extends StatelessWidget {
  const _PackageMetrics({
    required this.package,
    required this.accent,
    required this.labels,
  });

  final PortfolioPackage package;
  final Color accent;
  final _PackageLabels labels;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      style: AppFonts.jetBrainsMono(
        fontSize: 11,
        color: AppColors.textSecondary,
        height: 1.65,
        letterSpacing: 0.2,
      ),
      children: [
        TextSpan(text: 'v${package.version}   '),
        TextSpan(
          text: '${package.pubPoints}/160',
          style: AppFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: accent,
            letterSpacing: 0.2,
          ),
        ),
        TextSpan(
          text:
              ' ${labels.pubPoints}   ${package.downloads} '
              '${labels.downloads}   ${package.likes} ${labels.likes}',
        ),
      ],
    ),
  );
}

String _groupThousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}

Future<void> _openPackage(Uri uri) async =>
    launchUrl(uri, webOnlyWindowName: '_blank');
