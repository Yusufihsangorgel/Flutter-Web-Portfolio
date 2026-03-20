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
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';
import 'package:url_launcher/url_launcher.dart';

/// Blog Section — article cards from i18n JSON.
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
                  color: Colors.white.withValues(alpha: 0.02),
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
                      number: '04',
                      title: languageController.getText(
                        'blog_section.title',
                        defaultValue: 'Blog',
                      ),
                      accent: accent,
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
                Obx(() {
                  languageController.currentLanguage;
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

// Blog card grid — Column of Rows instead of GridView for reliable layout
class _BlogGrid extends StatelessWidget {
  const _BlogGrid({required this.blogPosts});

  final List<dynamic> blogPosts;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final columns = screenWidth >= Breakpoints.tablet
        ? 3
        : screenWidth >= Breakpoints.mobile
            ? 2
            : 1;

    final rows = <Widget>[];
    for (var i = 0; i < blogPosts.length; i += columns) {
      final rowChildren = <Widget>[];
      for (var j = i; j < i + columns && j < blogPosts.length; j++) {
        rowChildren.add(
          Expanded(
            child: ScrollFadeIn(
              delay: Duration(milliseconds: 100 * j),
              child: _BlogPostCard(
                post: blogPosts[j] as Map<String, dynamic>,
              ),
            ),
          ),
        );
      }
      // Fill remaining slots with empty Expanded to keep alignment
      while (rowChildren.length < columns) {
        rowChildren.add(const Expanded(child: SizedBox.shrink()));
      }
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + columns < blogPosts.length ? 20 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var k = 0; k < rowChildren.length; k++) ...[
                if (k > 0) const SizedBox(width: 20),
                rowChildren[k],
              ],
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}

// Single blog post card
class _BlogPostCard extends StatelessWidget {
  const _BlogPostCard({required this.post});

  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) {
    final title = post['title'] as String? ?? '';
    final date = post['date'] as String? ?? '';
    final summary = post['summary'] as String? ?? '';
    final readTime = post['readTime'] as String? ?? '';
    final tags = (post['tags'] as List?)?.cast<String>() ?? [];
    final url = post['url'] as String? ?? '';

    return Obx(() {
      final accent = Get.find<SceneDirector>().currentAccent.value;
      return CinematicFocusable(
        onTap: url.isNotEmpty && url != '#'
            ? () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            : () {},
        child: BorderLightCard(
          glowColor: accent,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date + read time
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 14, color: accent.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(date, style: AppTypography.caption),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule_rounded,
                      size: 14, color: accent.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(readTime, style: AppTypography.caption),
                  const Spacer(),
                  if (url.isNotEmpty && url != '#')
                    Icon(Icons.open_in_new_rounded,
                        size: 16, color: accent.withValues(alpha: 0.5)),
                ],
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                title,
                style: AppTypography.h3.copyWith(color: AppColors.textBright),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Summary
              Text(
                summary,
                style: AppTypography.bodySmall.copyWith(height: 1.6),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              // Tags
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: tags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: accent.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            tag,
                            style: AppTypography.caption
                                .copyWith(color: accent, fontSize: 11),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      );
    });
  }
}
