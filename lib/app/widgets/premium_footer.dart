import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:url_launcher/url_launcher.dart';

/// A high-contrast closing section with direct navigation and profile links.
class PremiumFooter extends StatelessWidget {
  const PremiumFooter({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) {
          final language = context.read<LanguageCubit>();
          final portfolio = context.read<PortfolioDocument>();
          final width = MediaQuery.sizeOf(context).width;
          final desktop = width >= Breakpoints.desktop;
          final name = portfolio.profile.name;

          return Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: desktop ? 160 : 96),
            color: AppColors.textBright,
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: AppColors.background),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  desktop ? 72 : 24,
                  desktop ? 54 : 38,
                  desktop ? 72 : 68,
                  26,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FooterRail(portfolio: portfolio),
                    SizedBox(height: desktop ? 70 : 48),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        name,
                        maxLines: 1,
                        style: AppFonts.spaceGrotesk(
                          fontSize: desktop ? 76 : 44,
                          fontWeight: FontWeight.w600,
                          color: AppColors.background,
                          height: 0.98,
                          letterSpacing: desktop ? -2.8 : -1.2,
                        ),
                      ),
                    ),
                    SizedBox(height: desktop ? 76 : 54),
                    _FooterNavigation(
                      language: language,
                      portfolio: portfolio,
                      desktop: desktop,
                    ),
                    const SizedBox(height: 44),
                    _FooterBottom(name: name, portfolio: portfolio),
                  ],
                ),
              ),
            ),
          );
        },
      );
}

class _FooterRail extends StatelessWidget {
  const _FooterRail({required this.portfolio});

  final PortfolioDocument portfolio;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      children: [
        Text(
          '${portfolio.profile.role} · ${portfolio.profile.location}',
          style: AppFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.background,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(child: Divider(color: Color(0x520B0B0D))),
      ],
    ),
  );
}

class _FooterNavigation extends StatelessWidget {
  const _FooterNavigation({
    required this.language,
    required this.portfolio,
    required this.desktop,
  });

  final LanguageCubit language;
  final PortfolioDocument portfolio;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final links = [
      for (final section in portfolio.activeSections)
        if (section != 'home')
          (
            id: section,
            label: language.getText(
              'nav.$section',
              defaultValue:
                  '${section[0].toUpperCase()}${section.substring(1)}',
            ),
          ),
    ];
    final navigation = Wrap(
      spacing: desktop ? 34 : 18,
      runSpacing: 14,
      children: [
        for (var index = 0; index < links.length; index++)
          _FooterLink(
            label: links[index].label,
            onTap: () => context.read<AppScrollController>().scrollToSection(
              links[index].id,
            ),
          ),
      ],
    );
    final focus = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          language.getText(
            'footer.verification',
            defaultValue: 'Current focus',
          ),
          style: AppFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.background.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          portfolio.profile.focus.take(3).join(' · '),
          style: AppFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.background,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 18,
          runSpacing: 12,
          children: [
            for (final link in portfolio.profile.links)
              _ProfileLink(link: link),
          ],
        ),
      ],
    );

    return desktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(flex: 7, child: navigation),
              const SizedBox(width: 60),
              Expanded(flex: 3, child: focus),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [navigation, const SizedBox(height: 36), focus],
          );
  }
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({required this.link});

  final PortfolioLink link;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: () => launchUrl(link.url, webOnlyWindowName: '_blank'),
    semanticLabel: link.label,
    semanticRole: CinematicControlRole.link,
    focusColor: AppColors.background,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            link.label,
            style: AppFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.background,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.north_east_rounded,
            size: 14,
            color: AppColors.background,
          ),
        ],
      ),
    ),
  );
}

class _FooterLink extends StatefulWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: widget.onTap,
    onHoverChanged: (value) => setState(() => _hovered = value),
    focusColor: AppColors.background,
    semanticLabel: widget.label,
    child: AnimatedContainer(
      duration: AppDurations.fast,
      padding: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _hovered ? AppColors.background : Colors.transparent,
          ),
        ),
      ),
      child: Text(
        widget.label,
        style: AppFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.background,
          letterSpacing: -0.1,
        ),
      ),
    ),
  );
}

class _FooterBottom extends StatelessWidget {
  const _FooterBottom({required this.name, required this.portfolio});

  final String name;
  final PortfolioDocument portfolio;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 18),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0x3D0B0B0D))),
    ),
    child: Wrap(
      spacing: 24,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('\u00A9 ${DateTime.now().year} $name', style: _bottomStyle()),
        Text(
          portfolio.profile.focus.take(3).join(' · '),
          style: _bottomStyle(),
        ),
      ],
    ),
  );

  TextStyle _bottomStyle() => AppFonts.spaceGrotesk(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.background.withValues(alpha: 0.62),
    letterSpacing: 0.1,
  );
}
