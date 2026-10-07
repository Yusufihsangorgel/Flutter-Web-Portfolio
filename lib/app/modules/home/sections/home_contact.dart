part of 'home_section.dart';

class _HeroNarrative extends StatelessWidget {
  const _HeroNarrative({required this.portfolio});

  final PortfolioDocument portfolio;

  @override
  Widget build(BuildContext context) {
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
        _actions(context),
      ],
    );
  }

  Widget _actions(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      _HeroLink(
        uri: Uri.parse('#/projects'),
        label: context.strings.homeSectionViewWork,
        primary: true,
      ),
      _HeroLink(
        uri: Uri(scheme: 'mailto', path: portfolio.profile.email),
        label: context.strings.homeSectionEmail,
      ),
    ],
  );
}

class _CurrentPractice extends StatelessWidget {
  const _CurrentPractice({
    required this.profile,
    required this.roles,
    this.compact = false,
  });

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
          context.strings.homeSectionCurrently,
          style: AppFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
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

  final content.PortfolioLink link;

  @override
  Widget build(BuildContext context) => PortfolioLink(
    uri: link.url,
    semanticLabel: link.label,
    focusColor: AppColors.accent,
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
            color: AppColors.accent,
          ),
        ],
      ),
    ),
  );
}

class _HeroLink extends StatefulWidget {
  const _HeroLink({
    required this.uri,
    required this.label,
    this.primary = false,
  });

  final Uri uri;
  final String label;
  final bool primary;

  @override
  State<_HeroLink> createState() => _HeroLinkState();
}

class _HeroLinkState extends State<_HeroLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => PortfolioLink(
    uri: widget.uri,
    semanticLabel: widget.label,
    onHoverChanged: (value) => setState(() => _hovered = value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: widget.primary
            ? AppColors.accent.withValues(alpha: _hovered ? 0.9 : 1)
            : AppColors.textBright.withValues(alpha: _hovered ? 0.06 : 0),
        border: Border.all(
          color: widget.primary
              ? AppColors.accent
              : AppColors.textBright.withValues(alpha: _hovered ? 1 : 0.28),
        ),
      ),
      child: Text(
        widget.label,
        style: AppFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: widget.primary ? AppColors.white : AppColors.textBright,
          letterSpacing: 2,
        ),
      ),
    ),
  );
}
