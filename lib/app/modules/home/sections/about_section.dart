import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';

/// Professional context and the complete capability ledger.
///
/// The public surface remains identity-safe, while preserving the substantive
/// career history, scope, and technical profile expected from a portfolio.
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) {
          final language = context.read<LanguageCubit>();
          final portfolio = context.read<PortfolioDocument>();
          final bio = portfolio.profile.summary;

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SceneAccentBuilder(
                  builder: (context, accent) => NumberedSectionHeading(
                    number: '01',
                    title: language.getText(
                      'about_section.title',
                      defaultValue: 'About Me',
                    ),
                    accent: accent,
                  ),
                ),
                SizedBox(
                  height: MediaQuery.sizeOf(context).width < Breakpoints.tablet
                      ? 46
                      : 76,
                ),
                Semantics(
                  label: bio,
                  excludeSemantics: true,
                  child: ExcludeSemantics(
                    child: Text(
                      bio,
                      style: AppFonts.spaceGrotesk(
                        fontSize:
                            MediaQuery.sizeOf(context).width <
                                Breakpoints.tablet
                            ? 30
                            : 47,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textBright,
                        height: 1.13,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 42),
                _ContextRail(portfolio: portfolio),
                const SizedBox(height: 72),
                _CapabilityLedger(capabilities: portfolio.capabilities),
              ],
            ),
          );
        },
      );
}

class _ContextRail extends StatelessWidget {
  const _ContextRail({required this.portfolio});

  final PortfolioDocument portfolio;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    final detail = portfolio.profile.focus.join('  /  ');
    final metadata = _AtlasMetadata(profile: portfolio.profile);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0x36DFFF3F)),
          bottom: BorderSide(color: Color(0x24F2F0E9)),
        ),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail,
                  style: AppFonts.inter(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 26),
                metadata,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: Text(
                    detail,
                    style: AppFonts.inter(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      height: 1.75,
                    ),
                  ),
                ),
                const SizedBox(width: 80),
                Expanded(flex: 4, child: metadata),
              ],
            ),
    );
  }
}

class _AtlasMetadata extends StatelessWidget {
  const _AtlasMetadata({required this.profile});

  final PortfolioProfile profile;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      children: [
        Expanded(
          child: _MetadataField(label: 'BASE', value: profile.location),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: _MetadataField(label: 'MODE', value: profile.headline),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: _MetadataField(label: 'SINCE', value: profile.since),
        ),
      ],
    ),
  );
}

class _MetadataField extends StatelessWidget {
  const _MetadataField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppFonts.jetBrainsMono(
          fontSize: 8,
          color: AppColors.aboutAccent,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        value.toUpperCase(),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppFonts.jetBrainsMono(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppColors.textBright,
          height: 1.45,
          letterSpacing: 0.55,
        ),
      ),
    ],
  );
}

class _CapabilityLedger extends StatelessWidget {
  const _CapabilityLedger({required this.capabilities});
  final List<PortfolioCapability> capabilities;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 900;
      if (!desktop) {
        return Column(
          children: [
            for (var index = 0; index < capabilities.length; index++)
              _CapabilityField(capability: capabilities[index], index: index),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < capabilities.length; index++) ...[
            Expanded(
              child: _CapabilityField(
                capability: capabilities[index],
                index: index,
              ),
            ),
            if (index < capabilities.length - 1) const SizedBox(width: 28),
          ],
        ],
      );
    },
  );
}

class _CapabilityField extends StatelessWidget {
  const _CapabilityField({required this.capability, required this.index});

  final PortfolioCapability capability;
  final int index;

  @override
  Widget build(BuildContext context) {
    final category = capability.label;
    final items = capability.items;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x3DDFFF3F))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${index + 1}'.padLeft(2, '0'),
                style: AppFonts.jetBrainsMono(
                  fontSize: 9,
                  color: AppColors.aboutAccent,
                ),
              ),
              const Spacer(),
              Text(
                'FIELD',
                style: AppFonts.jetBrainsMono(
                  fontSize: 8,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            category,
            style: AppFonts.instrumentSerif(
              fontSize: 34,
              fontStyle: FontStyle.italic,
              color: AppColors.textBright,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 18),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                item,
                style: AppFonts.jetBrainsMono(
                  fontSize: 10,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
