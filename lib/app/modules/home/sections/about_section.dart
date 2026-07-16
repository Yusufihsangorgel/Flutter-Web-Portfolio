import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';
import 'package:url_launcher/url_launcher.dart';

/// Personal context and engineering practice, sourced from the portfolio JSON.
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) {
          final language = context.read<LanguageCubit>();
          final portfolio = context.read<PortfolioDocument>();
          final compact =
              MediaQuery.sizeOf(context).width < Breakpoints.desktop;

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SceneAccentBuilder(
                  builder: (context, accent) => NumberedSectionHeading(
                    number: context.read<NarrativeDocument>().sectionNumber(
                      SectionId.about,
                    ),
                    title: language.getText(
                      'about_section.title',
                      defaultValue: 'About',
                    ),
                    accent: accent,
                  ),
                ),
                SizedBox(height: compact ? 54 : 82),
                compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AboutLead(profile: portfolio.profile),
                          const SizedBox(height: 34),
                          _AboutDetail(
                            language: language,
                            profile: portfolio.profile,
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _AboutLead(profile: portfolio.profile),
                          ),
                          const SizedBox(width: 96),
                          Expanded(
                            flex: 4,
                            child: _AboutDetail(
                              language: language,
                              profile: portfolio.profile,
                            ),
                          ),
                        ],
                      ),
                SizedBox(height: compact ? 72 : 112),
                Text(
                  language.getText(
                    'about_section.practice_title',
                    defaultValue: 'What I work across',
                  ),
                  style: AppFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBright,
                  ),
                ),
                const SizedBox(height: 24),
                _PracticeIndex(capabilities: portfolio.capabilities),
              ],
            ),
          );
        },
      );
}

class _AboutLead extends StatelessWidget {
  const _AboutLead({required this.profile});

  final PortfolioProfile profile;

  @override
  Widget build(BuildContext context) => Semantics(
    label: profile.summary,
    excludeSemantics: true,
    child: Text(
      profile.summary,
      style: AppFonts.spaceGrotesk(
        fontSize: MediaQuery.sizeOf(context).width < Breakpoints.tablet
            ? 29
            : 43,
        fontWeight: FontWeight.w500,
        color: AppColors.textBright,
        height: 1.15,
        letterSpacing: -1.25,
      ),
    ),
  );
}

class _AboutDetail extends StatelessWidget {
  const _AboutDetail({required this.language, required this.profile});

  final LanguageCubit language;
  final PortfolioProfile profile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        profile.background,
        style: AppFonts.inter(
          fontSize: 16,
          color: AppColors.textPrimary,
          height: 1.75,
        ),
      ),
      const SizedBox(height: 32),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0x361E51FF)),
            bottom: BorderSide(color: Color(0x2412110F)),
          ),
        ),
        child: Column(
          children: [
            _FactLine(
              label: language.getText(
                'about_section.location',
                defaultValue: 'Based in',
              ),
              value: profile.location,
            ),
            const SizedBox(height: 14),
            _FactLine(
              label: language.getText(
                'about_section.experience',
                defaultValue: 'Professional work since',
              ),
              value: profile.since,
            ),
            const SizedBox(height: 14),
            _FactLine(
              label: language.getText(
                'about_section.email',
                defaultValue: 'Email',
              ),
              value: profile.email,
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 20,
        runSpacing: 12,
        children: [
          for (final link in profile.links) _ProfileLink(link: link),
          _EmailLink(email: profile.email),
        ],
      ),
    ],
  );
}

class _EmailLink extends StatelessWidget {
  const _EmailLink({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: () => launchUrl(Uri(scheme: 'mailto', path: email)),
    semanticLabel: email,
    semanticRole: CinematicControlRole.link,
    focusColor: AppColors.heroAccent,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            email,
            style: AppFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textBright,
            ),
          ),
          const SizedBox(width: 7),
          const Icon(
            Icons.arrow_outward_rounded,
            size: 15,
            color: AppColors.heroAccent,
          ),
        ],
      ),
    ),
  );
}

class _FactLine extends StatelessWidget {
  const _FactLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: AppFonts.spaceGrotesk(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      const SizedBox(width: 20),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: AppFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textBright,
          ),
        ),
      ),
    ],
  );
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({required this.link});

  final PortfolioLink link;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: () => launchUrl(link.url, webOnlyWindowName: '_blank'),
    semanticLabel: link.label,
    semanticRole: CinematicControlRole.link,
    focusColor: AppColors.heroAccent,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            link.label,
            style: AppFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textBright,
            ),
          ),
          const SizedBox(width: 7),
          const Icon(
            Icons.north_east_rounded,
            size: 15,
            color: AppColors.heroAccent,
          ),
        ],
      ),
    ),
  );
}

class _PracticeIndex extends StatelessWidget {
  const _PracticeIndex({required this.capabilities});

  final List<PortfolioCapability> capabilities;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final twoColumns = constraints.maxWidth >= 760;
      if (!twoColumns) {
        return Column(
          children: [
            for (var index = 0; index < capabilities.length; index++)
              _PracticeRow(capability: capabilities[index], index: index),
          ],
        );
      }
      return Wrap(
        spacing: 52,
        runSpacing: 0,
        children: [
          for (var index = 0; index < capabilities.length; index++)
            SizedBox(
              width: (constraints.maxWidth - 52) / 2,
              child: _PracticeRow(
                capability: capabilities[index],
                index: index,
              ),
            ),
        ],
      );
    },
  );
}

class _PracticeRow extends StatelessWidget {
  const _PracticeRow({required this.capability, required this.index});

  final PortfolioCapability capability;
  final int index;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 24),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0x3D1E51FF))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${index + 1}'.padLeft(2, '0'),
          style: AppFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.heroAccent,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                capability.label,
                style: AppFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBright,
                  letterSpacing: -0.45,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                capability.items.join(' · '),
                style: AppFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
