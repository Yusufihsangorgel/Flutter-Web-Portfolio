import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_button.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

/// Personal opening for the portfolio.
///
/// The person is the visual anchor. Technical detail follows as evidence in
/// the document instead of masquerading as decorative interface chrome.
class HomeSection extends StatelessWidget {
  const HomeSection({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) {
          final language = context.read<LanguageCubit>();
          final portfolio = context.read<PortfolioDocument>();
          final size = MediaQuery.sizeOf(context);
          final desktop = size.width >= Breakpoints.desktop;
          final tablet = size.width >= Breakpoints.tablet;
          final veryNarrow = size.width < 340;
          final horizontal = size.width > AppDimensions.maxContentWidth
              ? AppDimensions.sectionPaddingDesktop
              : tablet
              ? AppDimensions.sectionPaddingTablet
              : AppDimensions.sectionPaddingMobile;
          final appBarHeight = tablet
              ? AppDimensions.appBarHeight
              : AppDimensions.appBarHeightMobile;
          final height = (size.height - appBarHeight).clamp(
            veryNarrow ? 700.0 : 520.0,
            1040.0,
          );

          return SizedBox(
            width: double.infinity,
            height: height,
            child: Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 0),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _HeroIdentityRail(
                      profile: portfolio.profile,
                      showFocus: tablet,
                      showLocation: !veryNarrow,
                    ),
                  ),
                  Positioned.fill(
                    top: tablet ? 82 : 74,
                    bottom: desktop ? 232 : 310,
                    child: Align(
                      alignment: desktop
                          ? const Alignment(0, -0.02)
                          : Alignment.centerLeft,
                      child: _PersonalTitle(profile: portfolio.profile),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 62,
                    child: desktop
                        ? _DesktopHeroFooter(
                            language: language,
                            portfolio: portfolio,
                          )
                        : _CompactHeroFooter(
                            language: language,
                            portfolio: portfolio,
                          ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: ScrollIndicator(delay: Duration.zero),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _HeroIdentityRail extends StatelessWidget {
  const _HeroIdentityRail({
    required this.profile,
    required this.showFocus,
    required this.showLocation,
  });

  final PortfolioProfile profile;
  final bool showFocus;
  final bool showLocation;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(bottom: 15),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0x24F2F0E9))),
    ),
    child: Row(
      children: [
        Flexible(
          child: Text(
            profile.role,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textBright,
              letterSpacing: -0.1,
            ),
          ),
        ),
        const Spacer(),
        if (showFocus) ...[
          Text(
            profile.focus.take(2).join(' · '),
            style: AppFonts.spaceGrotesk(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 42),
        ],
        if (showLocation)
          Text(
            profile.location,
            style: AppFonts.spaceGrotesk(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
      ],
    ),
  );
}

class _PersonalTitle extends StatelessWidget {
  const _PersonalTitle({required this.profile});

  final PortfolioProfile profile;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final displayName = profile.displayName;
    final titleSize = width < Breakpoints.tablet
        ? (width * 0.132).clamp(48.0, 64.0)
        : width < Breakpoints.desktop
        ? (width * 0.09).clamp(72.0, 96.0)
        : (width * 0.077).clamp(100.0, 132.0);

    return Semantics(
      header: true,
      headingLevel: 1,
      label: '${displayName.accessible}, ${profile.role}',
      excludeSemantics: true,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  displayName.primary,
                  maxLines: 1,
                  style: AppFonts.spaceGrotesk(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textBright,
                    height: 0.82,
                    letterSpacing: -titleSize * 0.05,
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, -titleSize * 0.025),
              child: Align(
                alignment: width >= Breakpoints.tablet
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: width >= Breakpoints.tablet
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Text(
                    displayName.accent,
                    maxLines: 1,
                    style: AppFonts.instrumentSerif(
                      fontSize: titleSize * 1.08,
                      fontStyle: FontStyle.italic,
                      color: AppColors.heroAccent,
                      height: 0.84,
                      letterSpacing: -titleSize * 0.035,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopHeroFooter extends StatelessWidget {
  const _DesktopHeroFooter({required this.language, required this.portfolio});

  final LanguageCubit language;
  final PortfolioDocument portfolio;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        flex: 5,
        child: _HeroStatement(language: language, portfolio: portfolio),
      ),
      const SizedBox(width: 96),
      Expanded(
        flex: 4,
        child: _ProfileFacts(language: language, profile: portfolio.profile),
      ),
    ],
  );
}

class _CompactHeroFooter extends StatelessWidget {
  const _CompactHeroFooter({required this.language, required this.portfolio});

  final LanguageCubit language;
  final PortfolioDocument portfolio;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _HeroStatement(language: language, portfolio: portfolio),
      const SizedBox(height: 28),
      _ProfileFacts(language: language, profile: portfolio.profile),
    ],
  );
}

class _HeroStatement extends StatelessWidget {
  const _HeroStatement({required this.language, required this.portfolio});

  final LanguageCubit language;
  final PortfolioDocument portfolio;

  @override
  Widget build(BuildContext context) {
    final github = portfolio.profile.links
        .where((link) => link.id == 'github')
        .firstOrNull;
    final veryNarrow = MediaQuery.sizeOf(context).width < 340;
    final buttons = <Widget>[
      if (portfolio.systems.isNotEmpty)
        CinematicButton(
          label: language.getText(
            'home_section.view_work',
            defaultValue: 'View selected work',
          ),
          isPrimary: true,
          onTap: () =>
              context.read<AppScrollController>().scrollToSection('projects'),
        ),
      if (github != null)
        CinematicButton(
          label: language.getText(
            'home_section.view_github',
            defaultValue: 'GitHub',
          ),
          onTap: () => launchUrl(github.url, webOnlyWindowName: '_blank'),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            portfolio.profile.headline,
            style: AppFonts.spaceGrotesk(
              fontSize: MediaQuery.sizeOf(context).width < Breakpoints.tablet
                  ? 20
                  : 25,
              fontWeight: FontWeight.w500,
              color: AppColors.textBright,
              height: 1.28,
              letterSpacing: -0.55,
            ),
          ),
        ),
        if (buttons.isNotEmpty) ...[
          const SizedBox(height: 22),
          if (veryNarrow)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < buttons.length; index++) ...[
                  if (index > 0) const SizedBox(height: 10),
                  buttons[index],
                ],
              ],
            )
          else
            Wrap(spacing: 10, runSpacing: 10, children: buttons),
        ],
      ],
    );
  }
}

class _ProfileFacts extends StatelessWidget {
  const _ProfileFacts({required this.language, required this.profile});

  final LanguageCubit language;
  final PortfolioProfile profile;

  @override
  Widget build(BuildContext context) {
    final facts = [
      (
        language.getText('home_section.based_in', defaultValue: 'Based in'),
        profile.location,
      ),
      (
        language.getText(
          'home_section.working_since',
          defaultValue: 'Working since',
        ),
        profile.since,
      ),
      (
        language.getText('home_section.focus', defaultValue: 'Focus'),
        profile.focus.first,
      ),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < facts.length; index++) ...[
          if (index > 0) const SizedBox(width: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 11),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x3DF2F0E9))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    facts[index].$1,
                    style: AppFonts.spaceGrotesk(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    facts[index].$2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBright,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
