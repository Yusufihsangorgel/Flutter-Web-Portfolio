import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_button.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_indicator.dart';

/// A direct, content-first introduction to the portfolio.
class HomeSection extends StatefulWidget {
  const HomeSection({super.key});

  /// Used by the page shell to reveal navigation after the hero arrives.
  static final ValueNotifier<bool> entranceComplete = ValueNotifier(false);

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    HomeSection.entranceComplete.value = false;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HomeSection.entranceComplete.value = true;
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 140), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LanguageCubit, LanguageState>(
    builder: (context, _) {
      final language = context.read<LanguageCubit>();
      final size = MediaQuery.sizeOf(context);
      final horizontalPadding = size.width > AppDimensions.maxContentWidth
          ? AppDimensions.sectionPaddingDesktop
          : size.width > Breakpoints.tablet
          ? AppDimensions.sectionPaddingTablet
          : AppDimensions.sectionPaddingMobile;
      final titleSize = size.width < Breakpoints.tablet
          ? (size.width * 0.115).clamp(40.0, 58.0)
          : (size.width * 0.065).clamp(64.0, 104.0);
      final title = language
          .getText(
            'home_section.title',
            defaultValue: 'SENIOR FLUTTER ENGINEER.',
          )
          .toUpperCase();

      return SizedBox(
        width: double.infinity,
        height: size.height - (size.width < Breakpoints.tablet ? 60 : 80),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: FadeTransition(
                    opacity: _opacity,
                    child: SlideTransition(
                      position: _slide,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            language.getText(
                              'cv_data.personal_info.tagline',
                              defaultValue:
                                  'Product-minded Flutter engineering',
                            ),
                            style: AppFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.heroAccent,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Semantics(
                            header: true,
                            headingLevel: 1,
                            label: title,
                            excludeSemantics: true,
                            child: ExcludeSemantics(
                              child: Text(
                                title,
                                style: AppFonts.spaceGrotesk(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textBright,
                                  height: 0.96,
                                  letterSpacing: -3.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 650),
                            child: Text(
                              language.getText(
                                'home_section.subtitle',
                                defaultValue:
                                    'Building useful products across mobile, desktop, and web.',
                              ),
                              style: AppFonts.spaceGrotesk(
                                fontSize: size.width < Breakpoints.tablet
                                    ? 20
                                    : 27,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                                height: 1.45,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            language.getText(
                              'cv_data.personal_info.location',
                              defaultValue: 'Remote',
                            ),
                            style: AppFonts.jetBrainsMono(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 42),
                          Wrap(
                            spacing: 16,
                            runSpacing: 14,
                            children: [
                              CinematicButton(
                                label: language.getText(
                                  'home_section.view_work',
                                  defaultValue: 'View selected work',
                                ),
                                isPrimary: true,
                                onTap: () => context
                                    .read<AppScrollController>()
                                    .scrollToSection('projects'),
                              ),
                              CinematicButton(
                                label: language.getText(
                                  'home_section.inspect_runtime',
                                  defaultValue: 'About me',
                                ),
                                onTap: () => context
                                    .read<AppScrollController>()
                                    .scrollToSection('about'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: ScrollIndicator(delay: Duration(milliseconds: 900)),
            ),
          ],
        ),
      );
    },
  );
}
