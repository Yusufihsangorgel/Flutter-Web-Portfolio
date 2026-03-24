import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/controllers/achievement_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Achievement showcase — full gallery modal
// ─────────────────────────────────────────────────────────────────────────────

/// A modal overlay displaying all achievements in a grid layout.
///
/// Unlocked achievements glow with full color; locked ones are greyed out
/// with a "?" icon and hint text. Progress bars show partial completion.
///
/// Open from the footer, command palette, or anywhere else:
/// ```dart
/// AchievementShowcase.show(context);
/// ```
class AchievementShowcase extends StatefulWidget {
  const AchievementShowcase({super.key});

  /// Shows the achievement showcase as a modal overlay with backdrop blur.
  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close achievements',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: AppDurations.medium,
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: CinematicCurves.dramaticEntrance,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 16 * curved.value,
            sigmaY: 16 * curved.value,
          ),
          child: FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (_, __, ___) => const AchievementShowcase(),
    );
  }

  @override
  State<AchievementShowcase> createState() => _AchievementShowcaseState();
}

class _AchievementShowcaseState extends State<AchievementShowcase>
    with TickerProviderStateMixin {
  late final AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Responsive: 2 columns on mobile, 3 on tablet, 4 on desktop
    final crossAxisCount = screenWidth < 500
        ? 2
        : screenWidth < 900
            ? 3
            : 4;

    final dialogWidth = (screenWidth * 0.9).clamp(320.0, 860.0);
    final dialogHeight = (screenHeight * 0.85).clamp(400.0, 720.0);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.background : AppColors.lightBackground)
                .withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 60,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: _buildGrid(crossAxisCount, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final controller = Get.find<AchievementController>();

    return Obx(() {
      final unlocked = controller.unlockedCount;
      final total = controller.totalAchievements;

      return Container(
        padding: const EdgeInsets.fromLTRB(28, 24, 16, 20),
        child: Row(
          children: [
            // Trophy icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFCD7F32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            // Title & counter
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievements',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textBright : AppColors.lightTextBright,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$unlocked / $total Unlocked',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total > 0 ? unlocked / total : 0,
                            minHeight: 6,
                            backgroundColor: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.08),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFFD700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Close button
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.close_rounded,
                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
              ),
              splashRadius: 20,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildGrid(int crossAxisCount, bool isDark) {
    final controller = Get.find<AchievementController>();
    const achievements = Achievement.values;

    return Obx(() {
      // Force rebuild when unlocked/progress changes
      controller.unlockedIds.length;
      controller.progress.length;

      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          final isUnlocked = controller.isUnlocked(achievement);
          final fraction = controller.progressFraction(achievement);

          // Stagger: each card fades in slightly after the previous
          final staggerDelay = index / achievements.length;
          final itemAnimation = CurvedAnimation(
            parent: _staggerController,
            curve: Interval(
              (staggerDelay * 0.6).clamp(0.0, 1.0),
              ((staggerDelay * 0.6) + 0.4).clamp(0.0, 1.0),
              curve: CinematicCurves.dramaticEntrance,
            ),
          );

          return AnimatedBuilder(
            animation: itemAnimation,
            builder: (context, _) => Opacity(
              opacity: itemAnimation.value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - itemAnimation.value)),
                child: _AchievementCard(
                  achievement: achievement,
                  isUnlocked: isUnlocked,
                  progressFraction: fraction,
                  isDark: isDark,
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual achievement card
// ─────────────────────────────────────────────────────────────────────────────

class _AchievementCard extends StatefulWidget {
  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
    required this.progressFraction,
    required this.isDark,
  });

  final Achievement achievement;
  final bool isUnlocked;
  final double progressFraction;
  final bool isDark;

  @override
  State<_AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<_AchievementCard> {
  bool _isHovered = false;

  static const _gold = Color(0xFFFFD700);
  static const _bronze = Color(0xFFCD7F32);

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.isUnlocked;
    final achievement = widget.achievement;
    final isDark = widget.isDark;

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppDurations.buttonHover,
        curve: CinematicCurves.hoverLift,
        transform: Matrix4.identity()
          ..translateByDouble(0.0, _isHovered ? -4.0 : 0.0, 0.0, 0.0),
        decoration: BoxDecoration(
          gradient: unlocked
              ? LinearGradient(
                  colors: [
                    (isDark ? const Color(0xFF1A1333) : const Color(0xFFFFFDF5))
                        .withValues(alpha: 0.9),
                    (isDark ? const Color(0xFF0F0A2A) : const Color(0xFFFFF8E1))
                        .withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: unlocked
              ? null
              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: unlocked
                ? _gold.withValues(alpha: _isHovered ? 0.6 : 0.3)
                : (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.06),
            width: unlocked ? 1.5 : 1,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: _gold.withValues(alpha: _isHovered ? 0.25 : 0.12),
                    blurRadius: _isHovered ? 20 : 12,
                    spreadRadius: _isHovered ? 2 : 0,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            _buildIcon(unlocked, achievement, isDark),
            const SizedBox(height: 10),
            // Name or "?"
            Text(
              unlocked ? achievement.name : '???',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: unlocked
                    ? (isDark ? AppColors.textBright : AppColors.lightTextBright)
                    : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Description or hint
            Flexible(
              child: Text(
                unlocked ? achievement.description : achievement.hint,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: unlocked
                      ? (isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : AppColors.lightTextSecondary)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.3)),
                  fontStyle: unlocked ? FontStyle.normal : FontStyle.italic,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Progress bar (only for multi-step achievements that are not yet unlocked)
            if (!unlocked && achievement.maxProgress > 1) ...[
              const SizedBox(height: 8),
              _buildProgressBar(isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(bool unlocked, Achievement achievement, bool isDark) {
    if (unlocked) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_gold, _bronze],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: 0.4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(
          IconData(achievement.icon, fontFamily: 'MaterialIcons'),
          color: Colors.white,
          size: 24,
        ),
      );
    }

    // Locked state
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        ),
      ),
      child: Icon(
        Icons.lock_rounded,
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
        size: 22,
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final controller = Get.find<AchievementController>();
    final current = controller.progress[widget.achievement.id] ?? 0;
    final max = widget.achievement.maxProgress;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: widget.progressFraction,
            minHeight: 4,
            backgroundColor:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(
              _gold.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$current / $max',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 8,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AnimatedBuilder — thin helper to avoid boilerplate AnimatedWidget subclasses
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedBuilder extends AnimatedWidget {
  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  final Widget Function(BuildContext context, Widget? child) builder;

  @override
  Widget build(BuildContext context) => builder(context, null);
}
