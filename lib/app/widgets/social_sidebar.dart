import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

/// Fixed left sidebar with social icon links (GitHub, LinkedIn, Email)
/// and a vertical line below. Brittany Chiang style.
/// Only visible on desktop (>= 900px).
class SocialSidebarLeft extends StatelessWidget {
  const SocialSidebarLeft({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < 900) return const SizedBox.shrink();

    final languageController = Get.find<LanguageController>();

    return Obx(() {
      final data = languageController.cvData['personal_info']
              as Map<String, dynamic>? ??
          <String, dynamic>{};
      final github = (data['github'] as String?) ?? '';
      final linkedin = (data['linkedin'] as String?) ?? '';
      final email = (data['email'] as String?) ?? '';

      return AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: AppDurations.entrance,
        curve: CinematicCurves.revealDecel,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 0.15),
          duration: AppDurations.entrance,
          curve: CinematicCurves.revealDecel,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (github.isNotEmpty)
                _SidebarIcon(
                  icon: Icons.code_rounded,
                  tooltip: languageController.getText('sidebar.github', defaultValue: 'GitHub'),
                  url: github,
                ),
              if (linkedin.isNotEmpty)
                _SidebarIcon(
                  icon: Icons.business_center_outlined,
                  tooltip: languageController.getText('sidebar.linkedin', defaultValue: 'LinkedIn'),
                  url: linkedin,
                ),
              if (email.isNotEmpty)
                _SidebarIcon(
                  icon: Icons.email_outlined,
                  tooltip: languageController.getText('sidebar.email', defaultValue: 'Email'),
                  url: 'mailto:$email',
                ),
              const SizedBox(height: 12),
              const _VerticalLine(),
            ],
          ),
        ),
      );
    });
  }
}

/// Fixed right sidebar with the email address rotated vertically
/// and a vertical line below. Brittany Chiang style.
/// Only visible on desktop (>= 900px).
class SocialSidebarRight extends StatelessWidget {
  const SocialSidebarRight({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < 900) return const SizedBox.shrink();

    final languageController = Get.find<LanguageController>();

    return Obx(() {
      final data = languageController.cvData['personal_info']
              as Map<String, dynamic>? ??
          <String, dynamic>{};
      final email = (data['email'] as String?) ?? '';

      if (email.isEmpty) return const SizedBox.shrink();

      return AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: AppDurations.entrance,
        curve: CinematicCurves.revealDecel,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 0.15),
          duration: AppDurations.entrance,
          curve: CinematicCurves.revealDecel,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RotatedEmailLink(email: email),
              const SizedBox(height: 12),
              const _VerticalLine(),
            ],
          ),
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Sidebar icon button — 20px, subtle gray, brighten on hover
// ---------------------------------------------------------------------------
class _SidebarIcon extends StatefulWidget {
  const _SidebarIcon({
    required this.icon,
    required this.tooltip,
    required this.url,
  });

  final IconData icon;
  final String tooltip;
  final String url;

  @override
  State<_SidebarIcon> createState() => _SidebarIconState();
}

class _SidebarIconState extends State<_SidebarIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const baseColor = AppColors.textSecondary;
    const hoverColor = AppColors.textBright;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: widget.tooltip,
          child: GestureDetector(
            onTap: () async {
              final uri = Uri.parse(widget.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: AnimatedContainer(
              duration: AppDurations.buttonHover,
              curve: CinematicCurves.hoverLift,
              transform: Matrix4.translationValues(
                0,
                _hovered ? -2 : 0,
                0,
              ),
              child: Icon(
                widget.icon,
                size: 20,
                color: _hovered ? hoverColor : baseColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rotated email link with hover underline
// ---------------------------------------------------------------------------
class _RotatedEmailLink extends StatefulWidget {
  const _RotatedEmailLink({required this.email});
  final String email;

  @override
  State<_RotatedEmailLink> createState() => _RotatedEmailLinkState();
}

class _RotatedEmailLinkState extends State<_RotatedEmailLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const baseColor = AppColors.textSecondary;
    const hoverColor = AppColors.textBright;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse('mailto:${widget.email}');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: RotatedBox(
          quarterTurns: 1,
          child: AnimatedContainer(
            duration: AppDurations.buttonHover,
            curve: CinematicCurves.hoverLift,
            transform: Matrix4.translationValues(
              0,
              _hovered ? -2 : 0,
              0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.email,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    letterSpacing: 2,
                    color: _hovered ? hoverColor : baseColor,
                  ),
                ),
                const SizedBox(height: 2),
                // Hover underline that expands from left
                AnimatedContainer(
                  duration: AppDurations.fast,
                  curve: CinematicCurves.hoverLift,
                  height: 1,
                  width: _hovered ? 160 : 0,
                  color: AppColors.accent.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vertical line — 1px wide, ~100px tall, accent at 0.2 opacity
// ---------------------------------------------------------------------------
class _VerticalLine extends StatelessWidget {
  const _VerticalLine();

  @override
  Widget build(BuildContext context) => Container(
      width: 1,
      height: 100,
      color: AppColors.accent.withValues(alpha: 0.2),
    );
}
