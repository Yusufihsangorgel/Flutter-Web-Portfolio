import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart'
    hide PortfolioLink;
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart'
    as content
    show PortfolioLink;
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_context.dart';
import 'package:flutter_web_portfolio/app/widgets/portfolio_link.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_indicator.dart';

part 'home_identity.dart';
part 'home_contact.dart';

class HomeSection extends StatelessWidget {
  const HomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final portfolio = context.watch<PortfolioDocument>();
    final size = MediaQuery.sizeOf(context);
    final layout = _HomeLayout(portfolio: portfolio);
    return SizedBox(
      width: double.infinity,
      child: size.width < 360
          ? ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 1080),
              child: layout,
            )
          : SizedBox(height: _height(size), child: layout),
    );
  }

  double _height(Size size) {
    final tablet = size.width >= Breakpoints.tablet;
    final minimum = size.width >= Breakpoints.desktop
        ? 720.0
        : tablet
        ? 800.0
        : size.width >= Breakpoints.mobile
        ? 900.0
        : 860.0;
    final appBar = tablet
        ? AppDimensions.appBarHeight
        : AppDimensions.appBarHeightMobile;
    return (size.height - appBar).clamp(minimum, 1080.0);
  }
}

class _HomeLayout extends StatelessWidget {
  const _HomeLayout({required this.portfolio});

  final PortfolioDocument portfolio;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final tablet = size.width >= Breakpoints.tablet;
    final desktop = size.width >= Breakpoints.desktop;
    final horizontal = size.width > AppDimensions.maxContentWidth
        ? AppDimensions.sectionPaddingDesktop
        : tablet
        ? AppDimensions.sectionPaddingTablet
        : AppDimensions.sectionPaddingMobile;
    final roles = portfolio.currentExperience.toList(growable: false);
    return Padding(
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
          if (size.width < 360)
            _UltraNarrowIdentityStory(portfolio: portfolio, currentRoles: roles)
          else
            Expanded(child: _story(context, roles)),
          const SizedBox(height: 12),
          const ScrollIndicator(delay: Duration.zero),
        ],
      ),
    );
  }

  Widget _story(BuildContext context, List<PortfolioExperience> roles) {
    if (MediaQuery.sizeOf(context).width < Breakpoints.desktop) {
      return _CompactIdentityStory(portfolio: portfolio, currentRoles: roles);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 7, child: _IdentityStory(portfolio: portfolio)),
        const SizedBox(width: 88),
        SizedBox(
          width: 340,
          child: _CurrentPractice(profile: portfolio.profile, roles: roles),
        ),
      ],
    );
  }
}
