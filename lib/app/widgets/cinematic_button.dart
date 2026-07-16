import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';

/// Pointer- and keyboard-accessible outlined call-to-action.
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
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) => setState(() => _pressed = false),
    onTapCancel: () => setState(() => _pressed = false),
    behavior: HitTestBehavior.translucent,
    excludeFromSemantics: true,
    child: AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: AppDurations.microFast,
      curve: CinematicCurves.hoverLift,
      child: CinematicFocusable(
        onTap: widget.onTap,
        semanticLabel: widget.label,
        onHoverChanged: (hovered) => setState(() => _hovered = hovered),
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
                            color: AppColors.textBright.withValues(alpha: 0.12),
                            offset: const Offset(4, 4),
                          ),
                        ]
                      : [],
                )
              : BoxDecoration(
                  color: _hovered
                      ? AppColors.textBright.withValues(alpha: 0.06)
                      : Colors.transparent,
                  border: Border.all(
                    color: _hovered
                        ? AppColors.textBright
                        : AppColors.textBright.withValues(alpha: 0.28),
                    width: 1,
                  ),
                ),
          child: Text(
            widget.label,
            style: AppFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.isPrimary ? AppColors.white : AppColors.textBright,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    ),
  );
}
