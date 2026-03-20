import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_button.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_indicator.dart';
import 'package:flutter_web_portfolio/app/widgets/shader_text_reveal.dart';
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
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 1400 ? 160 : (screenWidth > 900 ? 80 : 24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Name
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ShaderTextReveal(
                          text: languageController.getText(
                            'home_section.title',
                            defaultValue: 'YUSUF IHSAN GORGEL',
                          ).toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: heroFontSize,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textBright,
                            letterSpacing: -4,
                            height: 1.0,
                          ),
                          delay: AppDurations.heroNameRevealDelay,
                          duration: AppDurations.heroNameRevealDuration,
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Horizontal line between name and subtitle
                      const SizedBox(height: 20),
                      Container(
                        height: 1,
                        width: screenWidth * 0.5 * _lineWidth.value,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Subtitle
                      ShaderTextReveal(
                        text: languageController.getText(
                          'home_section.subtitle',
                          defaultValue: 'Mobile Software Engineer',
                        ),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: (heroFontSize * 0.35).clamp(18.0, 42.0),
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                          letterSpacing: 2,
                          height: 1.3,
                        ),
                        delay: AppDurations.heroSubtitleDelay,
                        duration: AppDurations.heroSubtitleDuration,
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
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 12,
          children: [
            CinematicButton(
              label: widget.languageController.getText(
                'home_section.view_work',
                defaultValue: 'View My Work',
              ),
              onTap: () => Get.find<AppScrollController>()
                  .scrollToSection('projects'),
            ),
            CinematicButton(
              label: widget.languageController.getText(
                'home_section.download_cv',
                defaultValue: 'Download CV',
              ),
              onTap: () async {
                final baseUrl = Uri.base.toString();
                final cvUrl = '${baseUrl}assets/data/cv.pdf';
                final uri = Uri.parse(cvUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}
