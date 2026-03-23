import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_button.dart';
import 'package:flutter_web_portfolio/app/widgets/constellation_particles.dart';

/// 404 Not Found page — cinematic dark theme with constellation particles.
class NotFoundView extends StatelessWidget {
  const NotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final lang = Get.isRegistered<LanguageController>()
        ? Get.find<LanguageController>()
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Constellation particle background
          const Positioned.fill(
            child: ConstellationParticles(particleCount: 60),
          ),
          // Content
          Center(
            child: SizedBox(
              height: screenHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 404 hero text
                  _FadeSlideIn(
                    delay: AppDurations.staggerShort,
                    child: Text(
                      '404',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 160,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                        letterSpacing: -8,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Subtitle
                  _FadeSlideIn(
                    delay: AppDurations.staggerMedium,
                    child: Text(
                      lang?.getText('not_found.subtitle', defaultValue: 'Page not found') ?? 'Page not found',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Go Home button
                  _FadeSlideIn(
                    delay: AppDurations.medium,
                    child: CinematicButton(
                      label: lang?.getText('not_found.go_home', defaultValue: 'Go Home') ?? 'Go Home',
                      isPrimary: true,
                      onTap: () => Get.offAllNamed('/'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple fade + slide-up entrance animation.
class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({required this.child, required this.delay});
  final Widget child;
  final Duration delay;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppDurations.entrance,
    );
    _opacity = CurvedAnimation(
      parent: _ctrl,
      curve: CinematicCurves.revealDecel,
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: CinematicCurves.revealDecel,
    ));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Opacity(
      opacity: _opacity.value,
      child: Transform.translate(
        offset: _offset.value,
        child: widget.child,
      ),
    ),
  );
}
