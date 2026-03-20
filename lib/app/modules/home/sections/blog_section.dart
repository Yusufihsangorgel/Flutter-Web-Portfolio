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
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';
import 'package:url_launcher/url_launcher.dart';

/// Blog Section — displays blog post cards loaded from i18n JSON.
/// Responsive grid: 3 columns desktop (>=900px), 2 columns tablet (600-900px),
/// 1 column mobile (<600px).
class BlogSection extends StatelessWidget {
  const BlogSection({super.key});

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
                    .getText('nav.blog', defaultValue: 'Blog')
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
                        'blog_section.title',
                        defaultValue: 'Blog',
                      ),
                      style: AppTypography.h1.copyWith(color: accent),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                ScrollFadeIn(
                  delay: AppDurations.staggerShort,
                  child: Obx(() => Text(
                    languageController.getText(
                      'blog_section.subtitle',
                      defaultValue:
                          'Thoughts, tutorials, and insights on mobile development',
                    ),
                    style: AppTypography.body,
                  )),
                ),
                const SizedBox(height: 40),
                // Blog post cards
                Obx(() {
                  final blogPosts =
                      languageController.cvData['blog_posts'] as List? ?? [];
                  if (blogPosts.isEmpty) return const SizedBox.shrink();
                  return _BlogGrid(blogPosts: blogPosts);
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
// Responsive grid of blog post cards
// ---------------------------------------------------------------------------
class _BlogGrid extends StatelessWidget {
  const _BlogGrid({required this.blogPosts});

  final List<dynamic> blogPosts;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final int crossAxisCount;
    final double childAspectRatio;

    if (screenWidth >= Breakpoints.tablet) {
      crossAxisCount = 3;
      childAspectRatio = 1.0;
    } else if (screenWidth >= Breakpoints.mobile) {
      crossAxisCount = 2;
      childAspectRatio = 1.3;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 1.6;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: blogPosts.length,
      itemBuilder: (context, index) => ScrollFadeIn(
        delay: Duration(milliseconds: 100 * index),
        child: _BlogPostCard(
          post: blogPosts[index] as Map<String, dynamic>,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single blog post card
// ---------------------------------------------------------------------------
class _BlogPostCard extends StatelessWidget {
  const _BlogPostCard({required this.post});

  final Map<String, dynamic> post;

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool get _isComingSoon {
    final url = post['url'] as String? ?? '';
    return url == '#';
  }

  @override
  Widget build(BuildContext context) {
    final title = post['title'] as String? ?? '';
    final date = post['date'] as String? ?? '';
    final summary = post['summary'] as String? ?? '';
    final readTime = post['readTime'] as String? ?? '';
    final tags = (post['tags'] as List?)?.cast<String>() ?? [];
    final url = post['url'] as String? ?? '';
    final isComingSoon = _isComingSoon;

    return Obx(() {
      final accent = Get.find<SceneDirector>().currentAccent.value;
      return CinematicFocusable(
        onTap: url.isNotEmpty && !isComingSoon ? () => _openUrl(url) : () {},
        child: BorderLightCard(
          glowColor: accent,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and read time row
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: accent.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: accent.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    readTime,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (isComingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Coming Soon',
                        style: AppTypography.caption.copyWith(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  else if (url.isNotEmpty)
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                      color: accent.withValues(alpha: 0.5),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                title,
                style: AppTypography.h3.copyWith(
                  color: AppColors.textBright,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Summary
              Expanded(
                child: Text(
                  summary,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              // Tags
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: tags
                    .map((tag) => _TagPill(tag: tag, accent: accent))
                    .toList(),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Tag pill
// ---------------------------------------------------------------------------
class _TagPill extends StatelessWidget {
  const _TagPill({required this.tag, required this.accent});

  final String tag;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: accent.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
    child: Text(
      tag,
      style: AppTypography.caption.copyWith(
        color: accent,
        fontSize: 11,
      ),
    ),
  );
}
