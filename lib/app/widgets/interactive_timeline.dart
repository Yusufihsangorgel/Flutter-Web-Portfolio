import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

/// Data for a single timeline entry.
class TimelineEntryData {
  const TimelineEntryData({
    required this.company,
    required this.role,
    required this.startDate,
    required this.endDate,
    required this.description,
    this.techTags = const [],
    this.logoIcon,
  });

  /// Convenience factory from a CV-data map (matches existing data shape).
  factory TimelineEntryData.fromMap(Map<String, dynamic> map) {
    final techList = (map['technologies'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    return TimelineEntryData(
      company: (map['company'] as String?) ?? '',
      role: (map['position'] as String?) ?? '',
      startDate: (map['start_date'] as String?) ?? '',
      endDate: (map['end_date'] as String?) ?? 'Present',
      description: (map['description'] as String?) ?? '',
      techTags: techList,
    );
  }

  final String company;
  final String role;
  final String startDate;
  final String endDate;
  final String description;
  final List<String> techTags;
  final IconData? logoIcon;
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. InteractiveTimeline — Main widget
// ─────────────────────────────────────────────────────────────────────────────

/// A scroll-driven vertical timeline with staggered, animated entries.
///
/// Desktop: center-aligned line with entries alternating left/right.
/// Mobile:  left-aligned line with entries stacked on the right.
class InteractiveTimeline extends StatefulWidget {
  const InteractiveTimeline({
    super.key,
    required this.entries,
    required this.accent,
  });

  final List<TimelineEntryData> entries;
  final Color accent;

  @override
  State<InteractiveTimeline> createState() => _InteractiveTimelineState();
}

class _InteractiveTimelineState extends State<InteractiveTimeline>
    with TickerProviderStateMixin {
  /// Keys for each entry so we can measure their positions.
  late List<GlobalKey> _entryKeys;

  /// Scroll-driven fill progress [0..1].
  double _scrollFill = 0.0;

  /// Which entry index is currently "active" (nearest to screen center).
  int _activeIndex = 0;

  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _entryKeys =
        List.generate(widget.entries.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void didUpdateWidget(covariant InteractiveTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entries.length != oldWidget.entries.length) {
      _entryKeys =
          List.generate(widget.entries.length, (_) => GlobalKey());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_onScroll);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final selfTop = renderBox.localToGlobal(Offset.zero).dy;
    final selfHeight = renderBox.size.height;
    final screenH = MediaQuery.sizeOf(context).height;

    // Fill: how much of the timeline has scrolled past the center of screen
    final centerY = screenH * 0.55;
    final progress = ((centerY - selfTop) / selfHeight).clamp(0.0, 1.0);

    // Active index: find entry nearest screen center
    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < _entryKeys.length; i++) {
      final box =
          _entryKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final entryCenter =
          box.localToGlobal(Offset.zero).dy + box.size.height / 2;
      final dist = (entryCenter - centerY).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }

    if (progress != _scrollFill || best != _activeIndex) {
      setState(() {
        _scrollFill = progress;
        _activeIndex = best;
      });
    }
  }

  void _scrollToEntry(int index) {
    final box =
        _entryKeys[index].currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || _scrollPosition == null) return;
    final entryTop = box.localToGlobal(Offset.zero).dy;
    final screenH = MediaQuery.sizeOf(context).height;
    final target =
        _scrollPosition!.pixels + entryTop - screenH * 0.35;
    _scrollPosition!.animateTo(
      target.clamp(
          _scrollPosition!.minScrollExtent, _scrollPosition!.maxScrollExtent),
      duration: AppDurations.sectionScroll,
      curve: CinematicCurves.easeInOutCinematic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= Breakpoints.tablet;
    final entryCount = widget.entries.length;

    return Stack(
      children: [
        // The vertical connector line behind everything
        Positioned.fill(
          child: TimelineConnector(
            accent: widget.accent,
            fillProgress: _scrollFill,
            isDesktop: isDesktop,
          ),
        ),
        // The entries
        Column(
          children: [
            for (int i = 0; i < entryCount; i++)
              _buildRow(i, isDesktop),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(int index, bool isDesktop) {
    final isLeft = isDesktop && index.isEven;
    final entryProgress = widget.entries.length <= 1
        ? 1.0
        : index / (widget.entries.length - 1);
    final isPassed = entryProgress <= _scrollFill;
    final isActive = index == _activeIndex;

    final node = TimelineNode(
      accent: widget.accent,
      isPassed: isPassed,
      isActive: isActive,
      year: widget.entries[index].startDate,
      onTap: () => _scrollToEntry(index),
    );

    final card = Expanded(
      child: _StaggeredEntrance(
        index: index,
        slideFromLeft: isDesktop ? isLeft : false,
        child: TimelineEntryCard(
          key: _entryKeys[index],
          data: widget.entries[index],
          accent: widget.accent,
          isActive: isActive,
        ),
      ),
    );

    if (!isDesktop) {
      // Mobile: node on the left, card on the right
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 4),
            node,
            const SizedBox(width: 16),
            card,
          ],
        ),
      );
    }

    // Desktop: alternate left/right
    const spacer = Expanded(child: SizedBox.shrink());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isLeft
            ? [card, const SizedBox(width: 20), node, const SizedBox(width: 20), spacer]
            : [spacer, const SizedBox(width: 20), node, const SizedBox(width: 20), card],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. TimelineEntryCard — Individual entry card
// ─────────────────────────────────────────────────────────────────────────────

class TimelineEntryCard extends StatefulWidget {
  const TimelineEntryCard({
    super.key,
    required this.data,
    required this.accent,
    this.isActive = false,
  });

  final TimelineEntryData data;
  final Color accent;
  final bool isActive;

  @override
  State<TimelineEntryCard> createState() => _TimelineEntryCardState();
}

class _TimelineEntryCardState extends State<TimelineEntryCard> {
  bool _hovered = false;
  bool _expanded = false;

  // Mouse position relative to card center, normalized [-1,1]
  Offset _mouseNorm = Offset.zero;

  static const _maxTilt = 0.035; // ~2° in radians ≈ subtle 3D tilt

  /// Build a combined perspective + tilt + lift transform matrix.
  Matrix4 _buildCardTransform(double tiltX, double tiltY, double liftY) =>
      Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(tiltX)
        ..rotateY(tiltY)
        ..setTranslationRaw(0, liftY, 0);

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;

    // 3D tilt transform
    final tiltX = _hovered ? _mouseNorm.dy * _maxTilt : 0.0;
    final tiltY = _hovered ? -_mouseNorm.dx * _maxTilt : 0.0;

    final borderGlow = widget.isActive
        ? [
            BoxShadow(
              color: accent.withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: -2,
            ),
          ]
        : <BoxShadow>[];

    final hoverShadow = _hovered
        ? [
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ]
        : <BoxShadow>[];

    // Build description lines
    final bullets = widget.data.description
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final hasLongDescription = bullets.length > 2;
    final visibleBullets =
        _expanded || !hasLongDescription ? bullets : bullets.take(2).toList();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onHover: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        setState(() {
          _mouseNorm = Offset(
            (e.localPosition.dx / box.size.width) * 2 - 1,
            (e.localPosition.dy / box.size.height) * 2 - 1,
          );
        });
      },
      onExit: (_) => setState(() {
        _hovered = false;
        _mouseNorm = Offset.zero;
      }),
      child: AnimatedContainer(
        duration: AppDurations.medium,
        curve: CinematicCurves.hoverLift,
        transform: _buildCardTransform(tiltX, tiltY, _hovered ? -4.0 : 0.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.isActive
                ? accent.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.06),
            width: widget.isActive ? 1.5 : 1,
          ),
          boxShadow: [...borderGlow, ...hoverShadow],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Company logo placeholder + company name row
            Row(
              children: [
                // Logo placeholder
                AnimatedContainer(
                  duration: AppDurations.fast,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    widget.data.logoIcon ?? Icons.business_rounded,
                    size: 18,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.data.role,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textBright,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@ ${widget.data.company}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: accent,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Date range
            Text(
              '${widget.data.startDate} — ${widget.data.endDate}',
              style: AppTypography.mono.copyWith(
                letterSpacing: 0.8,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            // Description bullets
            AnimatedSize(
              duration: AppDurations.normal,
              curve: CinematicCurves.revealDecel,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final bullet in visibleBullets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '▸ ',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              color: accent,
                              height: 1.5,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              bullet.trim(),
                              style: AppTypography.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // "Show more" toggle
            if (hasLongDescription)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _expanded ? 'Show less' : 'Show more',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0.0,
                          duration: AppDurations.fast,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Tech tags
            if (widget.data.techTags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: widget.data.techTags
                    .map((tag) => _TechTagPill(tag: tag, accent: accent))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small pill for a technology tag with hover tooltip.
class _TechTagPill extends StatefulWidget {
  const _TechTagPill({required this.tag, required this.accent});

  final String tag;
  final Color accent;

  @override
  State<_TechTagPill> createState() => _TechTagPillState();
}

class _TechTagPillState extends State<_TechTagPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => Tooltip(
      message: widget.tag,
      preferBelow: false,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: CinematicCurves.hoverLift,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.accent.withValues(alpha: 0.15)
                : widget.accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered
                  ? widget.accent.withValues(alpha: 0.4)
                  : widget.accent.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            widget.tag,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: _hovered
                  ? widget.accent
                  : widget.accent.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. TimelineNode — Circle on the timeline
// ─────────────────────────────────────────────────────────────────────────────

class TimelineNode extends StatefulWidget {
  const TimelineNode({
    super.key,
    required this.accent,
    required this.isPassed,
    required this.isActive,
    required this.year,
    this.onTap,
  });

  final Color accent;
  final bool isPassed;
  final bool isActive;
  final String year;
  final VoidCallback? onTap;

  @override
  State<TimelineNode> createState() => _TimelineNodeState();
}

class _TimelineNodeState extends State<TimelineNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    if (widget.isActive) _pulseCtrl.repeat();
  }

  @override
  void didUpdateWidget(covariant TimelineNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat();
    } else if (!widget.isActive && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final size = widget.isActive ? 14.0 : 10.0;

    return Tooltip(
      message: widget.year,
      preferBelow: false,
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) {
                  return CustomPaint(
                    painter: _NodePainter(
                      accent: accent,
                      isPassed: widget.isPassed,
                      isActive: widget.isActive,
                      pulseValue: widget.isActive ? _pulseAnim.value : 0.0,
                      nodeSize: size,
                    ),
                    size: const Size(32, 32),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NodePainter extends CustomPainter {
  _NodePainter({
    required this.accent,
    required this.isPassed,
    required this.isActive,
    required this.pulseValue,
    required this.nodeSize,
  });

  final Color accent;
  final bool isPassed;
  final bool isActive;
  final double pulseValue;
  final double nodeSize;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = nodeSize / 2;

    // Pulse ring (active only)
    if (isActive && pulseValue > 0) {
      final pulseRadius = radius + 10 * pulseValue;
      final pulseOpacity = (1.0 - pulseValue) * 0.4;
      canvas.drawCircle(
        center,
        pulseRadius,
        Paint()
          ..color = accent.withValues(alpha: pulseOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // Outer glow for active/passed
    if (isPassed || isActive) {
      canvas.drawCircle(
        center,
        radius + 3,
        Paint()
          ..color = accent.withValues(alpha: isActive ? 0.2 : 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Main circle
    if (isPassed || isActive) {
      // Filled
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = accent,
      );
      // Inner bright dot
      canvas.drawCircle(
        center,
        radius * 0.35,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
    } else {
      // Future: outline only
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppColors.textSecondary.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_NodePainter old) =>
      pulseValue != old.pulseValue ||
      isPassed != old.isPassed ||
      isActive != old.isActive ||
      accent != old.accent;
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. TimelineConnector — The vertical line
// ─────────────────────────────────────────────────────────────────────────────

class TimelineConnector extends StatelessWidget {
  const TimelineConnector({
    super.key,
    required this.accent,
    required this.fillProgress,
    required this.isDesktop,
  });

  final Color accent;
  final double fillProgress;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ConnectorPainter(
        accent: accent,
        fillProgress: fillProgress,
        isDesktop: isDesktop,
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({
    required this.accent,
    required this.fillProgress,
    required this.isDesktop,
  });

  final Color accent;
  final double fillProgress;
  final bool isDesktop;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // X position of the line
    // Desktop: center | Mobile: left (20px in from edge)
    final x = isDesktop ? size.width / 2 : 20.0;
    final totalHeight = size.height;
    final filledHeight = totalHeight * fillProgress;

    // ── Unfilled portion (dashed, subtle) ──
    _drawDashedLine(
      canvas,
      Offset(x, filledHeight),
      Offset(x, totalHeight),
      Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.12)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
      dashLength: 6,
      gapLength: 4,
    );

    if (filledHeight <= 0) return;

    // ── Filled portion (gradient + glow) ──
    final filledPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent.withValues(alpha: 0.6),
          accent,
          accent.withValues(alpha: 0.8),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(x - 1, 0, 2, filledHeight))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(x, 0), Offset(x, filledHeight), filledPaint);

    // Glow on filled portion
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent.withValues(alpha: 0.0),
          accent.withValues(alpha: 0.15),
          accent.withValues(alpha: 0.25),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(x - 8, 0, 16, filledHeight))
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawLine(Offset(x, 0), Offset(x, filledHeight), glowPaint);

    // Bright tip at the fill edge
    canvas.drawCircle(
      Offset(x, filledHeight),
      3,
      Paint()
        ..color = accent
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashLength = 5,
    double gapLength = 3,
  }) {
    final totalLength = (end - start).distance;
    if (totalLength <= 0) return;
    final direction = (end - start) / totalLength;
    double drawn = 0;
    while (drawn < totalLength) {
      final segStart = start + direction * drawn;
      final segEnd = start +
          direction * math.min(drawn + dashLength, totalLength);
      canvas.drawLine(segStart, segEnd, paint);
      drawn += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      fillProgress != old.fillProgress ||
      accent != old.accent ||
      isDesktop != old.isDesktop;
}

// ─────────────────────────────────────────────────────────────────────────────
// Staggered entrance animation (scroll-triggered)
// ─────────────────────────────────────────────────────────────────────────────

class _StaggeredEntrance extends StatefulWidget {
  const _StaggeredEntrance({
    required this.child,
    required this.index,
    required this.slideFromLeft,
  });

  final Widget child;
  final int index;
  final bool slideFromLeft;

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  bool _triggered = false;
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.entrance,
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: CinematicCurves.revealDecel,
    );

    final slideX = widget.slideFromLeft ? -60.0 : 60.0;
    _slide = Tween<Offset>(
      begin: Offset(slideX, 20),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: CinematicCurves.dramaticEntrance,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_checkVisibility);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_checkVisibility);
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_checkVisibility);
    _controller.dispose();
    super.dispose();
  }

  void _checkVisibility() {
    if (_triggered || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final screenH = MediaQuery.sizeOf(context).height;

    if (top < screenH * 0.88 && top > -box.size.height) {
      _triggered = true;
      _scrollPosition?.removeListener(_checkVisibility);
      // Stagger delay per index
      final delay = Duration(
        milliseconds: AppDurations.staggerMedium.inMilliseconds * widget.index,
      );
      Future.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: _slide.value,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
