import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';
import 'package:flutter_web_portfolio/app/widgets/border_light_card.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';

/// Testimonials Section — colleague and mentor quotes.
/// Desktop: responsive grid (3 columns).
/// Mobile/tablet (< 900px): auto-rotating carousel with dot indicators.
class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Obx(() {
      final raw =
          languageController.cvData['testimonials'] as List? ?? [];
      final testimonials = raw.cast<Map<String, dynamic>>();
      if (testimonials.isEmpty) return const SizedBox.shrink();

      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                left: -10,
                child: Obx(() => Text(
                  languageController
                      .getText('nav.testimonials', defaultValue: 'Testimonials')
                      .toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: ResponsiveUtils.getValueForScreenType<double>(
                      context: context,
                      mobile: 36.0,
                      tablet: screenWidth * 0.10,
                      desktop: screenWidth * 0.12,
                    ),
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.03),
                    letterSpacing: -3,
                  ),
                )),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  ScrollFadeIn(
                    child: Obx(() {
                      final accent =
                          Get.find<SceneDirector>().currentAccent.value;
                      return NumberedSectionHeading(
                        number: '03',
                        title: languageController.getText(
                          'testimonials_section.title',
                          defaultValue: 'What People Say',
                        ),
                        accent: accent,
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  ScrollFadeIn(
                    delay: AppDurations.staggerShort,
                    child: Text(
                      languageController.getText(
                        'testimonials_section.subtitle',
                        defaultValue:
                            'Feedback from colleagues and mentors I have worked with',
                      ),
                      style: AppTypography.body,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Builder(builder: (context) {
                    final isDesktop = screenWidth >= Breakpoints.tablet;
                    if (isDesktop) {
                      return _TestimonialsGrid(testimonials: testimonials);
                    }
                    return _TestimonialsCarousel(testimonials: testimonials);
                  }),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Responsive grid of testimonial cards (desktop only, >= 900px)
// ---------------------------------------------------------------------------
class _TestimonialsGrid extends StatelessWidget {
  const _TestimonialsGrid({required this.testimonials});

  final List<Map<String, dynamic>> testimonials;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = screenWidth >= Breakpoints.tablet
        ? 3
        : (screenWidth >= Breakpoints.mobile ? 2 : 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: crossAxisCount == 1 ? 1.8 : 0.85,
      ),
      itemCount: testimonials.length,
      itemBuilder: (context, index) => _TestimonialCard(
        testimonial: testimonials[index],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Auto-rotating carousel for mobile / tablet (< 900px)
// ---------------------------------------------------------------------------
class _TestimonialsCarousel extends StatefulWidget {
  const _TestimonialsCarousel({required this.testimonials});

  final List<Map<String, dynamic>> testimonials;

  @override
  State<_TestimonialsCarousel> createState() => _TestimonialsCarouselState();
}

class _TestimonialsCarouselState extends State<_TestimonialsCarousel> {
  late final PageController _pageController;
  Timer? _autoAdvanceTimer;
  int _currentPage = 0;

  static const _autoAdvanceInterval = Duration(seconds: 5);
  static const _resumeDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoAdvance();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(_autoAdvanceInterval, (_) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % widget.testimonials.length;
      _pageController.animateToPage(
        nextPage,
        duration: AppDurations.entrance,
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _onManualSwipe() {
    // Cancel auto-advance, resume after delay.
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
    Future.delayed(_resumeDelay, () {
      if (mounted) _startAutoAdvance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.testimonials.length;

    return ScrollFadeIn(
      child: Column(
        children: [
          SizedBox(
            height: 280,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification &&
                    notification.dragDetails != null) {
                  _onManualSwipe();
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: count,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _TestimonialCard(
                    testimonial: widget.testimonials[index],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Dot indicators
          Obx(() {
            final accent = Get.find<SceneDirector>().currentAccent.value;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                count,
                (i) => AnimatedContainer(
                  duration: AppDurations.fast,
                  width: i == _currentPage ? 8 : 4,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i == _currentPage
                        ? accent
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single testimonial card
// ---------------------------------------------------------------------------
class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.testimonial});

  final Map<String, dynamic> testimonial;

  @override
  Widget build(BuildContext context) {
    final quote = testimonial['quote'] as String? ?? '';
    final name = testimonial['name'] as String? ?? '';
    final position = testimonial['position'] as String? ?? '';
    final company = testimonial['company'] as String? ?? '';

    return Obx(() {
      final accent = Get.find<SceneDirector>().currentAccent.value;
      return BorderLightCard(
        glowColor: accent,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quote icon
            Icon(
              Icons.format_quote_rounded,
              color: accent.withValues(alpha: 0.4),
              size: 28,
            ),
            const SizedBox(height: 12),
            // Quote text
            Expanded(
              child: Text(
                quote,
                style: AppTypography.bodySmall.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            // Divider
            Container(
              width: 40,
              height: 1,
              color: accent.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            // Author
            Text(
              name,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textBright,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$position, $company',
              style: AppTypography.caption.copyWith(
                color: accent.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    });
  }
}
