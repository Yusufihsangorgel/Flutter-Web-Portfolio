import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_web_portfolio/app/controllers/cursor_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/data/providers/medium_provider.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:url_launcher/url_launcher.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 1. BlogCard — Premium blog post card with hover effects & entrance anim
// ═══════════════════════════════════════════════════════════════════════════

/// Data model for a premium blog card.
/// Wraps [MediumPost] with additional display fields.
class BlogCardData {
  const BlogCardData({
    required this.title,
    required this.excerpt,
    required this.thumbnailUrl,
    required this.date,
    required this.readTime,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.url,
    this.category = '',
    this.categoryColor,
    this.tags = const [],
  });

  /// Convenience factory from a [MediumPost].
  factory BlogCardData.fromMediumPost(
    MediumPost post, {
    String authorName = '',
    String authorAvatarUrl = '',
  }) {
    // Estimate read time: ~200 words/min, ~5 chars/word
    final wordCount = post.description.length / 5;
    final minutes = (wordCount / 200).ceil().clamp(1, 30);

    return BlogCardData(
      title: post.title,
      excerpt: post.description,
      thumbnailUrl: post.thumbnail,
      date: post.pubDate,
      readTime: '$minutes min read',
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      url: post.link,
      category: post.categories.isNotEmpty ? post.categories.first : '',
      tags: post.categories,
    );
  }

  final String title;
  final String excerpt;
  final String thumbnailUrl;
  final String date;
  final String readTime;
  final String authorName;
  final String authorAvatarUrl;
  final String url;
  final String category;
  final Color? categoryColor;
  final List<String> tags;
}

/// Premium blog post card with image thumbnail, category pill, hover
/// effects (image zoom, shadow lift, title color shift, 3D tilt), and
/// fade-up + scale entrance animation.
class BlogCard extends StatefulWidget {
  const BlogCard({
    super.key,
    required this.data,
    this.accentColor,
    this.entranceDelay = Duration.zero,
    this.onTap,
  });

  final BlogCardData data;
  final Color? accentColor;
  final Duration entranceDelay;
  final VoidCallback? onTap;

  @override
  State<BlogCard> createState() => _BlogCardState();
}

class _BlogCardState extends State<BlogCard>
    with SingleTickerProviderStateMixin {
  // Hover state
  final _hovered = ValueNotifier<bool>(false);
  final _mousePos = ValueNotifier<Offset>(Offset.zero);
  Size _cardSize = Size.zero;

  // Entrance animation
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.entrance,
    );

    final curved = CurvedAnimation(
      parent: _entranceCtrl,
      curve: CinematicCurves.dramaticEntrance,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(curved);
    _scaleAnim = Tween<double>(begin: 0.95, end: 1).animate(curved);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(curved);

    if (widget.entranceDelay == Duration.zero) {
      _entranceCtrl.forward();
    } else {
      Future.delayed(widget.entranceDelay, () {
        if (mounted) _entranceCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _hovered.dispose();
    _mousePos.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    if (widget.data.url.isNotEmpty) {
      final uri = Uri.tryParse(widget.data.url);
      if (uri != null) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ??
        Get.find<SceneDirector>().currentAccent.value;

    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (_, child) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.translate(
          offset: _slideAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          _cardSize = Size(
            constraints.maxWidth,
            constraints.maxHeight.isFinite ? constraints.maxHeight : 400,
          );
          return _buildCard(context, accent);
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, Color accent) {
    return CinematicFocusable(
      onTap: _handleTap,
      onHoverChanged: (hovered) {
        _hovered.value = hovered;
        if (Get.isRegistered<CursorController>()) {
          Get.find<CursorController>().isHovering.value = hovered;
        }
      },
      child: MouseRegion(
        onHover: (e) => _mousePos.value = e.localPosition,
        onExit: (_) => _mousePos.value = Offset.zero,
        child: ValueListenableBuilder<bool>(
          valueListenable: _hovered,
          builder: (context, hovered, _) =>
              ValueListenableBuilder<Offset>(
            valueListenable: _mousePos,
            builder: (context, mousePos, _) {
              // 3D tilt calculation
              double tiltX = 0;
              double tiltY = 0;
              if (hovered && _cardSize.width > 0) {
                final nx = (mousePos.dx / _cardSize.width - 0.5) * 2;
                final ny = (mousePos.dy /
                        (_cardSize.height > 0 ? _cardSize.height : 400) -
                    0.5) *
                    2;
                tiltY = nx * 2.0 * (math.pi / 180);
                tiltX = -ny * 2.0 * (math.pi / 180);
              }

              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(tiltX)
                ..rotateY(tiltY);
              if (hovered) {
                transform.storage[13] -= 4; // lift
              }

              return AnimatedContainer(
                duration: AppDurations.veryFast,
                transform: transform,
                transformAlignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(
                        alpha: hovered ? 0.15 : 0.05,
                      ),
                      blurRadius: hovered ? 24 : 8,
                      offset: Offset(0, hovered ? 8 : 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight.withValues(alpha: 0.6),
                      border: Border.all(
                        color: (hovered ? accent : Colors.white)
                            .withValues(alpha: hovered ? 0.15 : 0.05),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Thumbnail with category overlay ──
                        _Thumbnail(
                          url: widget.data.thumbnailUrl,
                          category: widget.data.category,
                          categoryColor:
                              widget.data.categoryColor ?? accent,
                          hovered: hovered,
                        ),
                        // ── Content ──
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              AnimatedDefaultTextStyle(
                                duration: AppDurations.fast,
                                style: AppTypography.h3.copyWith(
                                  color: hovered
                                      ? accent
                                      : AppColors.textBright,
                                ),
                                child: Text(
                                  widget.data.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Excerpt
                              Text(
                                widget.data.excerpt,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall
                                    .copyWith(height: 1.6),
                              ),
                              const SizedBox(height: 16),
                              // Author row
                              _AuthorRow(
                                name: widget.data.authorName,
                                avatarUrl: widget.data.authorAvatarUrl,
                                date: widget.data.date,
                                readTime: widget.data.readTime,
                                accent: accent,
                              ),
                              // Tags
                              if (widget.data.tags.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                _TagRow(
                                  tags: widget.data.tags,
                                  accent: accent,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Image thumbnail with zoom-on-hover and category pill overlay.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.url,
    required this.category,
    required this.categoryColor,
    required this.hovered,
  });

  final String url;
  final String category;
  final Color categoryColor;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        height: 180,
        color: AppColors.backgroundLight.withValues(alpha: 0.3),
        child: Center(
          child: Icon(
            Icons.article_outlined,
            size: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image with zoom
          ClipRect(
            child: AnimatedScale(
              scale: hovered ? 1.05 : 1.0,
              duration: AppDurations.medium,
              curve: CinematicCurves.hoverLift,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                // Lazy-load via frameBuilder: show placeholder first
                frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) return child;
                  return AnimatedSwitcher(
                    duration: AppDurations.medium,
                    child: Container(
                      color: AppColors.backgroundLight,
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.backgroundLight.withValues(alpha: 0.5),
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 32,
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Gradient scrim at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.backgroundLight.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),
          // Category pill
          if (category.isNotEmpty)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Author avatar, name, date, and read time row.
class _AuthorRow extends StatelessWidget {
  const _AuthorRow({
    required this.name,
    required this.avatarUrl,
    required this.date,
    required this.readTime,
    required this.accent,
  });

  final String name;
  final String avatarUrl;
  final String date;
  final String readTime;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        if (avatarUrl.isNotEmpty)
          ClipOval(
            child: Image.network(
              avatarUrl,
              width: 28,
              height: 28,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _DefaultAvatar(accent: accent),
            ),
          )
        else
          _DefaultAvatar(accent: accent),
        const SizedBox(width: 10),
        // Name + date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name.isNotEmpty)
                Text(
                  name,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBright,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      date,
                      style: AppTypography.caption.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (readTime.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '\u00B7',
                        style: AppTypography.caption,
                      ),
                    ),
                    Text(
                      readTime,
                      style: AppTypography.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fallback avatar circle with accent-colored icon.
class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: 0.15),
        ),
        child: Icon(
          Icons.person_rounded,
          size: 16,
          color: accent.withValues(alpha: 0.7),
        ),
      );
}

/// Horizontal tag pills at the bottom of the card.
class _TagRow extends StatelessWidget {
  const _TagRow({required this.tags, required this.accent});
  final List<String> tags;
  final Color accent;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        runSpacing: 4,
        children: tags
            .take(4)
            .map(
              (tag) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  tag,
                  style: AppTypography.caption.copyWith(
                    color: accent,
                    fontSize: 10,
                  ),
                ),
              ),
            )
            .toList(),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. BlogGrid — Responsive layout with featured post + grid
// ═══════════════════════════════════════════════════════════════════════════

/// Responsive blog layout with a featured (full-width) first post and a
/// 2-column (desktop) / 1-column (mobile) grid for the rest.
/// Includes staggered entrance and a "View All Posts" link.
class BlogGrid extends StatelessWidget {
  const BlogGrid({
    super.key,
    required this.posts,
    this.accentColor,
    this.authorName = '',
    this.authorAvatarUrl = '',
    this.viewAllUrl = '',
    this.viewAllLabel = 'View All Posts',
    this.onViewAll,
  });

  final List<MediumPost> posts;
  final Color? accentColor;
  final String authorName;
  final String authorAvatarUrl;
  final String viewAllUrl;
  final String viewAllLabel;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const SizedBox.shrink();

    final accent = accentColor ??
        Get.find<SceneDirector>().currentAccent.value;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= Breakpoints.tablet;

    final cardDataList = posts
        .map((p) => BlogCardData.fromMediumPost(
              p,
              authorName: authorName,
              authorAvatarUrl: authorAvatarUrl,
            ))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Featured post (first) ──
        if (cardDataList.isNotEmpty)
          _FeaturedCard(
            data: cardDataList.first,
            accent: accent,
            isDesktop: isDesktop,
          ),
        if (cardDataList.length > 1) ...[
          const SizedBox(height: 24),
          // ── Regular grid ──
          _RegularGrid(
            cards: cardDataList.sublist(1),
            accent: accent,
            isDesktop: isDesktop,
          ),
        ],
        // ── View All Posts ──
        if (viewAllUrl.isNotEmpty || onViewAll != null) ...[
          const SizedBox(height: 32),
          _ViewAllLink(
            label: viewAllLabel,
            url: viewAllUrl,
            accent: accent,
            onTap: onViewAll,
          ),
        ],
      ],
    );
  }
}

/// Featured post — full width, horizontal layout on desktop.
class _FeaturedCard extends StatefulWidget {
  const _FeaturedCard({
    required this.data,
    required this.accent,
    required this.isDesktop,
  });

  final BlogCardData data;
  final Color accent;
  final bool isDesktop;

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard>
    with SingleTickerProviderStateMixin {
  final _hovered = ValueNotifier<bool>(false);

  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.entrance,
    );
    final curved = CurvedAnimation(
      parent: _entranceCtrl,
      curve: CinematicCurves.dramaticEntrance,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(curved);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 24),
      end: Offset.zero,
    ).animate(curved);

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _hovered.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.data.url.isNotEmpty) {
      final uri = Uri.tryParse(widget.data.url);
      if (uri != null) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (_, child) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.translate(
          offset: _slideAnim.value,
          child: child,
        ),
      ),
      child: CinematicFocusable(
        onTap: _handleTap,
        onHoverChanged: (h) => _hovered.value = h,
        child: ValueListenableBuilder<bool>(
          valueListenable: _hovered,
          builder: (context, hovered, _) {
            return AnimatedContainer(
              duration: AppDurations.medium,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.backgroundLight.withValues(alpha: 0.6),
                border: Border.all(
                  color: (hovered ? widget.accent : Colors.white)
                      .withValues(alpha: hovered ? 0.2 : 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withValues(
                      alpha: hovered ? 0.12 : 0.04,
                    ),
                    blurRadius: hovered ? 28 : 10,
                    offset: Offset(0, hovered ? 10 : 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: widget.isDesktop
                    ? _buildHorizontal(hovered)
                    : _buildVertical(hovered),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHorizontal(bool hovered) {
    return SizedBox(
      height: 300,
      child: Row(
        children: [
          // Left: image
          Expanded(
            flex: 5,
            child: _featuredImage(hovered),
          ),
          // Right: content
          Expanded(
            flex: 5,
            child: _featuredContent(hovered),
          ),
        ],
      ),
    );
  }

  Widget _buildVertical(bool hovered) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          width: double.infinity,
          child: _featuredImage(hovered),
        ),
        _featuredContent(hovered),
      ],
    );
  }

  Widget _featuredImage(bool hovered) {
    if (widget.data.thumbnailUrl.isEmpty) {
      return Container(
        color: AppColors.backgroundLight.withValues(alpha: 0.3),
        child: Center(
          child: Icon(
            Icons.article_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: AnimatedScale(
            scale: hovered ? 1.05 : 1.0,
            duration: AppDurations.medium,
            curve: CinematicCurves.hoverLift,
            child: Image.network(
              widget.data.thumbnailUrl,
              fit: BoxFit.cover,
              frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) return child;
                return Container(
                  color: AppColors.backgroundLight,
                );
              },
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.backgroundLight.withValues(alpha: 0.5),
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 40,
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Featured badge
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: widget.accent.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'Featured',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _featuredContent(bool hovered) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.data.category.isNotEmpty) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.data.category,
                style: AppTypography.caption.copyWith(
                  color: widget.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          AnimatedDefaultTextStyle(
            duration: AppDurations.fast,
            style: AppTypography.h2.copyWith(
              color: hovered ? widget.accent : AppColors.textBright,
            ),
            child: Text(
              widget.data.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.data.excerpt,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(height: 1.6),
          ),
          const SizedBox(height: 16),
          _AuthorRow(
            name: widget.data.authorName,
            avatarUrl: widget.data.authorAvatarUrl,
            date: widget.data.date,
            readTime: widget.data.readTime,
            accent: widget.accent,
          ),
          if (widget.data.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            _TagRow(tags: widget.data.tags, accent: widget.accent),
          ],
        ],
      ),
    );
  }
}

/// Regular post grid: 2-column on desktop, 1-column on mobile.
class _RegularGrid extends StatelessWidget {
  const _RegularGrid({
    required this.cards,
    required this.accent,
    required this.isDesktop,
  });

  final List<BlogCardData> cards;
  final Color accent;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final columns = isDesktop ? 2 : 1;
    final rows = <Widget>[];

    for (var i = 0; i < cards.length; i += columns) {
      final rowChildren = <Widget>[];
      for (var j = i; j < i + columns && j < cards.length; j++) {
        rowChildren.add(
          Expanded(
            child: BlogCard(
              data: cards[j],
              accentColor: accent,
              entranceDelay: Duration(milliseconds: 120 * (j + 1)),
            ),
          ),
        );
      }
      // Pad row to fill columns
      while (rowChildren.length < columns) {
        rowChildren.add(const Expanded(child: SizedBox.shrink()));
      }
      rows.add(
        Padding(
          padding:
              EdgeInsets.only(bottom: i + columns < cards.length ? 20 : 0),
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

/// "View All Posts" link with arrow icon.
class _ViewAllLink extends StatelessWidget {
  const _ViewAllLink({
    required this.label,
    required this.url,
    required this.accent,
    this.onTap,
  });

  final String label;
  final String url;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CinematicFocusable(
        onTap: onTap ??
            () {
              if (url.isNotEmpty) {
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: accent.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 16, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. BlogCardSkeleton — Loading skeleton with shimmer
// ═══════════════════════════════════════════════════════════════════════════

/// Loading skeleton that matches [BlogCard] layout with a shimmer sweep.
/// Displays 3 skeleton cards in a responsive grid.
class BlogCardSkeleton extends StatelessWidget {
  const BlogCardSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final columns = screenWidth >= Breakpoints.tablet ? 2 : 1;

    final rows = <Widget>[];
    for (var i = 0; i < count; i += columns) {
      final rowChildren = <Widget>[];
      for (var j = i; j < i + columns && j < count; j++) {
        rowChildren.add(
          const Expanded(child: _SingleSkeleton()),
        );
      }
      while (rowChildren.length < columns) {
        rowChildren.add(const Expanded(child: SizedBox.shrink()));
      }
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + columns < count ? 20 : 0),
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

/// Single skeleton card matching BlogCard proportions.
class _SingleSkeleton extends StatefulWidget {
  const _SingleSkeleton();

  @override
  State<_SingleSkeleton> createState() => _SingleSkeletonState();
}

class _SingleSkeletonState extends State<_SingleSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.loadingPulse,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Widget _shimmerBox({
    required double height,
    double? width,
    double borderRadius = 6,
  }) {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, __) => Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment(-1.0 + 2.0 * _shimmerCtrl.value, 0),
            end: Alignment(1.0 + 2.0 * _shimmerCtrl.value, 0),
            colors: const [
              AppColors.backgroundLight,
              Color(0xFF1A1145),
              AppColors.backgroundLight,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.backgroundLight.withValues(alpha: 0.3),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail placeholder
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: _shimmerBox(height: 180),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title line 1
                _shimmerBox(height: 20, borderRadius: 4),
                const SizedBox(height: 8),
                // Title line 2 (shorter)
                _shimmerBox(height: 20, width: 200, borderRadius: 4),
                const SizedBox(height: 14),
                // Excerpt lines
                _shimmerBox(height: 14, borderRadius: 4),
                const SizedBox(height: 6),
                _shimmerBox(height: 14, borderRadius: 4),
                const SizedBox(height: 6),
                _shimmerBox(height: 14, width: 160, borderRadius: 4),
                const SizedBox(height: 18),
                // Author row
                Row(
                  children: [
                    _shimmerBox(height: 28, width: 28, borderRadius: 14),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _shimmerBox(height: 12, width: 100, borderRadius: 4),
                          const SizedBox(height: 4),
                          _shimmerBox(height: 10, width: 140, borderRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Tag pills
                Row(
                  children: [
                    _shimmerBox(height: 20, width: 60, borderRadius: 10),
                    const SizedBox(width: 8),
                    _shimmerBox(height: 20, width: 50, borderRadius: 10),
                    const SizedBox(width: 8),
                    _shimmerBox(height: 20, width: 70, borderRadius: 10),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. ReadingProgressBar — Scroll-based reading progress indicator
// ═══════════════════════════════════════════════════════════════════════════

/// Thin progress bar at the top of the page showing scroll progress.
/// Width represents 0-100% scroll position. Accent colored with glow.
///
/// Pass a [ScrollController] to track. Set [visible] to false to hide
/// when not reading a blog post.
class ReadingProgressBar extends StatefulWidget {
  const ReadingProgressBar({
    super.key,
    required this.scrollController,
    this.accentColor,
    this.height = 3.0,
    this.visible = true,
  });

  final ScrollController scrollController;
  final Color? accentColor;
  final double height;
  final bool visible;

  @override
  State<ReadingProgressBar> createState() => _ReadingProgressBarState();
}

class _ReadingProgressBarState extends State<ReadingProgressBar> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(ReadingProgressBar old) {
    super.didUpdateWidget(old);
    if (old.scrollController != widget.scrollController) {
      old.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final pos = widget.scrollController.position;
    if (pos.maxScrollExtent <= 0) {
      if (_progress != 0) setState(() => _progress = 0);
      return;
    }
    final newProgress =
        (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
    if ((newProgress - _progress).abs() > 0.002) {
      setState(() => _progress = newProgress);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    final accent = widget.accentColor ??
        Get.find<SceneDirector>().currentAccent.value;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _progress > 0.005 ? 1.0 : 0.0,
        duration: AppDurations.fast,
        child: SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth * _progress;
              return Stack(
                children: [
                  // Glow behind
                  AnimatedContainer(
                    duration: AppDurations.microFast,
                    width: barWidth,
                    height: widget.height,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  // Bar
                  AnimatedContainer(
                    duration: AppDurations.microFast,
                    width: barWidth,
                    height: widget.height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.8),
                          accent,
                        ],
                      ),
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. BlogFilters — Horizontal category filter pills
// ═══════════════════════════════════════════════════════════════════════════

/// Category filter data.
class BlogCategory {
  const BlogCategory({
    required this.label,
    this.count = 0,
  });

  final String label;
  final int count;
}

/// Horizontal scrollable category filter with animated active state,
/// count badges, and smooth transitions.
class BlogFilters extends StatefulWidget {
  const BlogFilters({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    this.accentColor,
  });

  final List<BlogCategory> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final Color? accentColor;

  @override
  State<BlogFilters> createState() => _BlogFiltersState();
}

class _BlogFiltersState extends State<BlogFilters> {
  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ??
        Get.find<SceneDirector>().currentAccent.value;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = widget.categories[index];
          final isSelected = cat.label == widget.selectedCategory;

          return _FilterPill(
            label: cat.label,
            count: cat.count,
            isSelected: isSelected,
            accent: accent,
            onTap: () => widget.onCategoryChanged(cat.label),
          );
        },
      ),
    );
  }
}

/// Individual filter pill with animated fill.
class _FilterPill extends StatefulWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.medium,
          curve: CinematicCurves.hoverLift,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accent
                : _hovered
                    ? widget.accent.withValues(alpha: 0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? widget.accent
                  : widget.accent.withValues(alpha: _hovered ? 0.3 : 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: AppDurations.medium,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: widget.isSelected
                      ? Colors.white
                      : _hovered
                          ? widget.accent
                          : AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
                child: Text(widget.label),
              ),
              if (widget.count > 0) ...[
                const SizedBox(width: 6),
                AnimatedContainer(
                  duration: AppDurations.medium,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : widget.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: widget.isSelected
                          ? Colors.white
                          : widget.accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper to build [BlogCategory] list from a set of posts, counting
/// how many posts belong to each category.
List<BlogCategory> buildCategoriesFromPosts(
  List<MediumPost> posts, {
  String allLabel = 'All',
}) {
  final counts = <String, int>{};
  for (final post in posts) {
    for (final cat in post.categories) {
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return [
    BlogCategory(label: allLabel, count: posts.length),
    ...sorted.map((e) => BlogCategory(label: e.key, count: e.value)),
  ];
}

/// Filters a list of posts by category. Returns all posts if
/// [category] equals [allLabel].
List<MediumPost> filterPostsByCategory(
  List<MediumPost> posts,
  String category, {
  String allLabel = 'All',
}) {
  if (category == allLabel || category.isEmpty) return posts;
  return posts.where((p) => p.categories.contains(category)).toList();
}
