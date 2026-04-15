import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_button.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_indicator.dart';
import 'package:flutter_web_portfolio/app/widgets/shader_text_reveal.dart';
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
  List<String>? _subtitleTexts(LanguageController lc) {
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
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;

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
                onExit: (_) => setState(
                  () => _heroMousePos = const Offset(0.5, 0.5),
                ),
                child: AnimatedContainer(
                  duration: AppDurations.medium,
                  transform: _buildHeroTransform(screenWidth),
                  transformAlignment: Alignment.center,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth > AppDimensions.maxContentWidth
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
                          Builder(builder: (context) {
                            const lineColor = Colors.white;
                            return Container(
                              height: 1.5,
                              width: (screenWidth * 0.4).clamp(100, 600).toDouble() * _lineWidth.value,
                              decoration: BoxDecoration(
                                color: lineColor.withValues(alpha: 0.4),
                                boxShadow: [
                                  BoxShadow(
                                    color: lineColor.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 20),

                          // Subtitle — typewriter cycling effect
                          TypewriterText(
                            text: languageController.getText(
                              'home_section.subtitle',
                              defaultValue: 'Mobile Software Engineer',
                            ),
                            texts: _subtitleTexts(languageController),
                            loop: true,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: (heroFontSize * 0.35).clamp(18.0, 42.0),
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
                              defaultValue: 'Antalya, Türkiye',
                            ),
                            style: GoogleFonts.jetBrainsMono(
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
  final LanguageController languageController;

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
    _ctrl = AnimationController(
      vsync: this,
      duration: AppDurations.entrance,
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: CinematicCurves.revealDecel);
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
    builder: (_, __) => Opacity(
      opacity: _opacity.value,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - _opacity.value)),
        child: Obx(() {
          // Touch reactive translations so the button labels rebuild on
          // language change. Without this, Wrap caches the original labels.
          final viewWorkLabel = widget.languageController.getText(
            'home_section.view_work',
            defaultValue: 'View My Work',
          );
          final downloadCvLabel = widget.languageController.getText(
            'home_section.download_cv',
            defaultValue: 'Download CV',
          );
          return Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 16,
          children: [
            CinematicButton(
              label: viewWorkLabel,
              isPrimary: true,
              onTap: () => Get.find<AppScrollController>()
                  .scrollToSection('projects'),
            ),
            CinematicButton(
              label: downloadCvLabel,
              onTap: () async {
                final origin = Uri.base.origin;
                final basePath = Uri.base.path.endsWith('/')
                    ? Uri.base.path
                    : '${Uri.base.path}/';
                final uri = Uri.parse('$origin${basePath}assets/data/cv.pdf');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
          );
        }),
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

  final LanguageController languageController;
  final double heroFontSize;

  @override
  Widget build(BuildContext context) {
    final nameText = languageController.getText(
      'home_section.title',
      defaultValue: 'YUSUF IHSAN GORGEL',
    ).toUpperCase();

    final nameStyle = GoogleFonts.spaceGrotesk(
      fontSize: heroFontSize,
      fontWeight: FontWeight.w800,
      color: AppColors.textBright,
      letterSpacing: -4,
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
          builder: (context, complete, _) {
            final accent = Get.find<SceneDirector>().currentAccent.value;
            return AnimatedOpacity(
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
                      Color.lerp(
                        AppColors.textBright,
                        accent,
                        0.20,
                      )!,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    nameText,
                    style: nameStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
