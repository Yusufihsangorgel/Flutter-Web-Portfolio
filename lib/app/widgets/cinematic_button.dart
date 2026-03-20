import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';

/// Cinematic CTA button — custom border draw, no Material
class CinematicButton extends StatefulWidget {
  const CinematicButton({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<CinematicButton> createState() => _CinematicButtonState();
}

class _CinematicButtonState extends State<CinematicButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: widget.onTap,
    onHoverChanged: (h) => setState(() => _hovered = h),
    child: AnimatedContainer(
        duration: AppDurations.buttonHover,
        curve: CinematicCurves.hoverLift,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: _hovered
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.transparent,
          border: Border.all(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _hovered ? AppColors.white : AppColors.textPrimary,
            letterSpacing: 2,
          ),
      ),
    ),
  );
}
