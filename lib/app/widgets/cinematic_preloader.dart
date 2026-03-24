import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/widgets/preloader_animations.dart';

/// Cinematic preloader — a jaw-dropping intro sequence that plays once per
/// session before revealing the main portfolio content.
///
/// Sequence (across ~3.5 s master timeline):
///   0.00–0.05  Fade-in background & particles
///   0.05–0.40  Letter-by-letter name reveal
///   0.30–0.55  Tagline fade-in below name
///   0.10–0.75  Progress bar + percentage counter
///   0.78–1.00  Circle-expand reveal to main content
///
/// Usage:
/// ```dart
/// CinematicPreloader(
///   onLoadingComplete: () => loadingController.setLoading(false),
///   child: HomeView(),
/// )
/// ```
class CinematicPreloader extends StatefulWidget {
  const CinematicPreloader({
    super.key,
    required this.child,
    this.onLoadingComplete,
    this.displayName = 'YUSUF IHSAN GORGEL',
    this.tagline = 'Crafting digital experiences',
    this.minimumDuration = const Duration(milliseconds: 3500),
    this.exitDuration = const Duration(milliseconds: 900),
  });

  /// The main content revealed after the preloader finishes.
  final Widget child;

  /// Fired once the full sequence (including exit) completes.
  final VoidCallback? onLoadingComplete;

  /// Name displayed during the letter-stagger reveal.
  final String displayName;

  /// Tagline that fades in below the name.
  final String tagline;

  /// Minimum wall-clock time the preloader is visible (for dramatic effect).
  final Duration minimumDuration;

  /// Duration of the circle-expand exit animation.
  final Duration exitDuration;

  /// Session-scoped flag — ensures the preloader plays only once.
  static bool _hasPlayedThisSession = false;

  /// Reset for testing or hot-restart scenarios.
  static void resetSessionFlag() => _hasPlayedThisSession = false;

  @override
  State<CinematicPreloader> createState() => _CinematicPreloaderState();
}

class _CinematicPreloaderState extends State<CinematicPreloader>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────

  /// Master timeline for the entire preloader sequence.
  late AnimationController _master;

  /// Exit animation: circle-expand reveal.
  late AnimationController _exit;

  // ── Sequenced intervals off the master controller ────────────────────────

  late Animation<double> _bgFade;
  late Animation<double> _nameReveal;
  late Animation<double> _taglineFade;
  late Animation<double> _progressAnim;
  late Animation<double> _exitReveal;

  bool _showContent = false;
  bool _preloaderDone = false;

  @override
  void initState() {
    super.initState();

    // Skip entirely if already played this session.
    if (CinematicPreloader._hasPlayedThisSession) {
      _preloaderDone = true;
      _showContent = true;
      return;
    }

    CinematicPreloader._hasPlayedThisSession = true;

    // ── Master timeline ───────────────────────────────────────────────────
    _master = AnimationController(
      vsync: this,
      duration: widget.minimumDuration,
    );

    // ── Exit controller ───────────────────────────────────────────────────
    _exit = AnimationController(
      vsync: this,
      duration: widget.exitDuration,
    );

    // ── Interval animations ───────────────────────────────────────────────

    _bgFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.0, 0.08, curve: Curves.easeOut),
      ),
    );

    _nameReveal = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.05, 0.42, curve: CinematicCurves.revealDecel),
      ),
    );

    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.32, 0.55, curve: CinematicCurves.easeInOutCinematic),
      ),
    );

    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.10, 0.78, curve: CinematicCurves.easeInOutCinematic),
      ),
    );

    _exitReveal = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _exit,
        curve: CinematicCurves.dramaticEntrance,
      ),
    );

    _exit.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _preloaderDone = true);
        widget.onLoadingComplete?.call();
      }
    });

    // Start the sequence
    _master.forward().then((_) {
      setState(() => _showContent = true);
      // Allow one frame for the child to layout before the reveal
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _exit.forward();
      });
    });
  }

  @override
  void dispose() {
    if (!CinematicPreloader._hasPlayedThisSession ||
        _master.duration != null) {
      // Only dispose if they were initialised
      if (!_preloaderDone || _master.duration != null) {
        try {
          _master.dispose();
          _exit.dispose();
        } catch (_) {
          // Controllers may not have been initialised if session flag was set.
        }
      }
    }
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Already played — passthrough.
    if (_preloaderDone && _showContent) {
      return widget.child;
    }

    // Skip path (shouldn't happen, but defensive).
    if (_preloaderDone) {
      return widget.child;
    }

    return Stack(
      children: [
        // Main content sits behind, ready for the reveal
        if (_showContent) Positioned.fill(child: widget.child),

        // Exit reveal clips the preloader away
        AnimatedBuilder(
          animation: _exit,
          builder: (_, __) {
            if (_exitReveal.value >= 1.0) return const SizedBox.shrink();

            // Inverse clip: we clip the *preloader* with an inverted circle
            return _InverseCircleClip(
              progress: _exitReveal.value,
              child: _buildPreloaderSurface(context),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPreloaderSurface(BuildContext context) =>
    AnimatedBuilder(
      animation: _master,
      builder: (_, __) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.backgroundDark
                    .withValues(alpha: _bgFade.value),
                AppColors.background
                    .withValues(alpha: _bgFade.value),
                const Color(0xFF0A0520)
                    .withValues(alpha: _bgFade.value),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Layer 1: Ambient particles
              Positioned.fill(
                child: Opacity(
                  opacity: _bgFade.value,
                  child: const PreloaderParticles(
                    particleCount: 40,
                    color: AppColors.heroAccent,
                  ),
                ),
              ),

              // Layer 2: Film grain
              Positioned.fill(
                child: Opacity(
                  opacity: _bgFade.value * 0.6,
                  child: const PreloaderFilmGrain(opacity: 0.025),
                ),
              ),

              // Layer 3: Vignette
              Positioned.fill(
                child: Opacity(
                  opacity: _bgFade.value,
                  child: const _Vignette(),
                ),
              ),

              // Layer 4: Center content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name reveal
                    LetterStaggerAnimation(
                      text: widget.displayName,
                      animation: _nameReveal,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: _responsiveFontSize(context),
                        fontWeight: FontWeight.w800,
                        letterSpacing: _responsiveLetterSpacing(context),
                        color: AppColors.textBright,
                        height: 1.0,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Accent line
                    _AnimatedLine(animation: _nameReveal),

                    const SizedBox(height: 20),

                    // Tagline
                    Opacity(
                      opacity: _taglineFade.value,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1 - _taglineFade.value)),
                        child: Text(
                          widget.tagline,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 3,
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Progress bar
                    Opacity(
                      opacity: _progressAnim.value > 0 ? 1.0 : 0.0,
                      child: GlowProgressBar(
                        progress: _progressAnim.value,
                        width: _responsiveBarWidth(context),
                        height: 1.5,
                        color: AppColors.heroAccent,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Percentage counter
                    Opacity(
                      opacity: _progressAnim.value > 0 ? 1.0 : 0.0,
                      child: PercentageCounter(
                        animation: _progressAnim,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2,
                          color: AppColors.heroAccent.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

  // ── Responsive helpers ───────────────────────────────────────────────────

  double _responsiveFontSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 480) return 24;
    if (width < 768) return 32;
    return 42;
  }

  double _responsiveLetterSpacing(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 480) return 4;
    if (width < 768) return 6;
    return 10;
  }

  double _responsiveBarWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 480) return 160;
    if (width < 768) return 200;
    return 240;
  }
}

// ---------------------------------------------------------------------------
// Internal helper widgets
// ---------------------------------------------------------------------------

/// Draws a thin accent line that grows horizontally in sync with the name.
class _AnimatedLine extends StatelessWidget {
  const _AnimatedLine({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (_, __) {
      final width = 60.0 * animation.value;
      return Container(
        width: width,
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.heroAccent.withValues(alpha: 0.0),
              AppColors.heroAccent.withValues(alpha: animation.value),
              AppColors.heroAccent.withValues(alpha: 0.0),
            ],
          ),
        ),
      );
    },
  );
}

/// Radial vignette overlay for cinematic depth.
class _Vignette extends StatelessWidget {
  const _Vignette();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.4),
          ],
          stops: const [0.4, 1.0],
        ),
      ),
    ),
  );
}

/// Clips the child to everything *outside* an expanding circle,
/// effectively "eating away" the preloader from the center.
class _InverseCircleClip extends StatelessWidget {
  const _InverseCircleClip({
    required this.progress,
    required this.child,
  });

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return child;
    if (progress >= 1) return const SizedBox.shrink();

    return ClipPath(
      clipper: _InverseCircleClipper(progress),
      child: child,
    );
  }
}

class _InverseCircleClipper extends CustomClipper<Path> {
  _InverseCircleClipper(this.progress);
  final double progress;

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(
      (size.width / 2) * (size.width / 2) +
          (size.height / 2) * (size.height / 2),
    );
    final radius = maxRadius * progress;

    // Full rect minus the expanding circle
    final outer = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    return Path.combine(PathOperation.difference, outer, hole);
  }

  @override
  bool shouldReclip(_InverseCircleClipper old) => progress != old.progress;
}
