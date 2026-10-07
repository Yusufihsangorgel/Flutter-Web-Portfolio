import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart'
    hide PortfolioLink;
import 'package:flutter_web_portfolio/app/features/language/application/language_context.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/packages/package_list.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';

/// Curated packages with an accessible catalog disclosure.
class PackagesSection extends StatefulWidget {
  const PackagesSection({super.key});

  @override
  State<PackagesSection> createState() => _PackagesSectionState();
}

class _PackagesSectionState extends State<PackagesSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) {
          final packages = context.read<PortfolioDocument>().packages;
          if (packages.isEmpty) return const SizedBox.shrink();

          final featured = packages.where((entry) => entry.featured).toList();
          final remainder = packages.where((entry) => !entry.featured).toList();
          final primary = featured.isEmpty ? packages : featured;
          final canExpand = featured.isNotEmpty && remainder.isNotEmpty;

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PackagesHeader(packages: packages),
                const SizedBox(height: 60),
                SceneAccentBuilder(
                  builder: (context, accent) => PackageCategoryList(
                    packages: primary,
                    accent: accent,
                    compact: false,
                  ),
                ),
                if (canExpand) ...[
                  const SizedBox(height: 28),
                  _PackageDisclosure(
                    count: packages.length,
                    expanded: _expanded,
                    onToggle: () => setState(() => _expanded = !_expanded),
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 36),
                    SceneAccentBuilder(
                      builder: (context, accent) => PackageCategoryList(
                        packages: remainder,
                        accent: accent,
                        compact: true,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      );
}

class _PackagesHeader extends StatelessWidget {
  const _PackagesHeader({required this.packages});

  final List<PortfolioPackage> packages;

  @override
  Widget build(BuildContext context) {
    final perfect = packages.where((entry) => entry.pubPoints == 160).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SceneAccentBuilder(
          builder: (context, accent) => NumberedSectionHeading(
            number: context.read<NarrativeDocument>().sectionNumber(
              SectionId.packages,
            ),
            title: context.strings.packagesSectionTitle,
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
            perfect == 0
                ? context.strings.packagesSectionSubtitleNoPerfect(
                    count: '${packages.length}',
                  )
                : context.strings.packagesSectionSubtitle(
                    count: '${packages.length}',
                    perfect: '$perfect',
                  ),
            style: AppFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

class _PackageDisclosure extends StatelessWidget {
  const _PackageDisclosure({
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => SceneAccentBuilder(
    builder: (context, accent) {
      final label = expanded
          ? context.strings.packagesSectionShowLess
          : context.strings.packagesSectionShowAll(count: '$count');
      return AccessibleAction(
        onTap: onToggle,
        semanticLabel: label,
        expanded: expanded,
        focusColor: accent,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: accent,
              ),
            ],
          ),
        ),
      );
    },
  );
}
