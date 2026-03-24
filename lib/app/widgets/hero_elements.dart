import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';


// =============================================================================
//  1. HeroTitle — Dramatic letter-by-letter entrance with spring overshoot
// =============================================================================

/// Each letter slides up from below with slight rotation, blur-to-sharp,
/// and spring physics. After all letters land, a subtle scale pulse fires.
/// The text renders with a gradient overlay (not flat color).
class HeroTitle extends StatefulWidget {
  const HeroTitle({
    super.key,
    required this.text,
    this.style,
    this.delay = Duration.zero,
    this.letterStagger = const Duration(milliseconds: 30),
    this.textAlign = TextAlign.center,
  });

  final String text;
  final TextStyle? style;
  final Duration delay;
  final Duration letterStagger;
  final TextAlign textAlign;

  @override
  State<HeroTitle> createState() => _HeroTitleState();
}

class _HeroTitleState extends State<HeroTitle> with TickerProviderStateMixin {
  final List<AnimationController> _letterCtrls = [];
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;
  bool _started = false;

  @override
  void initState() {
    super.initState();

    // Pulse controller — fires once after all letters land
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.02), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // One controller per letter — spring simulation via overshoot curve
    for (var i = 0; i < widget.text.length; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      _letterCtrls.add(ctrl);
    }

    Future.delayed(widget.delay, _startSequence);
  }

  void _startSequence() {
    if (!mounted) return;
    _started = true;
    for (var i = 0; i < _letterCtrls.length; i++) {
      Future.delayed(widget.letterStagger * i, () {
        if (!mounted) return;
        _letterCtrls[i].forward();
      });
    }
    // Fire pulse after last letter finishes
    final totalDelay =
        widget.letterStagger * _letterCtrls.length +
        const Duration(milliseconds: 600);
    Future.delayed(totalDelay, () {
      if (mounted) _pulseCtrl.forward();
    });
  }

  @override
  void dispose() {
    for (final c in _letterCtrls) {
      c.dispose();
    }
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ??
        GoogleFonts.spaceGrotesk(
          fontSize: 72,
          fontWeight: FontWeight.w800,
          color: AppColors.textBright,
          letterSpacing: -4,
          height: 1.0,
        );

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) => Transform.scale(
        scale: _started ? _pulseScale.value : 1.0,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                AppColors.textBright,
                Color(0xFFB8C5D6),
                AppColors.heroAccent,
              ],
              stops: [0.0, 0.6, 1.0],
            ).createShader(bounds),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.text.length, (i) {
                final char = widget.text[i];
                if (char == ' ') {
                  return SizedBox(width: baseStyle.fontSize! * 0.3);
                }
                return _AnimatedLetter(
                  char: char,
                  controller: _letterCtrls[i],
                  style: baseStyle,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedLetter extends StatelessWidget {
  const _AnimatedLetter({
    required this.char,
    required this.controller,
    required this.style,
  });

  final String char;
  final AnimationController controller;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    // Spring-like overshoot curve
    const curve = ElasticOutCurve(0.8);
    final progress = CurvedAnimation(parent: controller, curve: curve);

    // Slide from 40px below
    final slideUp = Tween<double>(begin: 40.0, end: 0.0).animate(progress);
    // Slight rotation: -8° to 0°
    final rotate =
        Tween<double>(begin: -0.14, end: 0.0).animate(progress);
    // Opacity
    final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    // Blur: 6px → 0px
    final blur = Tween<double>(begin: 6.0, end: 0.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, slideUp.value),
        child: Transform.rotate(
          angle: rotate.value,
          child: Opacity(
            opacity: opacity.value.clamp(0.0, 1.0),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: blur.value,
                sigmaY: blur.value,
              ),
              child: Text(char, style: style),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
//  2. HeroSubtitle — Role cycling with morph/dissolve transitions
// =============================================================================

/// Static "I'm a " prefix followed by cycling role text that morphs between
/// values with dissolve-out / assemble-in per character. Blinking pipe cursor.
class HeroSubtitle extends StatefulWidget {
  const HeroSubtitle({
    super.key,
    required this.roles,
    this.prefix = "I'm a ",
    this.style,
    this.delay = Duration.zero,
    this.displayDuration = const Duration(seconds: 3),
    this.morphDuration = const Duration(milliseconds: 800),
    this.cursorColor,
  });

  final List<String> roles;
  final String prefix;
  final TextStyle? style;
  final Duration delay;
  final Duration displayDuration;
  final Duration morphDuration;
  final Color? cursorColor;

  @override
  State<HeroSubtitle> createState() => _HeroSubtitleState();
}

class _HeroSubtitleState extends State<HeroSubtitle>
    with TickerProviderStateMixin {
  late AnimationController _morphCtrl;
  late AnimationController _cursorCtrl;
  late AnimationController _entranceCtrl;

  int _currentIndex = 0;
  int _nextIndex = 1;
  bool _isMorphing = false;
  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _morphCtrl = AnimationController(
      vsync: this,
      duration: widget.morphDuration,
    );
    _morphCtrl.addStatusListener(_onMorphComplete);

    _cursorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    Future.delayed(widget.delay, () {
      if (!mounted) return;
      _entranceCtrl.forward();
      _scheduleMorph();
    });
  }

  void _scheduleMorph() {
    Future.delayed(widget.displayDuration, () {
      if (!mounted || widget.roles.length <= 1) return;
      _nextIndex = (_currentIndex + 1) % widget.roles.length;
      _isMorphing = true;
      _morphCtrl.forward(from: 0.0);
    });
  }

  void _onMorphComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _currentIndex = _nextIndex;
        _isMorphing = false;
      });
      _scheduleMorph();
    }
  }

  @override
  void dispose() {
    _morphCtrl.removeStatusListener(_onMorphComplete);
    _morphCtrl.dispose();
    _cursorCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ??
        GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          letterSpacing: 2,
        );

    final cursorColor = widget.cursorColor ?? AppColors.heroAccent;

    return AnimatedBuilder(
      animation: Listenable.merge([_entranceCtrl, _morphCtrl, _cursorCtrl]),
      builder: (context, _) {
        final entranceOpacity = CurvedAnimation(
          parent: _entranceCtrl,
          curve: Curves.easeOut,
        ).value;

        return Opacity(
          opacity: entranceOpacity,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - entranceOpacity)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Static prefix
                Text(widget.prefix, style: baseStyle),
                // Morphing role text
                _buildMorphingText(baseStyle),
                // Blinking cursor
                Opacity(
                  opacity: _cursorCtrl.value,
                  child: Text(
                    '|',
                    style: baseStyle.copyWith(
                      color: cursorColor,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMorphingText(TextStyle style) {
    if (!_isMorphing) {
      final text = widget.roles.isNotEmpty
          ? widget.roles[_currentIndex % widget.roles.length]
          : '';
      return _buildCharRow(text, style, 1.0, false);
    }

    final currentText = widget.roles[_currentIndex % widget.roles.length];
    final nextText = widget.roles[_nextIndex % widget.roles.length];
    final progress = _morphCtrl.value;

    // First half: current dissolves out. Second half: next assembles in.
    if (progress < 0.5) {
      final dissolve = progress * 2.0; // 0→1
      return _buildCharRow(currentText, style, 1.0 - dissolve, true);
    } else {
      final assemble = (progress - 0.5) * 2.0; // 0→1
      return _buildCharRow(nextText, style, assemble, false);
    }
  }

  Widget _buildCharRow(
      String text, TextStyle style, double progress, bool dissolving) {
    final rng = math.Random(text.hashCode);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(text.length, (i) {
        // Each character has a slightly offset progress
        final charDelay = i / (text.length.clamp(1, 999));
        final charProgress =
            ((progress - charDelay * 0.3) / 0.7).clamp(0.0, 1.0);

        final angle = dissolving
            ? (1.0 - charProgress) * (rng.nextDouble() - 0.5) * 0.5
            : (1.0 - charProgress) * (rng.nextDouble() - 0.5) * 0.5;

        final yOffset = dissolving
            ? (1.0 - charProgress) * (rng.nextDouble() * 20 - 10)
            : (1.0 - charProgress) * (rng.nextDouble() * 20 - 10);

        final xOffset = dissolving
            ? (1.0 - charProgress) * (rng.nextDouble() * 12 - 6)
            : (1.0 - charProgress) * (rng.nextDouble() * 12 - 6);

        return Transform.translate(
          offset: Offset(xOffset, yOffset),
          child: Transform.rotate(
            angle: angle,
            child: Opacity(
              opacity: charProgress.clamp(0.0, 1.0),
              child: Text(text[i], style: style),
            ),
          ),
        );
      }),
    );
  }
}

// =============================================================================
//  3. HeroParticleAvatar — Profile photo with orbiting particle border
// =============================================================================

/// Circular profile image ringed by orbiting glowing particles.
/// On hover the ring expands and the photo scales up.
class HeroParticleAvatar extends StatefulWidget {
  const HeroParticleAvatar({
    super.key,
    required this.imageProvider,
    this.radius = 80,
    this.particleCount = 36,
    this.particleColor,
    this.orbitSpeed = 0.3,
  });

  final ImageProvider imageProvider;
  final double radius;
  final int particleCount;
  final Color? particleColor;

  /// Revolutions per second.
  final double orbitSpeed;

  @override
  State<HeroParticleAvatar> createState() => _HeroParticleAvatarState();
}

class _HeroParticleAvatarState extends State<HeroParticleAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final particleColor = widget.particleColor ?? AppColors.heroAccent;
    final totalSize = (widget.radius + 30) * 2;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        width: totalSize,
        height: totalSize,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => Stack(
            alignment: Alignment.center,
            children: [
              // Particle ring via CustomPaint
              CustomPaint(
                size: Size(totalSize, totalSize),
                painter: _ParticleRingPainter(
                  progress: _ctrl.value,
                  particleCount: widget.particleCount,
                  baseRadius: widget.radius + 14,
                  expandedRadius: widget.radius + 28,
                  isHovered: _hovered,
                  color: particleColor,
                  orbitSpeed: widget.orbitSpeed,
                ),
              ),
              // Profile photo
              AnimatedScale(
                scale: _hovered ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: widget.radius * 2,
                  height: widget.radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: widget.imageProvider,
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: particleColor.withValues(alpha: 0.25),
                        blurRadius: _hovered ? 30 : 16,
                        spreadRadius: _hovered ? 4 : 0,
                      ),
                    ],
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

class _ParticleRingPainter extends CustomPainter {
  _ParticleRingPainter({
    required this.progress,
    required this.particleCount,
    required this.baseRadius,
    required this.expandedRadius,
    required this.isHovered,
    required this.color,
    required this.orbitSpeed,
  });

  final double progress;
  final int particleCount;
  final double baseRadius;
  final double expandedRadius;
  final bool isHovered;
  final Color color;
  final double orbitSpeed;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = isHovered ? expandedRadius : baseRadius;
    final rotationAngle = progress * 2 * math.pi * orbitSpeed;

    for (var i = 0; i < particleCount; i++) {
      final baseAngle = (i / particleCount) * 2 * math.pi;
      // Slight per-particle wobble for organic feel
      final wobble = math.sin(progress * 2 * math.pi * 3 + i * 0.7) * 3.0;
      final r = radius + wobble;
      final angle = baseAngle + rotationAngle;

      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      // Particle size varies subtly
      final dotRadius = 1.5 + math.sin(i * 1.3 + progress * 8) * 0.8;

      // Glow trail — larger, semi-transparent circle behind
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(x, y), dotRadius * 3.5, glowPaint);

      // Core dot
      final dotPaint = Paint()
        ..color = color.withValues(
            alpha: 0.6 + 0.4 * math.sin(i * 0.8 + progress * 6).abs());
      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_ParticleRingPainter old) => true;
}

// =============================================================================
//  4. HeroCTAButtons — Staggered entrance, liquid fill hover, magnetic pull
// =============================================================================

/// Two call-to-action buttons with spring entrance, liquid-fill hover effect,
/// and a sliding arrow icon. Responsive: stacks vertically on mobile.
class HeroCTAButtons extends StatefulWidget {
  const HeroCTAButtons({
    super.key,
    required this.onViewWork,
    required this.onGetInTouch,
    this.viewWorkLabel = 'View My Work',
    this.getInTouchLabel = 'Get In Touch',
    this.delay = Duration.zero,
  });

  final VoidCallback onViewWork;
  final VoidCallback onGetInTouch;
  final String viewWorkLabel;
  final String getInTouchLabel;
  final Duration delay;

  @override
  State<HeroCTAButtons> createState() => _HeroCTAButtonsState();
}

class _HeroCTAButtonsState extends State<HeroCTAButtons>
    with TickerProviderStateMixin {
  late AnimationController _btn1Ctrl;
  late AnimationController _btn2Ctrl;

  @override
  void initState() {
    super.initState();
    _btn1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _btn2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    Future.delayed(widget.delay, () {
      if (!mounted) return;
      _btn1Ctrl.forward();
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) _btn2Ctrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _btn1Ctrl.dispose();
    _btn2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < Breakpoints.mobile;

    final children = [
      _SpringButton(
        controller: _btn1Ctrl,
        child: _LiquidFillButton(
          label: widget.viewWorkLabel,
          onTap: widget.onViewWork,
          isPrimary: true,
        ),
      ),
      if (isMobile) const SizedBox(height: 16) else const SizedBox(width: 20),
      _SpringButton(
        controller: _btn2Ctrl,
        child: _LiquidFillButton(
          label: widget.getInTouchLabel,
          onTap: widget.onGetInTouch,
          isPrimary: false,
        ),
      ),
    ];

    if (isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _SpringButton extends StatelessWidget {
  const _SpringButton({
    required this.controller,
    required this.child,
  });

  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final slide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: const ElasticOutCurve(0.85)),
    );
    final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Opacity(
        opacity: opacity.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, slide.value),
          child: child,
        ),
      ),
    );
  }
}

/// Button with liquid fill from left on hover and sliding arrow icon.
class _LiquidFillButton extends StatefulWidget {
  const _LiquidFillButton({
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  State<_LiquidFillButton> createState() => _LiquidFillButtonState();
}

class _LiquidFillButtonState extends State<_LiquidFillButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _fillCtrl;
  bool _hovered = false;
  Offset _mousePos = Offset.zero;

  @override
  void initState() {
    super.initState();
    _fillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _fillCtrl.dispose();
    super.dispose();
  }

  void _onEnter(PointerEnterEvent e) {
    setState(() => _hovered = true);
    _fillCtrl.forward();
  }

  void _onExit(PointerExitEvent e) {
    setState(() => _hovered = false);
    _fillCtrl.reverse();
  }

  void _onHover(PointerHoverEvent e) {
    setState(() => _mousePos = e.localPosition);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textBright : AppColors.lightTextBright;
    final borderColor = widget.isPrimary
        ? AppColors.heroAccent
        : (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.12));

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      onHover: _onHover,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _fillCtrl,
          builder: (context, _) {
            // Magnetic pull: slight offset toward cursor
            final magneticOffset = _hovered
                ? Offset(
                    (_mousePos.dx - 100) * 0.03,
                    (_mousePos.dy - 25) * 0.03,
                  )
                : Offset.zero;

            final fillProgress = CurvedAnimation(
              parent: _fillCtrl,
              curve: Curves.easeOutCubic,
            ).value;

            return Transform.translate(
              offset: magneticOffset,
              child: CustomPaint(
                painter: _LiquidFillPainter(
                  progress: fillProgress,
                  fillColor: widget.isPrimary
                      ? AppColors.heroAccent
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06)),
                  borderColor: borderColor,
                  isPrimary: widget.isPrimary,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.isPrimary
                              ? (fillProgress > 0.3
                                  ? AppColors.white
                                  : textColor)
                              : (_hovered
                                  ? (isDark
                                      ? AppColors.textBright
                                      : AppColors.lightTextBright)
                                  : (isDark
                                      ? AppColors.textPrimary
                                      : AppColors.lightTextPrimary)),
                          letterSpacing: 2,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: _hovered ? 24 : 0,
                        child: AnimatedOpacity(
                          opacity: _hovered ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: widget.isPrimary
                                  ? AppColors.white
                                  : textColor,
                            ),
                          ),
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
    );
  }
}

class _LiquidFillPainter extends CustomPainter {
  _LiquidFillPainter({
    required this.progress,
    required this.fillColor,
    required this.borderColor,
    required this.isPrimary,
  });

  final double progress;
  final Color fillColor;
  final Color borderColor;
  final bool isPrimary;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.zero);

    // Liquid fill from left — with a slight wave on the leading edge
    if (progress > 0) {
      final fillWidth = size.width * progress;
      final wavePath = Path();
      wavePath.moveTo(0, 0);
      wavePath.lineTo(fillWidth - 4, 0);

      // Subtle wave on the leading edge
      final waveAmplitude = 3.0 * (1.0 - progress); // fades as fill completes
      for (var y = 0.0; y <= size.height; y += 2) {
        final wave =
            math.sin(y * 0.15 + progress * math.pi * 4) * waveAmplitude;
        wavePath.lineTo(fillWidth + wave, y);
      }
      wavePath.lineTo(0, size.height);
      wavePath.close();

      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawPath(
        wavePath,
        Paint()..color = fillColor,
      );
      canvas.restore();
    }

    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = isPrimary
            ? fillColor
            : borderColor,
    );

    // Glow on hover for primary
    if (isPrimary && progress > 0.5) {
      canvas.drawRRect(
        rrect.inflate(1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = fillColor.withValues(alpha: 0.3 * progress)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12),
      );
    }
  }

  @override
  bool shouldRepaint(_LiquidFillPainter old) =>
      old.progress != progress || old.isPrimary != isPrimary;
}

// =============================================================================
//  5. HeroScrollIndicator — Animated scroll prompt with mouse icon
// =============================================================================

/// "Scroll Down" text + bouncing arrow + mouse icon with scrolling wheel.
/// Fades out when [scrollOffset] exceeds a threshold.
class HeroScrollIndicator extends StatefulWidget {
  const HeroScrollIndicator({
    super.key,
    this.delay = Duration.zero,
    this.scrollOffset = 0.0,
    this.fadeThreshold = 100.0,
  });

  final Duration delay;

  /// Current scroll offset — used to fade out after hero.
  final double scrollOffset;

  /// Scroll offset at which indicator fully disappears.
  final double fadeThreshold;

  @override
  State<HeroScrollIndicator> createState() => _HeroScrollIndicatorState();
}

class _HeroScrollIndicatorState extends State<HeroScrollIndicator>
    with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late AnimationController _bounceCtrl;
  late AnimationController _wheelCtrl;
  late Animation<double> _bounceY;
  late Animation<double> _wheelY;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _bounceY = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );

    _wheelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _wheelY = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _wheelCtrl, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _bounceCtrl.dispose();
    _wheelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrollFade =
        (1.0 - (widget.scrollOffset / widget.fadeThreshold)).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.4);

    return AnimatedBuilder(
      animation: Listenable.merge([_entranceCtrl, _bounceCtrl, _wheelCtrl]),
      builder: (context, _) {
        final entrance = CurvedAnimation(
          parent: _entranceCtrl,
          curve: Curves.easeOut,
        ).value;

        return Opacity(
          opacity: entrance * scrollFade,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - entrance)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mouse icon
                _buildMouseIcon(fgColor),
                const SizedBox(height: 12),
                // "Scroll Down" label
                Text(
                  'Scroll Down',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: fgColor,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 6),
                // Bouncing arrow
                Transform.translate(
                  offset: Offset(0, _bounceY.value),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMouseIcon(Color color) {
    return SizedBox(
      width: 22,
      height: 36,
      child: CustomPaint(
        painter: _MouseIconPainter(
          color: color,
          wheelOffset: _wheelY.value,
        ),
      ),
    );
  }
}

class _MouseIconPainter extends CustomPainter {
  _MouseIconPainter({required this.color, required this.wheelOffset});

  final Color color;
  final double wheelOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Mouse body — rounded rectangle
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width / 2),
    );
    canvas.drawRRect(bodyRect, paint);

    // Scroll wheel — small line that moves down
    final wheelTop = 8.0 + wheelOffset * 0.6;
    final wheelPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, wheelTop),
          width: 2.5,
          height: 5,
        ),
        const Radius.circular(1.5),
      ),
      wheelPaint,
    );
  }

  @override
  bool shouldRepaint(_MouseIconPainter old) =>
      old.wheelOffset != wheelOffset || old.color != color;
}

// =============================================================================
//  6. HeroBackground — Layered cinematic background with parallax
// =============================================================================

/// Four-layer background: deep gradient, floating shapes, constellation
/// particles, and vignette. All layers shift with [mousePosition] for parallax.
class HeroBackground extends StatefulWidget {
  const HeroBackground({
    super.key,
    this.mousePosition = const Offset(0.5, 0.5),
    this.gradientColors,
    this.child,
  });

  /// Normalized mouse position (0–1 on each axis). Center is (0.5, 0.5).
  final Offset mousePosition;

  /// Override gradient colors. Defaults to heroGradient palette.
  final List<Color>? gradientColors;

  final Widget? child;

  @override
  State<HeroBackground> createState() => _HeroBackgroundState();
}

class _HeroBackgroundState extends State<HeroBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  // Pre-generated floating shapes
  late List<_FloatingShape> _shapes;
  late List<_ConstellationDot> _dots;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    final rng = math.Random(42);
    _shapes = List.generate(12, (i) => _FloatingShape.random(rng));
    _dots = List.generate(60, (i) => _ConstellationDot.random(rng));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradColors = widget.gradientColors ??
        const [
          AppColors.backgroundDark,
          AppColors.heroGradient1,
          AppColors.heroGradient2,
          AppColors.backgroundDark,
        ];

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        // Parallax offsets from mouse — each layer moves differently
        final mx = (widget.mousePosition.dx - 0.5) * 2;
        final my = (widget.mousePosition.dy - 0.5) * 2;

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1: Deep gradient background
              Transform.translate(
                offset: Offset(mx * 5, my * 5),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        -0.3 + mx * 0.1,
                        -0.2 + my * 0.1,
                      ),
                      radius: 1.4,
                      colors: gradColors,
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              ),

              // Layer 2: Floating geometric shapes (slow drift)
              Transform.translate(
                offset: Offset(mx * 15, my * 15),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _FloatingShapesPainter(
                    shapes: _shapes,
                    time: _ctrl.value,
                  ),
                ),
              ),

              // Layer 3: Constellation particles
              Transform.translate(
                offset: Offset(mx * 25, my * 25),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _ConstellationPainter(
                    dots: _dots,
                    time: _ctrl.value,
                    accentColor: AppColors.heroAccent,
                  ),
                ),
              ),

              // Layer 4: Vignette overlay
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.3, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // Child content on top
              if (widget.child != null) widget.child!,
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
//  Floating geometric shapes data & painter
// ---------------------------------------------------------------------------

class _FloatingShape {
  _FloatingShape({
    required this.x,
    required this.y,
    required this.size,
    required this.rotation,
    required this.speed,
    required this.type,
    required this.opacity,
  });

  factory _FloatingShape.random(math.Random rng) => _FloatingShape(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 20 + rng.nextDouble() * 60,
        rotation: rng.nextDouble() * math.pi * 2,
        speed: 0.2 + rng.nextDouble() * 0.8,
        type: rng.nextInt(3), // 0=triangle, 1=square, 2=circle
        opacity: 0.02 + rng.nextDouble() * 0.06,
      );

  final double x, y, size, rotation, speed, opacity;
  final int type;
}

class _FloatingShapesPainter extends CustomPainter {
  _FloatingShapesPainter({required this.shapes, required this.time});

  final List<_FloatingShape> shapes;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    for (final shape in shapes) {
      final cx = shape.x * size.width;
      final cy = shape.y * size.height;
      // Slow drift
      final driftX = math.sin(time * math.pi * 2 * shape.speed + shape.x * 10) * 30;
      final driftY = math.cos(time * math.pi * 2 * shape.speed * 0.7 + shape.y * 10) * 20;
      final angle = shape.rotation + time * math.pi * 2 * shape.speed * 0.3;

      canvas.save();
      canvas.translate(cx + driftX, cy + driftY);
      canvas.rotate(angle);

      final paint = Paint()
        ..color = AppColors.heroAccent.withValues(alpha: shape.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      switch (shape.type) {
        case 0: // Triangle
          final path = Path()
            ..moveTo(0, -shape.size / 2)
            ..lineTo(shape.size / 2, shape.size / 2)
            ..lineTo(-shape.size / 2, shape.size / 2)
            ..close();
          canvas.drawPath(path, paint);
          break;
        case 1: // Square
          canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero,
                width: shape.size,
                height: shape.size),
            paint,
          );
          break;
        default: // Circle
          canvas.drawCircle(Offset.zero, shape.size / 2, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FloatingShapesPainter old) => true;
}

// ---------------------------------------------------------------------------
//  Constellation particles data & painter
// ---------------------------------------------------------------------------

class _ConstellationDot {
  _ConstellationDot({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.brightness,
  });

  factory _ConstellationDot.random(math.Random rng) => _ConstellationDot(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: 0.8 + rng.nextDouble() * 1.5,
        speed: 0.1 + rng.nextDouble() * 0.5,
        phase: rng.nextDouble() * math.pi * 2,
        brightness: 0.3 + rng.nextDouble() * 0.7,
      );

  final double x, y, radius, speed, phase, brightness;
}

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter({
    required this.dots,
    required this.time,
    required this.accentColor,
  });

  final List<_ConstellationDot> dots;
  final double time;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final positions = <Offset>[];

    // Draw dots and collect positions for line connections
    for (final dot in dots) {
      final px = dot.x * size.width +
          math.sin(time * math.pi * 2 * dot.speed + dot.phase) * 15;
      final py = dot.y * size.height +
          math.cos(time * math.pi * 2 * dot.speed * 0.8 + dot.phase) * 10;
      final pos = Offset(px, py);
      positions.add(pos);

      // Twinkle effect
      final twinkle =
          (math.sin(time * math.pi * 8 * dot.speed + dot.phase) + 1) / 2;
      final alpha = dot.brightness * (0.4 + twinkle * 0.6);

      // Glow
      canvas.drawCircle(
        pos,
        dot.radius * 3,
        Paint()
          ..color = accentColor.withValues(alpha: alpha * 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Core
      canvas.drawCircle(
        pos,
        dot.radius,
        Paint()..color = accentColor.withValues(alpha: alpha * 0.6),
      );
    }

    // Draw connecting lines between nearby dots
    const maxDist = 120.0;
    final linePaint = Paint()
      ..strokeWidth = 0.4
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < positions.length; i++) {
      for (var j = i + 1; j < positions.length; j++) {
        final dist = (positions[i] - positions[j]).distance;
        if (dist < maxDist) {
          final lineAlpha = (1.0 - dist / maxDist) * 0.15;
          linePaint.color = accentColor.withValues(alpha: lineAlpha);
          canvas.drawLine(positions[i], positions[j], linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter old) => true;
}
