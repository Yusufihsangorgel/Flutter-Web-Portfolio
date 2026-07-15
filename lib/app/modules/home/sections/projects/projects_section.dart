import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';
import 'package:url_launcher/url_launcher.dart';

/// Selected professional and independent work in an editorial index.
///
/// Three projects receive enough room for ownership and trade-offs. The rest
/// stay in a compact, scannable archive. No decorative project mock-ups are
/// generated when a real artifact is not available.
final class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LanguageCubit, LanguageState>(
    builder: (context, _) {
      final language = context.read<LanguageCubit>();
      final portfolio = context.read<PortfolioDocument>();
      final featured = portfolio.featuredSystems.toList(growable: false);
      final supporting = portfolio.supportingSystems.toList(growable: false);

      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SceneAccentBuilder(
              builder: (context, accent) => NumberedSectionHeading(
                number: portfolio.sectionNumber('projects'),
                title: language.getText(
                  'projects_section.title',
                  defaultValue: 'Selected Work',
                ),
                accent: accent,
              ),
            ),
            const SizedBox(height: 26),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Text(
                language.getText(
                  'projects_section.subtitle',
                  defaultValue:
                      'Products I shipped and tools I continue to maintain.',
                ),
                style: AppFonts.inter(
                  fontSize: 17,
                  color: AppColors.textPrimary,
                  height: 1.65,
                ),
              ),
            ),
            const SizedBox(height: 64),
            for (var index = 0; index < featured.length; index++)
              _FeaturedWork(
                system: featured[index],
                index: index,
                language: language,
              ),
            if (supporting.isNotEmpty) ...[
              const SizedBox(height: 96),
              Text(
                language.getText(
                  'projects_section.archive',
                  defaultValue: 'More work',
                ),
                style: AppFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBright,
                  letterSpacing: -0.45,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0x3D5B6CFF))),
                ),
                child: Column(
                  children: [
                    for (final system in supporting)
                      _ArchiveRow(system: system),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

final class _FeaturedWork extends StatelessWidget {
  const _FeaturedWork({
    required this.system,
    required this.index,
    required this.language,
  });

  final PortfolioSystem system;
  final int index;
  final LanguageCubit language;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= Breakpoints.desktop;
    final details = _ProjectDetails(system: system, language: language);
    final introduction = _ProjectIntroduction(
      system: system,
      index: index,
      openLabel: language.getText(
        'projects_section.open_project',
        defaultValue: 'Open project',
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(vertical: desktop ? 72 : 52),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x3D5B6CFF))),
      ),
      child: desktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 11, child: introduction),
                const SizedBox(width: 96),
                Expanded(flex: 9, child: details),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [introduction, const SizedBox(height: 42), details],
            ),
    );
  }
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            '${index + 1}'.padLeft(2, '0'),
            style: AppFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.heroAccent,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              '${system.year} · ${system.kind}',
              style: AppFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 28),
      Text(
        system.name,
        style: AppFonts.spaceGrotesk(
          fontSize: MediaQuery.sizeOf(context).width < Breakpoints.tablet
              ? 42
              : 62,
          fontWeight: FontWeight.w600,
          color: AppColors.textBright,
          height: 0.98,
          letterSpacing: -2.0,
        ),
      ),
      const SizedBox(height: 24),
      Text(
        system.summary,
        style: AppFonts.inter(
          fontSize: 16,
          color: AppColors.textPrimary,
          height: 1.72,
        ),
      ),
      const SizedBox(height: 28),
      CinematicFocusable(
        onTap: () => launchUrl(system.url, webOnlyWindowName: '_blank'),
        semanticLabel: '$openLabel: ${system.name}',
        semanticRole: CinematicControlRole.link,
        focusColor: AppColors.heroAccent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                openLabel,
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
    ],
  );
}

final class _ProjectDetails extends StatelessWidget {
  const _ProjectDetails({required this.system, required this.language});

  final PortfolioSystem system;
  final LanguageCubit language;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _DetailBlock(
        label: language.getText(
          'projects_section.ownership',
          defaultValue: 'What I owned',
        ),
        value: system.ownership,
      ),
      const SizedBox(height: 30),
      _DetailBlock(
        label: language.getText(
          'projects_section.decision',
          defaultValue: 'A key decision',
        ),
        value: system.decision,
      ),
      const SizedBox(height: 30),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final technology in system.technologies)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0x125B6CFF),
                border: Border.all(color: const Color(0x305B6CFF)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                technology,
                style: AppFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

final class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.heroAccent,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        value,
        style: AppFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColors.textBright,
          height: 1.5,
          letterSpacing: -0.25,
        ),
      ),
    ],
  );
}

final class _ArchiveRow extends StatefulWidget {
  const _ArchiveRow({required this.system});

  final PortfolioSystem system;

  @override
  State<_ArchiveRow> createState() => _ArchiveRowState();
}

final class _ArchiveRowState extends State<_ArchiveRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final system = widget.system;
    final desktop = MediaQuery.sizeOf(context).width >= Breakpoints.desktop;
    return CinematicFocusable(
      onTap: () => launchUrl(system.url, webOnlyWindowName: '_blank'),
      onHoverChanged: (value) => setState(() => _hovered = value),
      semanticLabel: '${system.name}. ${system.kind}. ${system.summary}',
      semanticRole: CinematicControlRole.link,
      focusColor: AppColors.heroAccent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(vertical: desktop ? 24 : 26),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0x0F5B6CFF) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: Color(0x24F2F0E9))),
        ),
        child: desktop
            ? Row(
                children: [
                  SizedBox(width: 110, child: _ArchiveYear(system: system)),
                  SizedBox(width: 270, child: _ArchiveName(system: system)),
                  SizedBox(width: 210, child: _ArchiveKind(system: system)),
                  const SizedBox(width: 34),
                  Expanded(child: _ArchiveSummary(system: system)),
                  const SizedBox(width: 24),
                  const Icon(
                    Icons.north_east_rounded,
                    size: 18,
                    color: AppColors.heroAccent,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _ArchiveName(system: system)),
                      const SizedBox(width: 20),
                      _ArchiveYear(system: system),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ArchiveKind(system: system),
                  const SizedBox(height: 14),
                  _ArchiveSummary(system: system),
                ],
              ),
      ),
    );
  }
}

final class _ArchiveName extends StatelessWidget {
  const _ArchiveName({required this.system});

  final PortfolioSystem system;

  @override
  Widget build(BuildContext context) => Text(
    system.name,
    style: AppFonts.spaceGrotesk(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textBright,
      letterSpacing: -0.25,
    ),
  );
}

final class _ArchiveYear extends StatelessWidget {
  const _ArchiveYear({required this.system});

  final PortfolioSystem system;

  @override
  Widget build(BuildContext context) => Text(
    system.year,
    style: AppFonts.jetBrainsMono(
      fontSize: 9,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),
  );
}

final class _ArchiveKind extends StatelessWidget {
  const _ArchiveKind({required this.system});

  final PortfolioSystem system;

  @override
  Widget build(BuildContext context) => Text(
    system.kind,
    style: AppFonts.spaceGrotesk(fontSize: 13, color: AppColors.textPrimary),
  );
}

final class _ArchiveSummary extends StatelessWidget {
  const _ArchiveSummary({required this.system});

  final PortfolioSystem system;

  @override
  Widget build(BuildContext context) => Text(
    system.summary,
    maxLines: MediaQuery.sizeOf(context).width >= Breakpoints.desktop ? 2 : 4,
    overflow: TextOverflow.ellipsis,
    style: AppFonts.inter(
      fontSize: 13,
      color: AppColors.textPrimary,
      height: 1.55,
    ),
  );
}
