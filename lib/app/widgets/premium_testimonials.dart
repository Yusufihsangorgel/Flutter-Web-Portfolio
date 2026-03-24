import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Data model
// ═══════════════════════════════════════════════════════════════════════════

/// Testimonial data consumed by all premium testimonial widgets.
class TestimonialData {
  const TestimonialData({
    required this.quote,
    required this.authorName,
    required this.authorRole,
    this.company = '',
    this.photoUrl,
    this.rating = 5,
  });

  final String quote;
  final String authorName;
  final String authorRole;
  final String company;

  /// Network or asset URL for the circular author photo.
  final String? photoUrl;

  /// Star rating from 1 to 5.
  final int rating;

  /// Convenience factory from a JSON map (compatible with existing cv data).
  factory TestimonialData.fromMap(Map<String, dynamic> map) {
    return TestimonialData(
      quote: map['quote'] as String? ?? '',
      authorName: map['name'] as String? ?? map['authorName'] as String? ?? '',
      authorRole:
          map['position'] as String? ?? map['authorRole'] as String? ?? '',
      company: map['company'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? map['photo'] as String?,
      rating: (map['rating'] as num?)?.toInt() ?? 5,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 1. TestimonialCard3D — Premium glassmorphism card with 3D tilt
// ═══════════════════════════════════════════════════════════════════════════

/// A premium testimonial card featuring:
/// - Glassmorphism (frosted blur) background
/// - Large opening quote mark with neon glow
/// - Elegant serif testimonial text
/// - Author photo, name, role, company
/// - Animated star rating
/// - 3D tilt with glare on hover
/// - Staggered fade+slide entrance animation
class TestimonialCard3D extends StatefulWidget {
  const TestimonialCard3D({
    super.key,
    required this.data,
    this.accentColor,
    this.entranceDelay = Duration.zero,
    this.backgroundTint,
    this.maxTiltDegrees = 12.0,
    this.glareOpacity = 0.10,
    this.borderRadius = 20.0,
  });

  final TestimonialData data;
  final Color? accentColor;
  final Duration entranceDelay;

  /// Optional background tint applied over the glass surface.
  final Color? backgroundTint;
  final double maxTiltDegrees;
  final double glareOpacity;
  final double borderRadius;

  @override
  State<TestimonialCard3D> createState() => _TestimonialCard3DState();
}

class _TestimonialCard3DState extends State<TestimonialCard3D>
    with TickerProviderStateMixin {
  // ── 3D tilt state ──
  double _normalX = 0;
  double _normalY = 0;
  double _tiltX = 0;
  double _tiltY = 0;
  double _hover = 0;

  late final AnimationController _hoverController;
  late final Animation<double> _hoverCurve;

  // ── Entrance animation ──
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  // ── Star rating ──
  late final AnimationController _starController;

  @override
  void initState() {
    super.initState();

    // Hover / tilt spring.
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(_interpolateTilt);

    _hoverCurve = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Entrance.
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 40),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    // Star rating fill.
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Trigger entrance after delay.
    Future.delayed(widget.entranceDelay, () {
      if (mounted) {
        _entranceController.forward();
        _starController.forward();
      }
    });
  }

  void _interpolateTilt() {
    setState(() {
      final t = _hoverCurve.value;
      final maxRad = widget.maxTiltDegrees * (math.pi / 180);
      _tiltX = -_normalY * maxRad * t;
      _tiltY = _normalX * maxRad * t;
      _hover = t;
    });
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _entranceController.dispose();
    _starController.dispose();
    super.dispose();
  }

  void _onEnter(PointerEnterEvent e) {
    if (e.kind == PointerDeviceKind.touch) return;
    _hoverController.forward();
  }

  void _onHover(PointerHoverEvent e) {
    if (e.kind == PointerDeviceKind.touch) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || box.size.isEmpty) return;
    _normalX = (e.localPosition.dx / box.size.width - 0.5) * 2;
    _normalY = (e.localPosition.dy / box.size.height - 0.5) * 2;
  }

  void _onExit(PointerExitEvent e) {
    _normalX = 0;
    _normalY = 0;
    _hoverController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.heroAccent;
    final tint = widget.backgroundTint ?? Colors.white.withValues(alpha: 0.03);

    // 3D transform.
    final scale = 1.0 + _hover * 0.03;
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(_tiltX)
      ..rotateY(_tiltY)
      ..scaleByDouble(scale, scale, scale, 1.0);

    final shadowOffsetX = -_tiltY * 24;
    final shadowOffsetY = _tiltX * 24;
    final shadowBlur = 12.0 + _hover * 20.0;

    final glareAlignment = Alignment(_normalX * _hover, _normalY * _hover);

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Opacity(
          opacity: _entranceFade.value,
          child: Transform.translate(
            offset: _entranceSlide.value,
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: _onEnter,
        onHover: _onHover,
        onExit: _onExit,
        child: Transform(
          transform: transform,
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12 + _hover * 0.15),
                  blurRadius: shadowBlur,
                  offset: Offset(shadowOffsetX, shadowOffsetY),
                ),
                // Accent glow on hover.
                if (_hover > 0.01)
                  BoxShadow(
                    color: accent.withValues(alpha: 0.08 * _hover),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08 + _hover * 0.06),
                      width: 1,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.06),
                        Colors.white.withValues(alpha: 0.02),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Card content.
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Large opening quote with neon glow.
                          _NeonQuoteMark(accent: accent),
                          const SizedBox(height: 16),
                          // Testimonial text (serif).
                          Text(
                            widget.data.quote,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              height: 1.7,
                              color: AppColors.textBright.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Star rating.
                          _AnimatedStarRating(
                            rating: widget.data.rating,
                            animation: _starController,
                            color: accent,
                          ),
                          const SizedBox(height: 20),
                          // Divider.
                          Container(
                            width: 40,
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accent.withValues(alpha: 0.6),
                                  accent.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Author info row.
                          _AuthorRow(data: widget.data, accent: accent),
                        ],
                      ),
                      // Glare overlay.
                      if (_hover > 0.01)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(widget.borderRadius),
                                gradient: RadialGradient(
                                  center: glareAlignment,
                                  radius: 0.85,
                                  colors: [
                                    Colors.white.withValues(
                                        alpha: widget.glareOpacity * _hover),
                                    Colors.white.withValues(
                                        alpha:
                                            widget.glareOpacity * 0.3 * _hover),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.45, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Neon quote mark ──────────────────────────────────────────────────────

class _NeonQuoteMark extends StatelessWidget {
  const _NeonQuoteMark({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Text(
      '\u201C',
      style: GoogleFonts.playfairDisplay(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        height: 0.8,
        color: accent,
        shadows: [
          Shadow(color: accent.withValues(alpha: 0.6), blurRadius: 12),
          Shadow(color: accent.withValues(alpha: 0.3), blurRadius: 28),
        ],
      ),
    );
  }
}

// ── Animated star rating ─────────────────────────────────────────────────

class _AnimatedStarRating extends StatelessWidget {
  const _AnimatedStarRating({
    required this.rating,
    required this.animation,
    required this.color,
  });

  final int rating;
  final AnimationController animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            // Each star fills sequentially during the animation.
            final starStart = i / 5;
            final starEnd = (i + 1) / 5;
            final starProgress =
                ((animation.value - starStart) / (starEnd - starStart))
                    .clamp(0.0, 1.0);
            final filled = i < rating;

            return Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Transform.scale(
                scale: filled ? 0.7 + starProgress * 0.3 : 0.7,
                child: Icon(
                  filled && starProgress >= 1.0
                      ? Icons.star_rounded
                      : filled
                          ? Icons.star_half_rounded
                          : Icons.star_outline_rounded,
                  size: 18,
                  color: filled
                      ? Color.lerp(
                          color.withValues(alpha: 0.3), color, starProgress)
                      : AppColors.textSecondary.withValues(alpha: 0.3),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Author row ───────────────────────────────────────────────────────────

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.data, required this.accent});
  final TestimonialData data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Circular photo.
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: accent.withValues(alpha: 0.4),
              width: 2,
            ),
            image: data.photoUrl != null
                ? DecorationImage(
                    image: NetworkImage(data.photoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
            gradient: data.photoUrl == null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.3),
                      accent.withValues(alpha: 0.1),
                    ],
                  )
                : null,
          ),
          child: data.photoUrl == null
              ? Center(
                  child: Text(
                    data.authorName.isNotEmpty
                        ? data.authorName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.authorName,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBright,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.company.isNotEmpty
                    ? '${data.authorRole}, ${data.company}'
                    : data.authorRole,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: accent.withValues(alpha: 0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. TestimonialCarousel — Auto-rotating, responsive carousel
// ═══════════════════════════════════════════════════════════════════════════

/// A responsive testimonial carousel that shows 1/2/3 cards based on
/// screen width, auto-advances every [autoAdvanceInterval], supports drag
/// navigation, and wraps around infinitely.
class TestimonialCarousel extends StatefulWidget {
  const TestimonialCarousel({
    super.key,
    required this.testimonials,
    this.accentColor,
    this.autoAdvanceInterval = const Duration(seconds: 5),
    this.transitionDuration = const Duration(milliseconds: 600),
    this.transitionCurve = Curves.easeInOutCubic,
    this.height = 340,
  });

  final List<TestimonialData> testimonials;
  final Color? accentColor;
  final Duration autoAdvanceInterval;
  final Duration transitionDuration;
  final Curve transitionCurve;
  final double height;

  @override
  State<TestimonialCarousel> createState() => _TestimonialCarouselState();
}

class _TestimonialCarouselState extends State<TestimonialCarousel>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  Timer? _autoTimer;
  int _currentPage = 0;
  bool _isHovered = false;
  bool _arrowsVisible = false;

  /// Large multiplier for infinite loop simulation via PageView.
  static const _virtualMultiplier = 1000;

  int get _itemCount => widget.testimonials.length;
  int get _virtualStart => _virtualMultiplier ~/ 2 * _itemCount;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _virtualStart,
      viewportFraction: 1.0,
    );
    _startAutoAdvance();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoAdvance() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(widget.autoAdvanceInterval, (_) {
      if (!mounted || _isHovered) return;
      _goToPage(_currentPage + 1);
    });
  }

  void _goToPage(int page) {
    final virtualPage = _pageController.page?.round() ?? _virtualStart;
    final diff = page - _currentPage;
    _pageController.animateToPage(
      virtualPage + diff,
      duration: widget.transitionDuration,
      curve: widget.transitionCurve,
    );
  }

  void _onPageChanged(int virtualPage) {
    setState(() {
      _currentPage = virtualPage % _itemCount;
    });
  }

  int _cardsPerView(double width) {
    if (width >= Breakpoints.desktop) return 3;
    if (width >= Breakpoints.tablet) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    if (_itemCount == 0) return const SizedBox.shrink();

    final accent = widget.accentColor ?? AppColors.heroAccent;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardsPerView = _cardsPerView(screenWidth);

    return MouseRegion(
      onEnter: (_) {
        _isHovered = true;
        setState(() => _arrowsVisible = true);
      },
      onExit: (_) {
        _isHovered = false;
        setState(() => _arrowsVisible = false);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Carousel body.
          SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                // Card pages.
                NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification &&
                        notification.dragDetails != null) {
                      // Manual drag — reset auto-advance.
                      _autoTimer?.cancel();
                      Future.delayed(const Duration(seconds: 3), () {
                        if (mounted) _startAutoAdvance();
                      });
                    }
                    return false;
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _virtualMultiplier * _itemCount,
                    itemBuilder: (context, virtualIndex) {
                      // Build a row of [cardsPerView] cards for this page.
                      final baseIndex = virtualIndex % _itemCount;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: List.generate(cardsPerView, (offset) {
                            final dataIndex =
                                (baseIndex + offset) % _itemCount;
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: TestimonialCard3D(
                                  data: widget.testimonials[dataIndex],
                                  accentColor: accent,
                                  entranceDelay:
                                      Duration(milliseconds: offset * 120),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    },
                  ),
                ),
                // Previous arrow.
                if (_arrowsVisible)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _ArrowButton(
                        icon: Icons.chevron_left_rounded,
                        accent: accent,
                        onTap: () => _goToPage(_currentPage - 1),
                      ),
                    ),
                  ),
                // Next arrow.
                if (_arrowsVisible)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _ArrowButton(
                        icon: Icons.chevron_right_rounded,
                        accent: accent,
                        onTap: () => _goToPage(_currentPage + 1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Dot indicators.
          _DotIndicators(
            count: _itemCount,
            currentIndex: _currentPage,
            accent: accent,
            onTap: _goToPage,
          ),
        ],
      ),
    );
  }
}

// ── Arrow button ─────────────────────────────────────────────────────────

class _ArrowButton extends StatefulWidget {
  const _ArrowButton({
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hovered
                ? widget.accent.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.3),
            border: Border.all(
              color: widget.accent.withValues(alpha: _hovered ? 0.5 : 0.15),
            ),
          ),
          child: Icon(
            widget.icon,
            color: _hovered
                ? widget.accent
                : AppColors.textPrimary.withValues(alpha: 0.6),
            size: 24,
          ),
        ),
      ),
    );
  }
}

// ── Dot indicators ───────────────────────────────────────────────────────

class _DotIndicators extends StatelessWidget {
  const _DotIndicators({
    required this.count,
    required this.currentIndex,
    required this.accent,
    required this.onTap,
  });

  final int count;
  final int currentIndex;
  final Color accent;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == currentIndex;
        return GestureDetector(
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: isActive ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive
                  ? accent
                  : AppColors.textSecondary.withValues(alpha: 0.25),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. TestimonialMasonry — Pinterest-style staggered grid
// ═══════════════════════════════════════════════════════════════════════════

/// A Pinterest-style masonry layout for testimonials with:
/// - Variable height cards based on content
/// - Staggered entrance animation (waterfall effect)
/// - Responsive columns (1 / 2 / 3 based on width)
/// - Each card has a different subtle background tint
/// - Hover: card lifts with shadow increase
class TestimonialMasonry extends StatelessWidget {
  const TestimonialMasonry({
    super.key,
    required this.testimonials,
    this.accentColor,
    this.spacing = 20,
  });

  final List<TestimonialData> testimonials;
  final Color? accentColor;
  final double spacing;

  static const _tints = [
    Color(0x08FF6B6B),
    Color(0x0806B6D4),
    Color(0x08A855F7),
    Color(0x0810B981),
    Color(0x08F59E0B),
    Color(0x08EC4899),
  ];

  int _columnCount(double width) {
    if (width >= Breakpoints.desktop) return 3;
    if (width >= Breakpoints.tablet) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    if (testimonials.isEmpty) return const SizedBox.shrink();

    final accent = accentColor ?? AppColors.heroAccent;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final columns = _columnCount(screenWidth);

    // Distribute items across columns (shortest-column-first approach).
    final columnItems = List.generate(columns, (_) => <int>[]);
    // Simple round-robin for deterministic layout.
    for (var i = 0; i < testimonials.length; i++) {
      columnItems[i % columns].add(i);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(columns, (col) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: col == 0 ? 0 : spacing / 2,
              right: col == columns - 1 ? 0 : spacing / 2,
            ),
            child: Column(
              children: columnItems[col].map((index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: spacing),
                  child: _MasonryCard(
                    data: testimonials[index],
                    accent: accent,
                    tint: _tints[index % _tints.length],
                    entranceDelay: Duration(milliseconds: index * 100),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }),
    );
  }
}

// ── Masonry card with hover lift ─────────────────────────────────────────

class _MasonryCard extends StatefulWidget {
  const _MasonryCard({
    required this.data,
    required this.accent,
    required this.tint,
    required this.entranceDelay,
  });

  final TestimonialData data;
  final Color accent;
  final Color tint;
  final Duration entranceDelay;

  @override
  State<_MasonryCard> createState() => _MasonryCardState();
}

class _MasonryCardState extends State<_MasonryCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;

  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 30),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
    ));

    Future.delayed(widget.entranceDelay, () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Opacity(
          opacity: _entranceFade.value,
          child: Transform.translate(
            offset: _entranceSlide.value,
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translateByDouble(0.0, _hovered ? -6.0 : 0.0, 0.0, 0.0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.tint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: _hovered ? 0.10 : 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: _hovered ? 0.25 : 0.10),
                blurRadius: _hovered ? 24 : 8,
                offset: Offset(0, _hovered ? 12 : 4),
              ),
              if (_hovered)
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.06),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quote icon.
              Icon(
                Icons.format_quote_rounded,
                color: widget.accent.withValues(alpha: 0.4),
                size: 28,
              ),
              const SizedBox(height: 12),
              // Full quote text (variable height).
              Text(
                widget.data.quote,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  height: 1.7,
                  color: AppColors.textBright.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 32,
                height: 1,
                color: widget.accent.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12),
              _AuthorRow(data: widget.data, accent: widget.accent),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. TestimonialMarquee — Continuous scrolling social proof
// ═══════════════════════════════════════════════════════════════════════════

/// Two rows of testimonial cards scrolling in opposite directions to create
/// an ambient social proof element.
///
/// Features:
/// - Infinite seamless loop
/// - Pauses on hover over individual cards
/// - Cards tilt slightly on hover
/// - Gradient fade on edges to mask the loop seam
class TestimonialMarquee extends StatelessWidget {
  const TestimonialMarquee({
    super.key,
    required this.testimonials,
    this.accentColor,
    this.scrollSpeed = 30.0,
    this.rowHeight = 200,
    this.rowSpacing = 16,
    this.cardWidth = 340,
  });

  final List<TestimonialData> testimonials;
  final Color? accentColor;

  /// Pixels per second scroll speed.
  final double scrollSpeed;
  final double rowHeight;
  final double rowSpacing;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    if (testimonials.isEmpty) return const SizedBox.shrink();

    final accent = accentColor ?? AppColors.heroAccent;

    // Split testimonials into two rows.
    final half = (testimonials.length / 2).ceil();
    final row1 = testimonials.sublist(0, half);
    final row2 = testimonials.sublist(half);

    return ClipRect(
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: rowHeight,
                child: _MarqueeRow(
                  testimonials: row1,
                  accent: accent,
                  scrollSpeed: scrollSpeed,
                  cardWidth: cardWidth,
                  reverse: false,
                ),
              ),
              SizedBox(height: rowSpacing),
              SizedBox(
                height: rowHeight,
                child: _MarqueeRow(
                  testimonials: row2.isNotEmpty ? row2 : row1,
                  accent: accent,
                  scrollSpeed: scrollSpeed,
                  cardWidth: cardWidth,
                  reverse: true,
                ),
              ),
            ],
          ),
          // Left fade gradient.
          Positioned.fill(
            child: IgnorePointer(
              child: Row(
                children: [
                  Container(
                    width: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.background,
                          AppColors.background.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.background.withValues(alpha: 0.0),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single marquee row ───────────────────────────────────────────────────

class _MarqueeRow extends StatefulWidget {
  const _MarqueeRow({
    required this.testimonials,
    required this.accent,
    required this.scrollSpeed,
    required this.cardWidth,
    required this.reverse,
  });

  final List<TestimonialData> testimonials;
  final Color accent;
  final double scrollSpeed;
  final double cardWidth;
  final bool reverse;

  @override
  State<_MarqueeRow> createState() => _MarqueeRowState();
}

class _MarqueeRowState extends State<_MarqueeRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _offset = 0;
  bool _isPaused = false;

  double get _totalWidth =>
      widget.testimonials.length * (widget.cardWidth + 16);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Tick-driven, not duration-driven.
    )..addListener(_tick);
    _controller.repeat();
  }

  DateTime _lastTick = DateTime.now();

  void _tick() {
    final now = DateTime.now();
    final dt = now.difference(_lastTick).inMicroseconds / 1000000.0;
    _lastTick = now;

    if (_isPaused || _totalWidth <= 0) return;

    setState(() {
      final direction = widget.reverse ? -1.0 : 1.0;
      _offset += widget.scrollSpeed * dt * direction;

      // Wrap around.
      if (_offset.abs() >= _totalWidth) {
        _offset = _offset % _totalWidth;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.testimonials;
    if (items.isEmpty) return const SizedBox.shrink();

    // Build enough copies to fill the screen + overflow.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final copies = (screenWidth / _totalWidth).ceil() + 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var copy = 0; copy < copies; copy++)
              for (var i = 0; i < items.length; i++)
                Positioned(
                  left: -_offset +
                      copy * _totalWidth +
                      i * (widget.cardWidth + 16),
                  top: 0,
                  bottom: 0,
                  width: widget.cardWidth,
                  child: _MarqueeCard(
                    data: items[i],
                    accent: widget.accent,
                    onHoverChanged: (hovered) {
                      _isPaused = hovered;
                    },
                  ),
                ),
          ],
        );
      },
    );
  }
}

// ── Marquee card with tilt on hover ──────────────────────────────────────

class _MarqueeCard extends StatefulWidget {
  const _MarqueeCard({
    required this.data,
    required this.accent,
    required this.onHoverChanged,
  });

  final TestimonialData data;
  final Color accent;
  final ValueChanged<bool> onHoverChanged;

  @override
  State<_MarqueeCard> createState() => _MarqueeCardState();
}

class _MarqueeCardState extends State<_MarqueeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        widget.onHoverChanged(true);
      },
      onExit: (_) {
        setState(() => _hovered = false);
        widget.onHoverChanged(false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateZ(_hovered ? -0.02 : 0.0)
          ..scaleByDouble(_hovered ? 1.04 : 1.0, _hovered ? 1.04 : 1.0, _hovered ? 1.04 : 1.0, 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: _hovered ? 0.10 : 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: _hovered ? 0.20 : 0.08),
              blurRadius: _hovered ? 16 : 6,
              offset: Offset(0, _hovered ? 8 : 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quote.
            Expanded(
              child: Text(
                widget.data.quote,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                  color: AppColors.textBright.withValues(alpha: 0.8),
                ),
                overflow: TextOverflow.fade,
              ),
            ),
            const SizedBox(height: 12),
            // Author.
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.accent.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    gradient: LinearGradient(
                      colors: [
                        widget.accent.withValues(alpha: 0.25),
                        widget.accent.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.data.authorName.isNotEmpty
                          ? widget.data.authorName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.data.authorName,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textBright,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.data.company.isNotEmpty
                            ? '${widget.data.authorRole}, ${widget.data.company}'
                            : widget.data.authorRole,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: widget.accent.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
