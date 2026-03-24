import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/controllers/achievement_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Overlay entry manager — handles stacking multiple notifications
// ─────────────────────────────────────────────────────────────────────────────

/// Shows a toast-style achievement notification that slides in from the
/// top-right, plays a particle burst, then auto-dismisses after 4 seconds.
///
/// Stacks vertically when multiple achievements unlock simultaneously.
class AchievementNotificationManager {
  AchievementNotificationManager._();

  static final _activeEntries = <_AchievementEntry>[];
  static const _verticalSpacing = 8.0;
  static const _notificationHeight = 88.0;

  /// Show a notification for the given [achievement].
  static void show(BuildContext context, Achievement achievement) {
    late final OverlayEntry overlayEntry;
    final index = _activeEntries.length;

    void removeEntry() {
      final entry = _activeEntries.firstWhere(
        (e) => e.overlayEntry == overlayEntry,
        orElse: () => _AchievementEntry(overlayEntry, -1),
      );
      if (entry.index >= 0) {
        _activeEntries.remove(entry);
        overlayEntry.remove();
        // Reindex remaining entries
        for (var i = 0; i < _activeEntries.length; i++) {
          _activeEntries[i] = _AchievementEntry(
            _activeEntries[i].overlayEntry,
            i,
          );
        }
      }
    }

    overlayEntry = OverlayEntry(
      builder: (_) => _AchievementToast(
        achievement: achievement,
        index: index,
        onDismiss: removeEntry,
      ),
    );

    _activeEntries.add(_AchievementEntry(overlayEntry, index));
    Overlay.of(context).insert(overlayEntry);
  }
}

class _AchievementEntry {
  _AchievementEntry(this.overlayEntry, this.index);

  final OverlayEntry overlayEntry;
  final int index;
}

// ─────────────────────────────────────────────────────────────────────────────
// Toast widget
// ─────────────────────────────────────────────────────────────────────────────

class _AchievementToast extends StatefulWidget {
  const _AchievementToast({
    required this.achievement,
    required this.index,
    required this.onDismiss,
  });

  final Achievement achievement;
  final int index;
  final VoidCallback onDismiss;

  @override
  State<_AchievementToast> createState() => _AchievementToastState();
}

class _AchievementToastState extends State<_AchievementToast>
    with TickerProviderStateMixin {
  static const _autoDismissDelay = Duration(seconds: 4);
  static const _slideDuration = Duration(milliseconds: 500);
  static const _particleDuration = Duration(milliseconds: 1200);

  late final AnimationController _slideController;
  late final AnimationController _particleController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  // Trophy colors
  static const _gold = Color(0xFFFFD700);
  static const _bronze = Color(0xFFCD7F32);
  static const _goldGlow = Color(0x40FFD700);

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: _slideDuration,
    );

    _particleController = AnimationController(
      vsync: this,
      duration: _particleDuration,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: CinematicCurves.dramaticEntrance,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideController.forward();
    _particleController.forward();

    _dismissTimer = Timer(_autoDismissDelay, _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _slideController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    _dismissTimer?.cancel();
    await _slideController.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topOffset = 24.0 +
        widget.index *
            (AchievementNotificationManager._notificationHeight +
                AchievementNotificationManager._verticalSpacing);

    return Positioned(
      top: topOffset,
      right: 24,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _dismiss,
              child: SizedBox(
                width: 340,
                height: AchievementNotificationManager._notificationHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Particle burst layer
                    Positioned.fill(
                      child: _ParticleBurstWidget(
                        animation: _particleController,
                        color: _gold,
                      ),
                    ),
                    // Card
                    _buildCard(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isDark ? const Color(0xFF1A1333) : const Color(0xFFFFFDF5))
                .withValues(alpha: 0.95),
            (isDark ? const Color(0xFF0F0A2A) : const Color(0xFFFFF8E1))
                .withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _gold.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          const BoxShadow(
            color: _goldGlow,
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Trophy icon with glow
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_gold, _bronze],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ACHIEVEMENT UNLOCKED',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _gold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.achievement.name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.achievement.description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Dismiss X
          Icon(
            Icons.close_rounded,
            size: 16,
            color: isDark
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Particle burst painter
// ─────────────────────────────────────────────────────────────────────────────

class _ParticleBurstPainter extends CustomPainter {
  _ParticleBurstPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  static const _particleCount = 16;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0 || progress <= 0.0) return;

    final center = Offset(size.width * 0.15, size.height * 0.5);
    final rng = math.Random(42); // deterministic seed for stable positions

    for (var i = 0; i < _particleCount; i++) {
      final angle = (i / _particleCount) * math.pi * 2 + rng.nextDouble() * 0.5;
      final speed = 30.0 + rng.nextDouble() * 50.0;
      final particleSize = 2.0 + rng.nextDouble() * 3.0;

      final distance = speed * progress;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final dx = center.dx + math.cos(angle) * distance;
      final dy = center.dy + math.sin(angle) * distance;

      final paint = Paint()
        ..color = Color.lerp(color, Colors.white, rng.nextDouble() * 0.5)!
            .withValues(alpha: opacity * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      canvas.drawCircle(Offset(dx, dy), particleSize * (1.0 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticleBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Particle burst animated widget
// ─────────────────────────────────────────────────────────────────────────────

class _ParticleBurstWidget extends AnimatedWidget {
  const _ParticleBurstWidget({
    required AnimationController animation,
    required this.color,
  }) : super(listenable: animation);

  final Color color;

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return CustomPaint(
      painter: _ParticleBurstPainter(
        progress: animation.value,
        color: color,
      ),
    );
  }
}
