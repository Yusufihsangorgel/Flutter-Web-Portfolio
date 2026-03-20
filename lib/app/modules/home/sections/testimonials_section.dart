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
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';

/// Testimonials Section — colleague and mentor quotes.
/// Responsive grid: 3 columns desktop, 2 tablet, 1 mobile.
class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Stack(
          children: [
            // Giant watermark
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
                // Section title
                ScrollFadeIn(
                  child: Obx(() {
                    final accent =
                        Get.find<SceneDirector>().currentAccent.value;
                    return Text(
                      languageController.getText(
                        'testimonials_section.title',
                        defaultValue: 'What People Say',
                      ),
                      style: AppTypography.h1.copyWith(color: accent),
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
                // Testimonial cards
                Obx(() {
                  final testimonials =
                      languageController.cvData['testimonials'] as List? ?? [];
                  if (testimonials.isEmpty) return const SizedBox.shrink();
                  return _TestimonialsGrid(testimonials: testimonials);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Responsive grid of testimonial cards
// ---------------------------------------------------------------------------
class _TestimonialsGrid extends StatelessWidget {
  const _TestimonialsGrid({required this.testimonials});

  final List<dynamic> testimonials;

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
      itemBuilder: (context, index) => ScrollFadeIn(
        delay: Duration(milliseconds: 100 * index),
        child: _TestimonialCard(
          testimonial: testimonials[index] as Map<String, dynamic>,
        ),
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
