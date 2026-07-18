import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/motion_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';

/// Pointer- and keyboard-accessible outlined call-to-action.
///
/// [isPrimary] toggles between filled accent (primary) and outline (secondary).
class PortfolioActionButton extends StatefulWidget {
  const PortfolioActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  State<PortfolioActionButton> createState() => _PortfolioActionButtonState();
}

class _PortfolioActionButtonState extends State<PortfolioActionButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => setState(() => _pressed = true),
    onPointerUp: (_) => setState(() => _pressed = false),
    onPointerCancel: (_) => setState(() => _pressed = false),
    behavior: HitTestBehavior.translucent,
    child: AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: AppDurations.microFast,
      curve: MotionCurves.quickOut,
      child: AccessibleAction(
        onTap: widget.onTap,
        semanticLabel: widget.label,
        onHoverChanged: (hovered) => setState(() => _hovered = hovered),
        child: AnimatedContainer(
          duration: AppDurations.buttonHover,
          curve: MotionCurves.quickOut,
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
