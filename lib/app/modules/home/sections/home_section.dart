import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_button.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

/// A personal opening built entirely from the external portfolio document.
///
/// The reusable template contract stays in JSON, while the visible surface
/// leads with the actual person, current work, and direct contact details.
class HomeSection extends StatelessWidget {
  const HomeSection({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) {
          final language = context.read<LanguageCubit>();
          final portfolio = context.read<PortfolioDocument>();
          final size = MediaQuery.sizeOf(context);
          final ultraNarrow = size.width < 360;
          final tablet = size.width >= Breakpoints.tablet;
          final desktop = size.width >= Breakpoints.desktop;
          final horizontal = size.width > AppDimensions.maxContentWidth
              ? AppDimensions.sectionPaddingDesktop
              : tablet
              ? AppDimensions.sectionPaddingTablet
              : AppDimensions.sectionPaddingMobile;
          final appBarHeight = tablet
              ? AppDimensions.appBarHeight
              : AppDimensions.appBarHeightMobile;
          final height = (size.height - appBarHeight).clamp(
            desktop
                ? 720.0
                : tablet
                ? 800.0
                : size.width >= Breakpoints.mobile
                ? 900.0
                : 860.0,
            1080.0,
          );
          final currentRoles = portfolio.currentExperience.toList(
            growable: false,
          );

          final content = Padding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              tablet ? 28 : 20,
              horizontal,
              14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _IdentityRail(profile: portfolio.profile),
                SizedBox(height: desktop ? 34 : 24),
                if (ultraNarrow)
                  _UltraNarrowIdentityStory(
                    language: language,
                    portfolio: portfolio,
                    currentRoles: currentRoles,
                  )
                else
                  Expanded(
                    child: desktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 7,
                                child: _IdentityStory(
                                  language: language,
                                  portfolio: portfolio,
                                ),
                              ),
                              const SizedBox(width: 88),
                              SizedBox(
                                width: 340,
                                child: _CurrentPractice(
                                  language: language,
                                  profile: portfolio.profile,
                                  roles: currentRoles,
                                ),
                              ),
                            ],
                          )
                        : _CompactIdentityStory(
                            language: language,
                            portfolio: portfolio,
                            currentRoles: currentRoles,
                          ),
                  ),
                const SizedBox(height: 12),
                const ScrollIndicator(delay: Duration.zero),
              ],
            ),
          );

          return SizedBox(
            width: double.infinity,
            child: ultraNarrow
                ? ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 1080),
                    child: content,
                  )
                : SizedBox(height: height, child: content),
          );
        },
      );
}

class _IdentityRail extends StatelessWidget {
  const _IdentityRail({required this.profile});

  final PortfolioProfile profile;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(bottom: 13),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: AppColors.textBright.withValues(alpha: 0.2)),
      ),
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
              fontWeight: FontWeight.w700,
              color: AppColors.textBright,
              letterSpacing: -0.1,
            ),
          ),
        ),
        const Spacer(),
        Text(
          profile.location,
          style: AppFonts.spaceGrotesk(
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
        ),
        if (MediaQuery.sizeOf(context).width >= Breakpoints.tablet) ...[
          const SizedBox(width: 36),
          Text(
            '${profile.since} →',
            style: AppFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.heroAccent,
            ),
          ),
        ],
      ],
    ),
  );
}

class _IdentityStory extends StatelessWidget {
  const _IdentityStory({required this.language, required this.portfolio});

  final LanguageCubit language;
  final PortfolioDocument portfolio;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: _PersonalTitle(profile: portfolio.profile),
        ),
      ),
      _HeroNarrative(language: language, portfolio: portfolio),
    ],
  );
}

class _CompactIdentityStory extends StatelessWidget {
  const _CompactIdentityStory({
    required this.language,
    required this.portfolio,
    required this.currentRoles,
  });

  final LanguageCubit language;
  final PortfolioDocument portfolio;
  final List<PortfolioExperience> currentRoles;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: _PersonalTitle(profile: portfolio.profile),
        ),
      ),
      _HeroNarrative(language: language, portfolio: portfolio),
      const SizedBox(height: 24),
      _CurrentPractice(
        language: language,
        profile: portfolio.profile,
        roles: currentRoles,
        compact: true,
      ),
    ],
  );
}

class _UltraNarrowIdentityStory extends StatelessWidget {
  const _UltraNarrowIdentityStory({
    required this.language,
    required this.portfolio,
    required this.currentRoles,
  });

  final LanguageCubit language;
  final PortfolioDocument portfolio;
  final List<PortfolioExperience> currentRoles;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _PersonalTitle(profile: portfolio.profile),
      const SizedBox(height: 52),
      _HeroNarrative(language: language, portfolio: portfolio),
      const SizedBox(height: 32),
      _CurrentPractice(
        language: language,
        profile: portfolio.profile,
        roles: currentRoles,
        compact: true,
      ),
    ],
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
        ? (width * 0.135).clamp(43.0, 62.0)
        : width < Breakpoints.desktop
        ? (width * 0.088).clamp(68.0, 94.0)
        : (width * 0.068).clamp(88.0, 122.0);

    return Semantics(
      header: true,
      headingLevel: 1,
      label: '${displayName.accessible}, ${profile.role}',
      excludeSemantics: true,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                displayName.primary,
                maxLines: 1,
                style: AppFonts.spaceGrotesk(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBright,
                  height: 0.88,
                  letterSpacing: -titleSize * 0.055,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              color: AppColors.heroAccent,
              padding: EdgeInsets.fromLTRB(
                titleSize * 0.08,
                titleSize * 0.15,
                titleSize * 0.11,
                titleSize * 0.08,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  displayName.accent,
                  maxLines: 1,
                  style: AppFonts.spaceGrotesk(
                    fontSize: titleSize * 0.9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    height: 1,
                    letterSpacing: -titleSize * 0.045,
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

class _HeroNarrative extends StatelessWidget {
  const _HeroNarrative({required this.language, required this.portfolio});

  final LanguageCubit language;
  final PortfolioDocument portfolio;

  @override
  Widget build(BuildContext context) {
    final firstChapter = context
        .read<NarrativeDocument>()
        .chapters
        .firstWhere((chapter) => !chapter.id.isHome)
        .id
        .value;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            portfolio.profile.headline,
            style: AppFonts.spaceGrotesk(
              fontSize: compact ? 20 : 26,
              fontWeight: FontWeight.w600,
              color: AppColors.textBright,
              height: 1.24,
              letterSpacing: compact ? -0.35 : -0.65,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            portfolio.profile.summary,
            style: AppFonts.inter(
              fontSize: compact ? 14 : 15,
              color: AppColors.textPrimary,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            CinematicButton(
              label: language.getText(
                'home_section.view_work',
                defaultValue: 'Explore my work',
              ),
              isPrimary: true,
              onTap: () => context.read<AppScrollController>().scrollToSection(
                firstChapter,
              ),
            ),
            CinematicButton(
              label: language.getText(
                'home_section.email',
                defaultValue: 'Email me',
              ),
              onTap: () => launchUrl(
                Uri(scheme: 'mailto', path: portfolio.profile.email),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CurrentPractice extends StatelessWidget {
  const _CurrentPractice({
    required this.language,
    required this.profile,
    required this.roles,
    this.compact = false,
  });

  final LanguageCubit language;
  final PortfolioProfile profile;
  final List<PortfolioExperience> roles;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          language.getText('home_section.currently', defaultValue: 'Currently'),
          style: AppFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.heroAccent,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < roles.length; index++)
          _CurrentRole(experience: roles[index], showBorder: index > 0),
        if (roles.isEmpty)
          Text(
            profile.focus.take(3).join(' · '),
            style: AppFonts.spaceGrotesk(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        const SizedBox(height: 20),
        _DirectLinks(profile: profile),
      ],
    );

    if (compact) {
      return Container(
        padding: const EdgeInsets.only(top: 18),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.textBright.withValues(alpha: 0.2)),
          ),
        ),
        child: content,
      );
    }

    return Container(
      padding: const EdgeInsetsDirectional.only(start: 28),
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(color: AppColors.textBright.withValues(alpha: 0.2)),
        ),
      ),
      child: Align(alignment: AlignmentDirectional.centerStart, child: content),
    );
  }
}

class _CurrentRole extends StatelessWidget {
  const _CurrentRole({required this.experience, required this.showBorder});

  final PortfolioExperience experience;
  final bool showBorder;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.only(top: showBorder ? 14 : 0, bottom: 14),
    decoration: BoxDecoration(
      border: showBorder
          ? Border(
              top: BorderSide(
                color: AppColors.textBright.withValues(alpha: 0.14),
              ),
            )
          : null,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          experience.company,
          style: AppFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textBright,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${experience.role} · ${experience.domain}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.inter(
            fontSize: 12,
            color: AppColors.textPrimary,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _DirectLinks extends StatelessWidget {
  const _DirectLinks({required this.profile});

  final PortfolioProfile profile;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 18,
    runSpacing: 10,
    children: [for (final link in profile.links) _ProfileLink(link: link)],
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textBright,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.north_east_rounded,
            size: 14,
            color: AppColors.heroAccent,
          ),
        ],
      ),
    ),
  );
}
