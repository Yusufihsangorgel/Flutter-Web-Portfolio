import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ProjectFilterBar — Horizontal category pills with animated active state
// ═══════════════════════════════════════════════════════════════════════════════

/// A horizontal row of category filter pills. Each pill shows a category label
/// and an optional count badge. The active pill animates to a filled accent
/// state. On mobile the bar becomes horizontally scrollable.
class ProjectFilterBar extends StatefulWidget {
  const ProjectFilterBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.counts = const {},
    this.showAllOption = true,
    this.allLabel = 'All',
  });

  /// List of category labels (e.g. ['Mobile', 'Web', 'Backend']).
  final List<String> categories;

  /// Currently selected category. Pass empty string or 'All' for the "All"
  /// option (when [showAllOption] is true).
  final String selectedCategory;

  /// Callback when a category pill is tapped.
  final ValueChanged<String> onCategorySelected;

  /// Optional count per category, e.g. {'Mobile': 5, 'Web': 3}.
  final Map<String, int> counts;

  /// Whether to show an "All" pill at the start.
  final bool showAllOption;

  /// Label text for the "All" option.
  final String allLabel;

  @override
  State<ProjectFilterBar> createState() => _ProjectFilterBarState();
}

class _ProjectFilterBarState extends State<ProjectFilterBar> {
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<String> get _effectiveCategories => [
        if (widget.showAllOption) widget.allLabel,
        ...widget.categories,
      ];

  bool _isSelected(String category) {
    if (category == widget.allLabel) {
      return widget.selectedCategory.isEmpty ||
          widget.selectedCategory == widget.allLabel;
    }
    return widget.selectedCategory == category;
  }

  int? _countFor(String category) {
    if (category == widget.allLabel) {
      // Sum all counts for the "All" pill.
      if (widget.counts.isEmpty) return null;
      final total = widget.counts.values.fold<int>(0, (a, b) => a + b);
      return total > 0 ? total : null;
    }
    final c = widget.counts[category];
    return (c != null && c > 0) ? c : null;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final pills = _effectiveCategories;

    return Obx(() {
      final accent = Get.find<SceneDirector>().currentAccent.value;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      final child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < pills.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _FilterPill(
              label: pills[i],
              isSelected: _isSelected(pills[i]),
              count: _countFor(pills[i]),
              accent: accent,
              isDark: isDark,
              onTap: () => widget.onCategorySelected(pills[i]),
            ),
          ],
        ],
      );

      // On mobile or when categories overflow, wrap in a scrollable row.
      if (isMobile || pills.length > 5) {
        return SizedBox(
          height: 44,
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Colors.transparent,
                (isDark ? AppColors.background : AppColors.lightBackground),
                (isDark ? AppColors.background : AppColors.lightBackground),
                Colors.transparent,
              ],
              stops: const [0.0, 0.03, 0.97, 1.0],
            ).createShader(bounds),
            blendMode: BlendMode.dstOut,
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ),
        );
      }

      // On desktop, center the pills.
      return Center(child: child);
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual filter pill with animated active state
// ─────────────────────────────────────────────────────────────────────────────

class _FilterPill extends StatefulWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.count,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final int? count;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _selectCtrl;
  late final Animation<double> _selectAnim;

  @override
  void initState() {
    super.initState();
    _selectCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.medium,
      value: widget.isSelected ? 1.0 : 0.0,
    );
    _selectAnim = CurvedAnimation(
      parent: _selectCtrl,
      curve: CinematicCurves.hoverLift,
    );
  }

  @override
  void didUpdateWidget(_FilterPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      widget.isSelected ? _selectCtrl.forward() : _selectCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _selectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _selectAnim,
      builder: (context, _) {
        final t = _selectAnim.value;

        // Interpolated colors.
        final bgColor = Color.lerp(
          _hovered
              ? widget.accent.withValues(alpha: 0.08)
              : Colors.transparent,
          widget.accent,
          t,
        )!;

        final borderColor = Color.lerp(
          _hovered
              ? widget.accent.withValues(alpha: 0.3)
              : widget.accent.withValues(alpha: 0.15),
          widget.accent,
          t,
        )!;

        final textColor = Color.lerp(
          _hovered
              ? (widget.isDark ? AppColors.textBright : AppColors.lightTextBright)
              : (widget.isDark
                  ? AppColors.textPrimary
                  : AppColors.lightTextPrimary),
          AppColors.white,
          t,
        )!;

        final badgeBgColor = Color.lerp(
          widget.accent.withValues(alpha: 0.15),
          AppColors.white.withValues(alpha: 0.2),
          t,
        )!;

        final badgeTextColor = Color.lerp(
          widget.accent,
          AppColors.white,
          t,
        )!;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: widget.accent.withValues(alpha: 0.25 * t),
                          blurRadius: 12 * t,
                          offset: Offset(0, 2 * t),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight:
                          widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (widget.count != null) ...[
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: AppDurations.fast,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.count}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
