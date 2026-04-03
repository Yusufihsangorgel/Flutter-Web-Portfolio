import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/data/providers/medium_provider.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';
import 'package:flutter_web_portfolio/app/widgets/border_light_card.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';
import 'package:flutter_web_portfolio/app/widgets/skeleton_shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

/// Blog Section -- fetches posts from Medium RSS feed via MediumProvider.
class BlogSection extends StatefulWidget {
  const BlogSection({super.key});

  @override
  State<BlogSection> createState() => _BlogSectionState();
}

class _BlogSectionState extends State<BlogSection> {
  List<MediumPost>? _posts;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    final languageController = Get.find<LanguageController>();
    final personalInfo =
        languageController.cvData['personal_info'] as Map<String, dynamic>?;
    final username = (personalInfo?['medium'] as String?) ?? '';

    if (username.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final provider = Get.find<MediumProvider>();
      final posts = await provider.fetchPosts(username);
      if (mounted) {
        setState(() {
          _posts = posts;
          _loading = false;
        });
      }
    } catch (e) {
      dev.log('Failed to fetch blog posts', name: 'BlogSection', error: e);
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

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
                if (_loading)
                  _BlogShimmerGrid()
                else if (_error)
                  _ErrorState(onRetry: () {
                    setState(() { _loading = true; _error = false; });
                    _fetchPosts();
                  })
                else if (_posts == null || _posts!.isEmpty)
                  _EmptyState()
                else ...[
                  _BlogGrid(posts: _posts!),
                  const SizedBox(height: 32),
                  _FollowOnMediumLink(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder -- shows 3 skeleton cards in a responsive grid.
class _BlogShimmerGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final columns = screenWidth >= Breakpoints.tablet
        ? 3
        : screenWidth >= Breakpoints.mobile
            ? 2
            : 1;
    final shimmerCount = columns == 1 ? 3 : (columns == 2 ? 4 : 6);
    final rows = <Widget>[];

    for (var i = 0; i < shimmerCount; i += columns) {
      final rowChildren = <Widget>[];
      for (var j = i; j < i + columns && j < shimmerCount; j++) {
        rowChildren.add(
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonShimmer(
                  width: double.infinity,
                  height: 24,
                  borderRadius: 6,
                ),
                SizedBox(height: 12),
                SkeletonShimmer(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 4,
                ),
                SizedBox(height: 8),
                SkeletonShimmer(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 4,
                ),
                SizedBox(height: 8),
                SkeletonShimmer(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 4,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    SkeletonShimmer(width: 60, height: 20, borderRadius: 10),
                    SizedBox(width: 8),
                    SkeletonShimmer(width: 60, height: 20, borderRadius: 10),
                  ],
                ),
              ],
            ),
          ),
        );
      }
      while (rowChildren.length < columns) {
        rowChildren.add(const Expanded(child: SizedBox.shrink()));
      }
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + columns < shimmerCount ? 20 : 0),
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

/// Empty state when no posts are available.
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Obx(() {
      final accent = Get.find<SceneDirector>().currentAccent.value;
      final lang = Get.find<LanguageController>();
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.article_outlined,
                  size: 48, color: accent.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                lang.getText('blog_section.empty', defaultValue: 'No blog posts yet'),
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    });
}

/// Error state with retry button.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Obx(() {
      final accent = Get.find<SceneDirector>().currentAccent.value;
      final lang = Get.find<LanguageController>();
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 48, color: accent.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                lang.getText('blog_section.error', defaultValue: 'Could not load blog posts'),
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh_rounded, size: 16, color: accent),
                label: Text(
                  lang.getText('blog_section.retry', defaultValue: 'Retry'),
                  style: AppTypography.bodySmall.copyWith(color: accent),
                ),
              ),
            ],
          ),
        ),
      );
    });
}

/// Blog card grid -- Column of Rows for reliable responsive layout.
class _BlogGrid extends StatelessWidget {
  const _BlogGrid({required this.posts});

  final List<MediumPost> posts;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final columns = screenWidth >= Breakpoints.tablet
        ? 3
        : screenWidth >= Breakpoints.mobile
            ? 2
            : 1;

    final rows = <Widget>[];
    for (var i = 0; i < posts.length; i += columns) {
      final rowChildren = <Widget>[];
      for (var j = i; j < i + columns && j < posts.length; j++) {
        rowChildren.add(
          Expanded(
            child: ScrollFadeIn(
              delay: Duration(milliseconds: 100 * j),
              child: _BlogPostCard(post: posts[j]),
            ),
          ),
        );
      }
      while (rowChildren.length < columns) {
        rowChildren.add(const Expanded(child: SizedBox.shrink()));
      }
      rows.add(
        Padding(
          padding:
              EdgeInsets.only(bottom: i + columns < posts.length ? 20 : 0),
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

/// Single blog post card backed by MediumPost data.
class _BlogPostCard extends StatelessWidget {
  const _BlogPostCard({required this.post});

  final MediumPost post;

  @override
  Widget build(BuildContext context) => Obx(() {
      final accent = Get.find<SceneDirector>().currentAccent.value;
      return CinematicFocusable(
        onTap: post.link.isNotEmpty
            ? () async {
                final uri = Uri.parse(post.link);
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
              // Thumbnail
              if (post.thumbnail.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.thumbnail,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        size: 32,
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Date + Medium badge
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 14, color: accent.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(post.pubDate, style: AppTypography.caption),
                  ),
                  const Spacer(),
                  _MediumBadge(accent: accent),
                ],
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                post.title,
                style: AppTypography.h3.copyWith(color: AppColors.textBright),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                post.description,
                style: AppTypography.bodySmall.copyWith(height: 1.6),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              // Tags
              if (post.categories.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: post.categories
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

/// Small "Read on Medium" badge shown on each card.
class _MediumBadge extends StatelessWidget {
  const _MediumBadge({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_stories_rounded,
            size: 14, color: accent.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          Get.find<LanguageController>().getText('blog_section.read_on_medium', defaultValue: 'Read on Medium'),
          style: AppTypography.caption.copyWith(
            color: accent.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
}

/// "Follow on Medium" link at the bottom of the section.
class _FollowOnMediumLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return Obx(() {
      final accent = Get.find<SceneDirector>().currentAccent.value;
      final mediumUrl = languageController.getText('social_links.medium');
      // Fallback: construct from username if social_links.medium is empty.
      final personalInfo =
          languageController.cvData['personal_info'] as Map<String, dynamic>?;
      final username = (personalInfo?['medium'] as String?) ?? '';
      final url = mediumUrl.isNotEmpty
          ? mediumUrl
          : (username.isNotEmpty
              ? 'https://medium.com/@$username'
              : '');

      if (url.isEmpty) return const SizedBox.shrink();

      return Center(
        child: CinematicFocusable(
          onTap: () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: accent.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_stories_rounded,
                    size: 18, color: accent),
                const SizedBox(width: 8),
                Text(
                  languageController.getText('blog_section.follow_on_medium', defaultValue: 'Follow on Medium'),
                  style: AppTypography.bodySmall.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded,
                    size: 16, color: accent),
              ],
            ),
          ),
        ),
      );
    });
  }
}
