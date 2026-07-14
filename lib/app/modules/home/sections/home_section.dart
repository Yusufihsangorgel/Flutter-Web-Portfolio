import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_button.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/features/engineering_lab/presentation/engineering_lab.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_indicator.dart';
import 'package:flutter_web_portfolio/app/widgets/shader_text_reveal.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';
import 'package:flutter_web_portfolio/app/widgets/typewriter_text.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';

/// Hero Section — "The Opening Shot"
/// Cinematic entrance: line draw → name reveal → subtitle → CTA assembly
class HomeSection extends StatefulWidget {
  const HomeSection({super.key});

  /// Notifies listeners when the entrance animation completes.
  static final ValueNotifier<bool> entranceComplete = ValueNotifier(false);

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection>
    with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double> _lineWidth;
  late Animation<double> _contentOpacity;

  /// Normalised mouse position within the hero section (0–1 on each axis).
  /// Defaults to centre so the transform starts at identity.
  Offset _heroMousePos = const Offset(0.5, 0.5);

  @override
  void initState() {
    super.initState();
    HomeSection.entranceComplete.value = false;

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.heroEntrance,
    );

    _entranceCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HomeSection.entranceComplete.value = true;
      }
    });

    // 0–25%: horizontal line draws
    _lineWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.25, curve: CinematicCurves.revealDecel),
      ),
    );

    // 25–100%: content fades in
    _contentOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.2, 0.35, curve: Curves.easeOut),
      ),
    );

    // 400ms initial darkness, then start
    Future.delayed(AppDurations.heroInitialPause, () {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  /// Returns subtitle texts for the typewriter cycling effect.
  /// Falls back to a single subtitle if the JSON key is missing.
  List<String>? _subtitleTexts(LanguageCubit lc) {
    final raw = lc.cvData['personal_info']?['subtitles'];
    if (raw is List && raw.isNotEmpty) {
      return raw.whereType<String>().toList();
    }
    return null;
  }

  /// Builds a subtle 3D perspective matrix that follows the mouse cursor.
  /// Returns [Matrix4.identity] on mobile/tablet to avoid touch jank.
  Matrix4 _buildHeroTransform(double screenWidth) {
    if (screenWidth < 900) return Matrix4.identity();
    const maxTilt = 2.0 * pi / 180.0; // 2 degrees
    final dx = (_heroMousePos.dx - 0.5) * 2.0;
    final dy = (_heroMousePos.dy - 0.5) * 2.0;
    return Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateY(dx * maxTilt)
      ..rotateX(-dy * maxTilt);
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) => _buildContent(context),
      );

  Widget _buildContent(BuildContext context) {
    final languageController = context.read<LanguageCubit>();
    final screenSize = MediaQuery.sizeOf(context);
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    final appBarHeight = ResponsiveUtils.getValueForScreenType<double>(
      context: context,
      mobile: 60,
      tablet: 70,
      desktop: 80,
    );

    // Responsive hero font size — avoids overflow on narrow screens
    final heroFontSize = ResponsiveUtils.getValueForScreenType<double>(
      context: context,
      mobile: 32.0,
      tablet: 56.0,
      desktop: (screenWidth * 0.07).clamp(60.0, 120.0),
    );

    return GestureDetector(
      onTap: () {
        if (!_entranceCtrl.isCompleted) {
          _entranceCtrl.forward(from: 1.0);
        }
      },
      child: SizedBox(
        width: double.infinity,
        height: screenHeight - appBarHeight,
        child: AnimatedBuilder(
          animation: _entranceCtrl,
          builder: (context, _) => Stack(
            children: [
              // Main content
              Opacity(
                opacity: _contentOpacity.value,
                child: MouseRegion(
                  onHover: (e) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    setState(() {
                      _heroMousePos = Offset(
                        e.localPosition.dx / box.size.width,
                        e.localPosition.dy / box.size.height,
                      );
                    });
                  },
                  onExit: (_) =>
                      setState(() => _heroMousePos = const Offset(0.5, 0.5)),
                  child: AnimatedContainer(
                    duration: AppDurations.medium,
                    transform: _buildHeroTransform(screenWidth),
                    transformAlignment: Alignment.center,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              screenWidth > AppDimensions.maxContentWidth
                              ? AppDimensions.sectionPaddingDesktop
                              : (screenWidth > Breakpoints.tablet
                                    ? AppDimensions.sectionPaddingTablet
                                    : AppDimensions.sectionPaddingMobile),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Name — gradient overlay fades in after reveal
                            _HeroNameWithGradient(
                              languageController: languageController,
                              heroFontSize: heroFontSize,
                            ),

                            // Horizontal line between name and subtitle
                            const SizedBox(height: 20),
                            Builder(
                              builder: (context) {
                                const lineColor = Colors.white;
                                return Container(
                                  height: 1.5,
                                  width:
                                      (screenWidth * 0.4)
                                          .clamp(100, 600)
                                          .toDouble() *
                                      _lineWidth.value,
                                  decoration: BoxDecoration(
                                    color: lineColor.withValues(alpha: 0.4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: lineColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // Subtitle — typewriter cycling effect
                            TypewriterText(
                              text: languageController.getText(
                                'home_section.subtitle',
                                defaultValue: 'Mobile Software Engineer',
                              ),
                              texts: _subtitleTexts(languageController),
                              loop: true,
                              style: AppFonts.spaceGrotesk(
                                fontSize: (heroFontSize * 0.35).clamp(
                                  18.0,
                                  42.0,
                                ),
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                                letterSpacing: 2,
                                height: 1.3,
                              ),
                              delay: AppDurations.heroSubtitleDelay,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),

                            // Location — monospace
                            ShaderTextReveal(
                              text: languageController.getText(
                                'cv_data.personal_info.location',
                                defaultValue: 'Remote',
                              ),
                              style: AppFonts.jetBrainsMono(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                                letterSpacing: 3,
                              ),
                              delay: AppDurations.heroLocationDelay,
                              duration: AppDurations.heroLocationDuration,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 56),

                            // CTA buttons — pixel assembly effect
                            _AnimatedCTAButtons(
                              delay: AppDurations.heroCTADelay,
                              languageController: languageController,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Scroll indicator at bottom
              if (_contentOpacity.value > 0.5)
                const Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: ScrollIndicator(
                    delay: AppDurations.heroScrollIndicator,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CTA Buttons with staggered entrance
// ---------------------------------------------------------------------------
class _AnimatedCTAButtons extends StatefulWidget {
  const _AnimatedCTAButtons({
    required this.delay,
    required this.languageController,
  });
  final Duration delay;
  final LanguageCubit languageController;

  @override
  State<_AnimatedCTAButtons> createState() => _AnimatedCTAButtonsState();
}

class _AnimatedCTAButtonsState extends State<_AnimatedCTAButtons>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppDurations.entrance);
    _opacity = CurvedAnimation(
      parent: _ctrl,
      curve: CinematicCurves.revealDecel,
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _opacity,
    builder: (_, _) => Opacity(
      opacity: _opacity.value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - _opacity.value)),
        child: BlocBuilder<LanguageCubit, LanguageState>(
          builder: (context, _) {
            final viewWorkLabel = widget.languageController.getText(
              'home_section.view_work',
              defaultValue: 'View My Work',
            );
            final inspectRuntimeLabel = widget.languageController.getText(
              'home_section.inspect_runtime',
              defaultValue: 'Inspect Runtime',
            );
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 16,
              children: [
                CinematicButton(
                  label: viewWorkLabel,
                  isPrimary: true,
                  onTap: () => context
                      .read<AppScrollController>()
                      .scrollToSection('projects'),
                ),
                CinematicButton(
                  label: inspectRuntimeLabel,
                  onTap: () {
                    final scrollController = context
                        .read<AppScrollController>();
                    EngineeringLab.show(
                      context,
                      activeSection: scrollController.activeSection,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Hero name with gradient that fades in after the entrance reveal completes.
// Uses a Stack: base layer is the ShaderTextReveal (for the sweep animation),
// top layer is a gradient-masked copy that cross-fades in once done.
// ---------------------------------------------------------------------------
class _HeroNameWithGradient extends StatelessWidget {
  const _HeroNameWithGradient({
    required this.languageController,
    required this.heroFontSize,
  });

  final LanguageCubit languageController;
  final double heroFontSize;

  @override
  Widget build(BuildContext context) {
    final nameText = languageController
        .getText('home_section.title', defaultValue: 'SYSTEMS PORTFOLIO')
        .toUpperCase();

    final isMobile = MediaQuery.sizeOf(context).width < Breakpoints.mobile;
    final nameStyle = AppFonts.spaceGrotesk(
      fontSize: heroFontSize,
      fontWeight: FontWeight.w800,
      color: AppColors.textBright,
      letterSpacing: isMobile ? -1 : -4,
      height: 1.0,
    );

    return Stack(
      children: [
        // Base layer — the original ShaderTextReveal with sweep animation
        FittedBox(
          fit: BoxFit.scaleDown,
          child: ShaderTextReveal(
            text: nameText,
            style: nameStyle,
            delay: AppDurations.heroNameRevealDelay,
            duration: AppDurations.heroNameRevealDuration,
            textAlign: TextAlign.center,
          ),
        ),
        // Top layer — gradient text that fades in after entrance completes
        ValueListenableBuilder<bool>(
          valueListenable: HomeSection.entranceComplete,
          builder: (context, complete, _) => SceneAccentBuilder(
            builder: (context, accent) => AnimatedOpacity(
              opacity: complete ? 1.0 : 0.0,
              duration: AppDurations.entrance,
              curve: Curves.easeOut,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppColors.textBright,
                      Color.lerp(AppColors.textBright, accent, 0.20)!,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    nameText,
                    style: nameStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
