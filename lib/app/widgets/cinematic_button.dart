import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';

/// Cinematic CTA button — custom border draw, no Material.
///
/// [isPrimary] toggles between filled accent (primary) and outline (secondary).
class CinematicButton extends StatefulWidget {
  const CinematicButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  State<CinematicButton> createState() => _CinematicButtonState();
}

class _CinematicButtonState extends State<CinematicButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.label,
    child: GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) => setState(() => _pressed = false),
    onTapCancel: () => setState(() => _pressed = false),
    behavior: HitTestBehavior.translucent,
    child: AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: AppDurations.microFast,
      curve: CinematicCurves.hoverLift,
      child: CinematicFocusable(
        onTap: widget.onTap,
        onHoverChanged: (h) => setState(() => _hovered = h),
        child: AnimatedContainer(
            duration: AppDurations.buttonHover,
            curve: CinematicCurves.hoverLift,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: widget.isPrimary
                ? BoxDecoration(
                    color: _hovered
                        ? AppColors.accent.withValues(alpha: 0.9)
                        : AppColors.accent,
                    border: Border.all(
                      color: _hovered
                          ? AppColors.accent
                          : AppColors.accent.withValues(alpha: 0.8),
                      width: 1,
                    ),
                    boxShadow: _hovered
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              blurRadius: 16,
                            ),
                          ]
                        : [],
                  )
                : BoxDecoration(
                    color: _hovered
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.transparent,
                    border: Border.all(
                      color: _hovered
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
            child: Text(
              widget.label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: widget.isPrimary
                    ? AppColors.white
                    : (_hovered ? AppColors.white : AppColors.textPrimary),
                letterSpacing: 2,
              ),
          ),
        ),
      ),
    ),
  ),
  );
}
