import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// 1. SkillRadarChart — Interactive hexagonal radar / spider chart
// ═══════════════════════════════════════════════════════════════════════════════

/// Data for a single radar axis.
class RadarSkillData {
  const RadarSkillData({
    required this.label,
    required this.value,
    this.subSkills = const [],
  });

  /// Axis label (e.g. "Frontend").
  final String label;

  /// Proficiency on a 0–100 scale.
  final double value;

  /// Specific skills listed in the hover tooltip.
  final List<String> subSkills;
}

/// Interactive radar / spider chart rendered with [CustomPainter].
///
/// Draws concentric hexagons, fills a semi-transparent accent polygon whose
/// vertices animate outward from the center on scroll-in, and places pulsing
/// dots at each data point.
class SkillRadarChart extends StatefulWidget {
  const SkillRadarChart({
    super.key,
    required this.skills,
    required this.accent,
    this.size = 300,
  });

  final List<RadarSkillData> skills;
  final Color accent;
  final double size;

  @override
  State<SkillRadarChart> createState() => _SkillRadarChartState();
}

class _SkillRadarChartState extends State<SkillRadarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _drawAnimation;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _drawAnimation = CurvedAnimation(
      parent: _controller,
      curve: CinematicCurves.dramaticEntrance,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final side = widget.size;

    return SizedBox(
      width: side,
      height: side + 40, // extra room for labels
      child: AnimatedBuilder(
        animation: _drawAnimation,
        builder: (_, __) {
          return Stack(
            children: [
              // Radar painting
              Positioned.fill(
                child: CustomPaint(
                  painter: _RadarPainter(
                    skills: widget.skills,
                    accent: widget.accent,
                    progress: _drawAnimation.value,
                    hoveredIndex: _hoveredIndex,
                  ),
                ),
              ),
              // Pulsing dots at each vertex
              ..._buildPulsingDots(side),
              // Invisible hit regions for hover detection + tooltips
              ..._buildHitRegions(side),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildPulsingDots(double side) {
    final center = Offset(side / 2, side / 2);
    final radius = side * 0.38;
    final count = widget.skills.length;
    final progress = _drawAnimation.value;

    return List.generate(count, (i) {
      final angle = -math.pi / 2 + (2 * math.pi * i / count);
      final value = widget.skills[i].value / 100.0;
      final r = radius * value * progress;
      final dx = center.dx + r * math.cos(angle) - 5;
      final dy = center.dy + r * math.sin(angle) - 5;

      return Positioned(
        left: dx,
        top: dy,
        child: _PulsingDot(color: widget.accent, delay: i * 120),
      );
    });
  }

  List<Widget> _buildHitRegions(double side) {
    final center = Offset(side / 2, side / 2);
    final labelRadius = side * 0.48;
    final count = widget.skills.length;

    return List.generate(count, (i) {
      final angle = -math.pi / 2 + (2 * math.pi * i / count);
      final dx = center.dx + labelRadius * math.cos(angle);
      final dy = center.dy + labelRadius * math.sin(angle);

      final skill = widget.skills[i];
      final tooltipText = skill.subSkills.isNotEmpty
          ? '${skill.label} (${skill.value.round()}%)\n${skill.subSkills.join(", ")}'
          : '${skill.label}: ${skill.value.round()}%';

      return Positioned(
        left: dx - 36,
        top: dy - 14,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoveredIndex = i),
          onExit: (_) => setState(() => _hoveredIndex = null),
          child: Tooltip(
            message: tooltipText,
            preferBelow: dy > side / 2,
            textStyle: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: AppColors.textBright,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.accent.withValues(alpha: 0.3)),
            ),
            child: SizedBox(
              width: 72,
              height: 28,
              child: Center(
                child: Text(
                  skill.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: _hoveredIndex == i
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: _hoveredIndex == i
                        ? widget.accent
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.skills,
    required this.accent,
    required this.progress,
    this.hoveredIndex,
  });

  final List<RadarSkillData> skills;
  final Color accent;
  final double progress;
  final int? hoveredIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.38;
    final count = skills.length;
    if (count < 3) return;

    // ── Concentric hexagons (grid lines) ──
    final gridPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (var ring = 1; ring <= 5; ring++) {
      final r = maxRadius * ring / 5;
      final path = Path();
      for (var i = 0; i <= count; i++) {
        final angle = -math.pi / 2 + (2 * math.pi * (i % count) / count);
        final pt = Offset(center.dx + r * math.cos(angle),
            center.dy + r * math.sin(angle));
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // ── Axis lines from center ──
    final axisPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.1)
      ..strokeWidth = 0.6;

    for (var i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / count);
      canvas.drawLine(
        center,
        Offset(center.dx + maxRadius * math.cos(angle),
            center.dy + maxRadius * math.sin(angle)),
        axisPaint,
      );
    }

    // ── Filled data polygon ──
    final dataPath = Path();
    for (var i = 0; i <= count; i++) {
      final idx = i % count;
      final angle = -math.pi / 2 + (2 * math.pi * idx / count);
      final value = skills[idx].value / 100.0;
      final r = maxRadius * value * progress;
      final pt = Offset(
          center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) {
        dataPath.moveTo(pt.dx, pt.dy);
      } else {
        dataPath.lineTo(pt.dx, pt.dy);
      }
    }
    dataPath.close();

    // Fill
    canvas.drawPath(
      dataPath,
      Paint()..color = accent.withValues(alpha: 0.15 * progress),
    );

    // Stroke
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = accent.withValues(alpha: 0.7 * progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // ── Hovered axis highlight ──
    if (hoveredIndex != null) {
      final hAngle =
          -math.pi / 2 + (2 * math.pi * hoveredIndex! / count);
      canvas.drawLine(
        center,
        Offset(center.dx + maxRadius * math.cos(hAngle),
            center.dy + maxRadius * math.sin(hAngle)),
        Paint()
          ..color = accent.withValues(alpha: 0.6)
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      progress != old.progress ||
      accent != old.accent ||
      hoveredIndex != old.hoveredIndex;
}

/// Small dot that pulses (scales) forever.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color, this.delay = 0});
  final Color color;
  final int delay;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: AppDurations.loadingPulse,
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _pulse.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final scale = 0.6 + 0.4 * _pulse.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. TechStackGrid — Interactive technology grid with category filtering
// ═══════════════════════════════════════════════════════════════════════════════

/// A single technology entry in the grid.
class TechItem {
  const TechItem({
    required this.name,
    required this.icon,
    required this.category,
    this.proficiency = 0.7,
    this.experienceLevel = 'Intermediate',
    this.accentColor,
  });

  final String name;

  /// Icon data (Material or custom).
  final IconData icon;

  /// Category key matching [TechStackGrid.categories].
  final String category;

  /// 0.0–1.0 proficiency displayed as a bar.
  final double proficiency;

  /// Textual experience level for tooltip.
  final String experienceLevel;

  /// Icon tint when hovered; falls back to the grid's accent.
  final Color? accentColor;
}

/// An interactive filterable grid of technology icons.
///
/// Icons are grayscale by default, colorize on hover with 3D tilt, and include
/// a proficiency bar that animates on entrance.
class TechStackGrid extends StatefulWidget {
  const TechStackGrid({
    super.key,
    required this.items,
    required this.accent,
    this.categories = const ['All', 'Languages', 'Frameworks', 'Tools', 'Platforms'],
  });

  final List<TechItem> items;
  final Color accent;
  final List<String> categories;

  @override
  State<TechStackGrid> createState() => _TechStackGridState();
}

class _TechStackGridState extends State<TechStackGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  String _activeCategory = 'All';

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  List<TechItem> get _filteredItems => _activeCategory == 'All'
      ? widget.items
      : widget.items.where((t) => t.category == _activeCategory).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Category filter tabs ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: widget.categories.map((cat) {
              final isActive = cat == _activeCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterTab(
                  label: cat,
                  isActive: isActive,
                  accent: widget.accent,
                  onTap: () {
                    if (cat != _activeCategory) {
                      setState(() => _activeCategory = cat);
                      _entrance
                        ..reset()
                        ..forward();
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        // ── Grid ──
        AnimatedBuilder(
          animation: _entrance,
          builder: (_, __) {
            final items = _filteredItems;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(items.length, (i) {
                // Stagger from top-left
                final totalMs = 600.0 + 50.0 * (items.length - 1);
                final start = (50.0 * i) / totalMs;
                final end = (600.0 + 50.0 * i) / totalMs;
                final stagger = CurvedAnimation(
                  parent: _entrance,
                  curve: Interval(
                    start.clamp(0.0, 1.0),
                    end.clamp(0.0, 1.0),
                    curve: CinematicCurves.dramaticEntrance,
                  ),
                );

                return Opacity(
                  opacity: stagger.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - stagger.value)),
                    child: _TechGridTile(
                      item: items[i],
                      accent: widget.accent,
                      entranceProgress: stagger.value,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

class _FilterTab extends StatefulWidget {
  const _FilterTab({
    required this.label,
    required this.isActive,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_FilterTab> createState() => _FilterTabState();
}

class _FilterTabState extends State<_FilterTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? widget.accent.withValues(alpha: 0.15)
                : _hovered
                    ? widget.accent.withValues(alpha: 0.06)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? widget.accent.withValues(alpha: 0.4)
                  : widget.accent.withValues(alpha: _hovered ? 0.2 : 0.08),
            ),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? widget.accent : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TechGridTile extends StatefulWidget {
  const _TechGridTile({
    required this.item,
    required this.accent,
    required this.entranceProgress,
  });

  final TechItem item;
  final Color accent;
  final double entranceProgress;

  @override
  State<_TechGridTile> createState() => _TechGridTileState();
}

class _TechGridTileState extends State<_TechGridTile> {
  bool _hovered = false;
  Offset _mousePos = const Offset(0.5, 0.5);

  static const double _maxTilt = 8.0 * math.pi / 180.0;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tintColor = item.accentColor ?? widget.accent;

    final dx = (_mousePos.dx - 0.5) * 2.0;
    final dy = (_mousePos.dy - 0.5) * 2.0;

    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateY(_hovered ? dx * _maxTilt : 0)
      ..rotateX(_hovered ? -dy * _maxTilt : 0)
      ..translate(0.0, _hovered ? -6.0 : 0.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onHover: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        setState(() {
          _mousePos = Offset(
            e.localPosition.dx / box.size.width,
            e.localPosition.dy / box.size.height,
          );
        });
      },
      onExit: (_) => setState(() {
        _hovered = false;
        _mousePos = const Offset(0.5, 0.5);
      }),
      child: Tooltip(
        message: '${item.name} — ${item.experienceLevel}',
        textStyle: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          color: AppColors.textBright,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.accent.withValues(alpha: 0.3)),
        ),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          transform: transform,
          transformAlignment: Alignment.center,
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.accent.withValues(alpha: 0.08)
                : AppColors.backgroundLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? widget.accent.withValues(alpha: 0.25)
                  : AppColors.textSecondary.withValues(alpha: 0.08),
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon: grayscale → color on hover
              AnimatedDefaultTextStyle(
                duration: AppDurations.fast,
                style: TextStyle(
                  color: _hovered ? tintColor : AppColors.textSecondary,
                ),
                child: Icon(
                  item.icon,
                  size: 30,
                  color: _hovered ? tintColor : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color:
                      _hovered ? AppColors.textBright : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // Proficiency bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 4,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _ProficiencyBarPainter(
                      fill: item.proficiency * widget.entranceProgress,
                      accent: _hovered ? tintColor : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProficiencyBarPainter extends CustomPainter {
  _ProficiencyBarPainter({required this.fill, required this.accent});

  final double fill;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    // Track
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3)),
      Paint()..color = accent.withValues(alpha: 0.15),
    );
    // Fill
    final w = size.width * fill.clamp(0.0, 1.0);
    if (w <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, size.height),
        const Radius.circular(3),
      ),
      Paint()..color = accent.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_ProficiencyBarPainter old) =>
      fill != old.fill || accent != old.accent;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. AboutTimeline — Horizontal scrollable personal journey timeline
// ═══════════════════════════════════════════════════════════════════════════════

/// A single milestone on the timeline.
class TimelineMilestone {
  const TimelineMilestone({
    required this.year,
    required this.title,
    required this.description,
    this.icon = Icons.flag_rounded,
  });

  final String year;
  final String title;
  final String description;
  final IconData icon;
}

/// Horizontal scrollable timeline with a progress line and pulsing milestone
/// nodes. The connecting line fills as the user scrolls horizontally.
class AboutTimeline extends StatefulWidget {
  const AboutTimeline({
    super.key,
    required this.milestones,
    required this.accent,
  });

  final List<TimelineMilestone> milestones;
  final Color accent;

  @override
  State<AboutTimeline> createState() => _AboutTimelineState();
}

class _AboutTimelineState extends State<AboutTimeline> {
  final ScrollController _scroll = ScrollController();
  double _scrollFraction = 0.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    setState(() {
      _scrollFraction = max > 0 ? (_scroll.offset / max).clamp(0.0, 1.0) : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.milestones.length;
    const nodeWidth = 180.0;
    const nodeSpacing = 40.0;

    return SizedBox(
      height: 200,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: count * (nodeWidth + nodeSpacing),
            child: Stack(
              children: [
                // ── Background line ──
                Positioned(
                  left: 0,
                  right: 0,
                  top: 60,
                  child: Container(
                    height: 2,
                    color: widget.accent.withValues(alpha: 0.1),
                  ),
                ),
                // ── Filled progress line ──
                Positioned(
                  left: 0,
                  top: 60,
                  child: AnimatedContainer(
                    duration: AppDurations.microFast,
                    width: count *
                        (nodeWidth + nodeSpacing) *
                        _scrollFraction.clamp(0.0, 1.0),
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.accent,
                          widget.accent.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                ),
                // ── Milestone nodes ──
                Row(
                  children: List.generate(count, (i) {
                    final milestone = widget.milestones[i];
                    // Consider milestone "reached" when the scroll fraction
                    // passes its proportional position in the list.
                    final threshold = count > 1 ? i / (count - 1) : 0.0;
                    final reached = _scrollFraction >= threshold || i == 0;

                    return SizedBox(
                      width: nodeWidth + nodeSpacing,
                      child: _MilestoneNode(
                        milestone: milestone,
                        accent: widget.accent,
                        reached: reached,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MilestoneNode extends StatefulWidget {
  const _MilestoneNode({
    required this.milestone,
    required this.accent,
    required this.reached,
  });

  final TimelineMilestone milestone;
  final Color accent;
  final bool reached;

  @override
  State<_MilestoneNode> createState() => _MilestoneNodeState();
}

class _MilestoneNodeState extends State<_MilestoneNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: AppDurations.loadingPulse,
    );
  }

  @override
  void didUpdateWidget(covariant _MilestoneNode old) {
    super.didUpdateWidget(old);
    if (widget.reached && !old.reached) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Year label
        Text(
          widget.milestone.year,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color:
                widget.reached ? widget.accent : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        // Circle node
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) {
            final scale = widget.reached ? 1.0 + 0.15 * _pulse.value : 1.0;
            return Transform.scale(
              scale: scale,
              child: AnimatedContainer(
                duration: AppDurations.medium,
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.reached
                      ? widget.accent.withValues(alpha: 0.2)
                      : AppColors.backgroundLight,
                  border: Border.all(
                    color: widget.reached
                        ? widget.accent
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: widget.reached
                      ? [
                          BoxShadow(
                            color: widget.accent.withValues(alpha: 0.3),
                            blurRadius: 12,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  widget.milestone.icon,
                  size: 16,
                  color: widget.reached
                      ? widget.accent
                      : AppColors.textSecondary,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Title
        Text(
          widget.milestone.title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.reached
                ? AppColors.textBright
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        // Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            widget.milestone.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: widget.reached
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. CodeSnippetWidget — Animated self-typing code display
// ═══════════════════════════════════════════════════════════════════════════════

/// An animated code display that types itself out character by character with
/// syntax highlighting, line numbers, a blinking cursor, and a subtle
/// scan-line overlay.
class CodeSnippetWidget extends StatefulWidget {
  const CodeSnippetWidget({
    super.key,
    this.codeLines,
    this.accent,
    this.typingSpeed = const Duration(milliseconds: 30),
  });

  /// Lines of pseudo-code. If null a default developer-bio snippet is used.
  final List<String>? codeLines;

  /// Accent colour for keywords and special tokens.
  final Color? accent;

  /// Delay between characters.
  final Duration typingSpeed;

  @override
  State<CodeSnippetWidget> createState() => _CodeSnippetWidgetState();
}

class _CodeSnippetWidgetState extends State<CodeSnippetWidget> {
  static const _defaultCode = [
    'class Developer {',
    '  final name = "Yusuf";',
    '  final role = "Full-Stack Engineer";',
    '  final languages = ["Dart", "Kotlin", "Swift"];',
    '  final passion = "Building pixel-perfect UIs";',
    '',
    '  bool get isAvailable => true;',
    '',
    '  String greet() {',
    '    return "Let\'s build something great!";',
    '  }',
    '}',
  ];

  late final List<String> _lines;
  int _charIndex = 0;
  int _totalChars = 0;
  Timer? _typeTimer;
  bool _cursorVisible = true;
  Timer? _cursorBlink;

  @override
  void initState() {
    super.initState();
    _lines = widget.codeLines ?? _defaultCode;
    _totalChars = _lines.fold<int>(
        0, (sum, line) => sum + line.length + 1); // +1 for newline
    _startTyping();
    _cursorBlink = Timer.periodic(
      const Duration(milliseconds: 530),
      (_) {
        if (mounted) setState(() => _cursorVisible = !_cursorVisible);
      },
    );
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _cursorBlink?.cancel();
    super.dispose();
  }

  void _startTyping() {
    _typeTimer = Timer.periodic(widget.typingSpeed, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_charIndex >= _totalChars) {
        timer.cancel();
        return;
      }
      setState(() => _charIndex++);
    });
  }

  /// Build visible text from character index, returning a list of
  /// (lineIndex, visibleText) pairs.
  List<(int, String)> _visibleLines() {
    final result = <(int, String)>[];
    var remaining = _charIndex;
    for (var i = 0; i < _lines.length; i++) {
      if (remaining <= 0) break;
      final line = _lines[i];
      if (remaining >= line.length + 1) {
        result.add((i, line));
        remaining -= line.length + 1;
      } else {
        result.add((i, line.substring(0, remaining)));
        remaining = 0;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ?? AppColors.aboutAccent;
    final visible = _visibleLines();
    final isTyping = _charIndex < _totalChars;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Stack(
        children: [
          // Scan-line effect overlay
          Positioned.fill(child: _ScanLines()),
          // Code content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (lineIdx, text) in visible)
                  _CodeLine(
                    lineNumber: lineIdx + 1,
                    text: text,
                    accent: accent,
                    showCursor: lineIdx == visible.last.$1 &&
                        (isTyping || _cursorVisible),
                    cursorVisible: _cursorVisible,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeLine extends StatelessWidget {
  const _CodeLine({
    required this.lineNumber,
    required this.text,
    required this.accent,
    this.showCursor = false,
    this.cursorVisible = true,
  });

  final int lineNumber;
  final String text;
  final Color accent;
  final bool showCursor;
  final bool cursorVisible;

  static const _keywords = {
    'class', 'final', 'bool', 'get', 'return', 'String', 'true', 'false',
    'int', 'double', 'void', 'var', 'const', 'static', 'if', 'else',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line number
          SizedBox(
            width: 36,
            child: Text(
              lineNumber.toString(),
              textAlign: TextAlign.right,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.4),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Syntax-highlighted code
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  ..._highlight(text),
                  if (showCursor && cursorVisible)
                    TextSpan(
                      text: '\u2588', // block cursor
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        color: accent,
                        height: 1.6,
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

  List<TextSpan> _highlight(String code) {
    if (code.isEmpty) return [];

    final spans = <TextSpan>[];
    final buffer = StringBuffer();
    var inString = false;
    String? stringDelim;

    void flushBuffer({Color? color}) {
      if (buffer.isEmpty) return;
      final raw = buffer.toString();
      buffer.clear();

      if (color != null) {
        spans.add(TextSpan(
          text: raw,
          style: GoogleFonts.jetBrainsMono(
              fontSize: 13, color: color, height: 1.6),
        ));
        return;
      }

      // Check for keywords
      final words = raw.split(RegExp(r'(?<=\s)|(?=\s)|(?<=[{}();\[\]=>,.])|(?=[{}();\[\]=>,.])'));
      for (final word in words) {
        Color c;
        if (_keywords.contains(word)) {
          c = accent;
        } else if (RegExp(r'^[{}();\[\]=>,.]$').hasMatch(word)) {
          c = AppColors.textSecondary;
        } else if (word == '=>') {
          c = accent;
        } else {
          c = AppColors.textBright;
        }
        spans.add(TextSpan(
          text: word,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            color: c,
            fontWeight:
                _keywords.contains(word) ? FontWeight.w600 : FontWeight.w400,
            height: 1.6,
          ),
        ));
      }
    }

    for (var i = 0; i < code.length; i++) {
      final ch = code[i];
      if (inString) {
        buffer.write(ch);
        if (ch == stringDelim && (i == 0 || code[i - 1] != '\\')) {
          flushBuffer(color: const Color(0xFFA5D6A7)); // green for strings
          inString = false;
          stringDelim = null;
        }
      } else if (ch == '"' || ch == "'") {
        flushBuffer();
        buffer.write(ch);
        inString = true;
        stringDelim = ch;
      } else if (ch == '/' && i + 1 < code.length && code[i + 1] == '/') {
        flushBuffer();
        // Rest of line is comment
        spans.add(TextSpan(
          text: code.substring(i),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
            height: 1.6,
          ),
        ));
        return spans;
      } else {
        buffer.write(ch);
      }
    }
    // Flush remaining (could still be in a string if line wraps)
    if (inString) {
      flushBuffer(color: const Color(0xFFA5D6A7));
    } else {
      flushBuffer();
    }

    return spans;
  }
}

/// Faint horizontal scan-line overlay for CRT effect.
class _ScanLines extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScanLinePainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.04);
    for (var y = 0.0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. InterestsTags — Personal interests cloud with animated entrance
// ═══════════════════════════════════════════════════════════════════════════════

/// A floating cloud of interest/hobby tags with slight random rotations
/// and animated entrance from random positions.
class InterestsTags extends StatefulWidget {
  const InterestsTags({
    super.key,
    required this.tags,
    required this.accent,
  });

  final List<String> tags;
  final Color accent;

  @override
  State<InterestsTags> createState() => _InterestsTagsState();
}

class _InterestsTagsState extends State<InterestsTags>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final List<double> _rotations;
  late final List<Offset> _startOffsets;
  static final _rng = math.Random(42);

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    // Generate deterministic random rotations ±3 degrees.
    _rotations = List.generate(
      widget.tags.length,
      (_) => (_rng.nextDouble() - 0.5) * 6.0 * math.pi / 180.0,
    );

    // Random start offsets for float-in animation.
    _startOffsets = List.generate(
      widget.tags.length,
      (_) => Offset(
        (_rng.nextDouble() - 0.5) * 200,
        (_rng.nextDouble() - 0.5) * 120,
      ),
    );
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (_, __) {
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(widget.tags.length, (i) {
            final totalMs = 600.0 + 60.0 * (widget.tags.length - 1);
            final start = (60.0 * i) / totalMs;
            final end = (600.0 + 60.0 * i) / totalMs;
            final progress = CurvedAnimation(
              parent: _entrance,
              curve: Interval(
                start.clamp(0.0, 1.0),
                end.clamp(0.0, 1.0),
                curve: CinematicCurves.dramaticEntrance,
              ),
            ).value;

            final offset = Offset(
              _startOffsets[i].dx * (1 - progress),
              _startOffsets[i].dy * (1 - progress),
            );

            return Transform.translate(
              offset: offset,
              child: Opacity(
                opacity: progress,
                child: Transform.rotate(
                  angle: _rotations[i],
                  child: _InterestTag(
                    label: widget.tags[i],
                    accent: widget.accent,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _InterestTag extends StatefulWidget {
  const _InterestTag({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  State<_InterestTag> createState() => _InterestTagState();
}

class _InterestTagState extends State<_InterestTag> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        transform: Matrix4.identity()..scale(_hovered ? 1.06 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: _hovered
              ? widget.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _hovered
                ? widget.accent.withValues(alpha: 0.5)
                : AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: _hovered ? FontWeight.w600 : FontWeight.w400,
            color: _hovered ? widget.accent : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
