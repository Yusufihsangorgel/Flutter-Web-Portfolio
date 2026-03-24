import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SectionHeader — premium animated section title with scroll-triggered reveal
// ─────────────────────────────────────────────────────────────────────────────

/// Alignment variant for [SectionHeader].
enum SectionHeaderAlignment { left, center, right }

/// A cinematic section header with animated number watermark, per-character
/// title reveal, subtitle fade, and accent line draw.
///
/// Usage:
/// ```dart
/// SectionHeader.left(
///   number: '01',
///   title: 'About Me',
///   subtitle: 'Get to know my story',
///   accent: AppColors.aboutAccent,
/// )
/// ```
class SectionHeader extends StatefulWidget {
  /// Left-aligned header (default).
  const SectionHeader.left({
    super.key,
    required this.number,
    required this.title,
    required this.accent,
    this.subtitle,
    this.icon,
    this.numberFontSize = 120,
    this.titleStyle,
  }) : alignment = SectionHeaderAlignment.left;

  /// Center-aligned header.
  const SectionHeader.center({
    super.key,
    required this.number,
    required this.title,
    required this.accent,
    this.subtitle,
    this.icon,
    this.numberFontSize = 120,
    this.titleStyle,
  }) : alignment = SectionHeaderAlignment.center;

  /// Right-aligned header.
  const SectionHeader.right({
    super.key,
    required this.number,
    required this.title,
    required this.accent,
    this.subtitle,
    this.icon,
    this.numberFontSize = 120,
    this.titleStyle,
  }) : alignment = SectionHeaderAlignment.right;

  /// Two-digit section number, e.g. `'01'`.
  final String number;

  /// Main title text.
  final String title;

  /// Optional subtitle/description displayed below the title.
  final String? subtitle;

  /// Scene accent color used for the number tint, accent line, and glow.
  final Color accent;

  /// Optional icon rendered next to the title.
  final IconData? icon;

  /// Font size for the large background number watermark. Defaults to 120.
  final double numberFontSize;

  /// Override the default title text style.
  final TextStyle? titleStyle;

  /// Layout alignment.
  final SectionHeaderAlignment alignment;

  @override
  State<SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<SectionHeader>
    with TickerProviderStateMixin {
  // Controllers ----------------------------------------------------------
  late final AnimationController _numberController;
  late final AnimationController _titleController;
  late final AnimationController _subtitleController;
  late final AnimationController _lineController;

  // Animations -----------------------------------------------------------
  late final Animation<double> _numberOpacity;
  late final Animation<Offset> _numberSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _lineProgress;

  // Scroll visibility ----------------------------------------------------
  bool _triggered = false;
  ScrollPosition? _scrollPosition;

  // Character stagger timing
  static const _charStagger = Duration(milliseconds: 40);
  static const _charDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();

    // Number watermark
    _numberController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );
    final numberCurved = CurvedAnimation(
      parent: _numberController,
      curve: CinematicCurves.dramaticEntrance,
    );
    _numberOpacity = Tween<double>(begin: 0, end: 1).animate(numberCurved);
    _numberSlide = Tween<Offset>(
      begin: const Offset(-40, 0),
      end: Offset.zero,
    ).animate(numberCurved);

    // Title — controller duration covers full stagger window
    final titleTotalMs =
        _charDuration.inMilliseconds +
        (_charStagger.inMilliseconds * widget.title.length);
    _titleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: titleTotalMs),
    );

    // Subtitle
    _subtitleController = AnimationController(
      vsync: this,
      duration: AppDurations.entrance,
    );
    _subtitleOpacity = CurvedAnimation(
      parent: _subtitleController,
      curve: Curves.easeOut,
    );

    // Accent line
    _lineController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );
    _lineProgress = CurvedAnimation(
      parent: _lineController,
      curve: CinematicCurves.textReveal,
    );

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
    _numberController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _lineController.dispose();
    super.dispose();
  }

  void _checkVisibility() {
    if (_triggered || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final pos = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.sizeOf(context).height;

    if (pos.dy < screenH * 0.85 && pos.dy > -box.size.height) {
      _triggered = true;
      _scrollPosition?.removeListener(_checkVisibility);
      _startSequence();
    }
  }

  Future<void> _startSequence() async {
    // 1. Number slides in
    _numberController.forward();

    // 2. Title characters begin after a short overlap
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _titleController.forward();

    // 3. Subtitle fades in after title completes
    await Future<void>.delayed(
      Duration(
        milliseconds:
            _titleController.duration!.inMilliseconds -
            _charDuration.inMilliseconds +
            200,
      ),
    );
    if (!mounted) return;
    _subtitleController.forward();

    // 4. Line draws shortly after subtitle starts
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _lineController.forward();
  }

  // Helpers for per-character animation ----------------------------------

  /// Returns a 0..1 progress value for the character at [index] given the
  /// controller's overall progress.
  double _charProgress(int index, double controllerValue) {
    final totalMs = _titleController.duration!.inMilliseconds;
    final startMs = _charStagger.inMilliseconds * index;
    final endMs = startMs + _charDuration.inMilliseconds;

    final currentMs = controllerValue * totalMs;
    if (currentMs <= startMs) return 0;
    if (currentMs >= endMs) return 1;
    return ((currentMs - startMs) / _charDuration.inMilliseconds).clamp(0, 1);
  }

  CrossAxisAlignment get _crossAxis {
    switch (widget.alignment) {
      case SectionHeaderAlignment.left:
        return CrossAxisAlignment.start;
      case SectionHeaderAlignment.center:
        return CrossAxisAlignment.center;
      case SectionHeaderAlignment.right:
        return CrossAxisAlignment.end;
    }
  }

  Alignment get _numberAlign {
    switch (widget.alignment) {
      case SectionHeaderAlignment.left:
        return Alignment.centerLeft;
      case SectionHeaderAlignment.center:
        return Alignment.center;
      case SectionHeaderAlignment.right:
        return Alignment.centerRight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleBase =
        widget.titleStyle ??
        AppTypography.h1.copyWith(
          color: isDark ? AppColors.textBright : AppColors.lightTextBright,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Stack(
        children: [
          // ── Large number watermark ──────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _numberController,
              builder: (_, __) {
                return Transform.translate(
                  offset: _numberSlide.value,
                  child: Align(
                    alignment: _numberAlign,
                    child: Opacity(
                      opacity: _numberOpacity.value * 0.05,
                      child: Text(
                        widget.number,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: widget.numberFontSize,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          color: widget.accent,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Foreground content ──────────────────────────────────────
          Column(
            crossAxisAlignment: _crossAxis,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title row (icon + per-character reveal)
              _buildTitleRow(titleBase),

              const SizedBox(height: 12),

              // Accent line with glow
              _buildAccentLine(),

              // Subtitle
              if (widget.subtitle != null) ...[
                const SizedBox(height: 16),
                _buildSubtitle(isDark),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleRow(TextStyle titleBase) {
    return AnimatedBuilder(
      animation: _titleController,
      builder: (_, __) {
        final chars = widget.title.characters.toList();
        final children = <Widget>[];

        // Optional icon
        if (widget.icon != null) {
          final iconProgress = _charProgress(0, _titleController.value);
          final curve = CinematicCurves.dramaticEntrance;
          final t = curve.transform(iconProgress);
          children.add(
            Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - t)),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    widget.icon,
                    color: widget.accent,
                    size: (titleBase.fontSize ?? 32) * 0.9,
                  ),
                ),
              ),
            ),
          );
        }

        // Per-character animated text
        for (var i = 0; i < chars.length; i++) {
          final p = _charProgress(i, _titleController.value);
          final curve = CinematicCurves.dramaticEntrance;
          final t = curve.transform(p);

          children.add(
            Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - t)),
                child: Text(chars[i], style: titleBase),
              ),
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: children,
        );
      },
    );
  }

  Widget _buildAccentLine() {
    return AnimatedBuilder(
      animation: _lineController,
      builder: (_, __) {
        final progress = _lineProgress.value;
        return Row(
          mainAxisSize:
              widget.alignment == SectionHeaderAlignment.center
                  ? MainAxisSize.min
                  : MainAxisSize.max,
          children: [
            // Leading decorative dot
            _buildDot(progress),
            const SizedBox(width: 8),

            // Animated line
            if (widget.alignment != SectionHeaderAlignment.center)
              Expanded(child: _buildLine(progress))
            else
              SizedBox(width: 120 * progress, child: _buildLine(progress)),

            const SizedBox(width: 8),
            // Trailing decorative dash
            _buildDash(progress),
          ],
        );
      },
    );
  }

  Widget _buildLine(double progress) {
    return ClipRect(
      child: Align(
        alignment:
            widget.alignment == SectionHeaderAlignment.right
                ? Alignment.centerRight
                : Alignment.centerLeft,
        widthFactor: progress.clamp(0, 1),
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.accent,
                widget.accent.withValues(alpha: 0.3),
              ],
              begin:
                  widget.alignment == SectionHeaderAlignment.right
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
              end:
                  widget.alignment == SectionHeaderAlignment.right
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.6 * progress),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(double progress) {
    return Opacity(
      opacity: progress,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.accent.withValues(alpha: 0.5 * progress),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDash(double progress) {
    return Opacity(
      opacity: progress,
      child: Container(
        width: 16,
        height: 2,
        decoration: BoxDecoration(
          color: widget.accent.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildSubtitle(bool isDark) {
    return FadeTransition(
      opacity: _subtitleOpacity,
      child: Text(
        widget.subtitle!,
        style: AppTypography.body.copyWith(
          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
        ),
        textAlign:
            widget.alignment == SectionHeaderAlignment.center
                ? TextAlign.center
                : widget.alignment == SectionHeaderAlignment.right
                ? TextAlign.right
                : TextAlign.left,
      ),
    );
  }
}
