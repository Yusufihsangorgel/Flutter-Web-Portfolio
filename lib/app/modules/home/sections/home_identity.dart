part of 'home_section.dart';

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
              color: AppColors.accent,
            ),
          ),
        ],
      ],
    ),
  );
}

class _IdentityStory extends StatelessWidget {
  const _IdentityStory({required this.portfolio});

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
      _HeroNarrative(portfolio: portfolio),
    ],
  );
}

class _CompactIdentityStory extends StatelessWidget {
  const _CompactIdentityStory({
    required this.portfolio,
    required this.currentRoles,
  });

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
      _HeroNarrative(portfolio: portfolio),
      const SizedBox(height: 24),
      _CurrentPractice(
        profile: portfolio.profile,
        roles: currentRoles,
        compact: true,
      ),
    ],
  );
}

class _UltraNarrowIdentityStory extends StatelessWidget {
  const _UltraNarrowIdentityStory({
    required this.portfolio,
    required this.currentRoles,
  });

  final PortfolioDocument portfolio;
  final List<PortfolioExperience> currentRoles;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _PersonalTitle(profile: portfolio.profile),
      const SizedBox(height: 52),
      _HeroNarrative(portfolio: portfolio),
      const SizedBox(height: 32),
      _CurrentPractice(
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
            _accentTitle(context, displayName.accent, titleSize),
          ],
        ),
      ),
    );
  }

  Widget _accentTitle(BuildContext context, String title, double size) =>
      KeyedSubtree(
        key: context.read<AppScrollController>().anchorKeyFor(SectionId.home),
        child: Container(
          color: AppColors.accent,
          padding: EdgeInsets.fromLTRB(
            size * 0.08,
            size * 0.15,
            size * 0.11,
            size * 0.08,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              title,
              maxLines: 1,
              style: AppFonts.spaceGrotesk(
                fontSize: size * 0.9,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                height: 1,
                letterSpacing: -size * 0.045,
              ),
            ),
          ),
        ),
      );
}
