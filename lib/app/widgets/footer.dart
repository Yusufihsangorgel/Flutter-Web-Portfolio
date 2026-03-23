import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';

/// Footer with social links pulled from cvData.
class PortfolioFooter extends StatelessWidget {
  const PortfolioFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final languageController = Get.find<LanguageController>();

    return Obx(() {
      final data = languageController.cvData['personal_info'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final name = (data['name'] as String?) ?? 'Yusuf Ihsan Gorgel';
      final github = (data['github'] as String?) ?? '';
      final linkedin = (data['linkedin'] as String?) ?? '';
      final email = (data['email'] as String?) ?? '';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Social links — wraps on narrow screens
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 32,
              runSpacing: 12,
              children: [
                if (github.isNotEmpty) _SocialLink(label: 'GitHub', url: github),
                if (linkedin.isNotEmpty) _SocialLink(label: 'LinkedIn', url: linkedin),
                if (email.isNotEmpty) _SocialLink(label: 'Email', url: 'mailto:$email'),
              ],
            ),
            const SizedBox(height: 20),
            // View Source link
            if (github.isNotEmpty)
              _ViewSourceLink(repoUrl: '$github/Flutter-Web-Portfolio'),
            const SizedBox(height: 20),
            Text(
              '\u00A9 $year $name',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            const _CommandPaletteHint(),
          ],
        ),
      );
    });
  }

}

class _SocialLink extends StatefulWidget {
  const _SocialLink({required this.label, required this.url});

  final String label;
  final String url;

  @override
  State<_SocialLink> createState() => _SocialLinkState();
}

class _SocialLinkState extends State<_SocialLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: () async {
      final uri = Uri.parse(widget.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    },
    onHoverChanged: (hovered) => setState(() => _hovered = hovered),
    child: Semantics(
      link: true,
      label: widget.label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              color: _hovered ? AppColors.textBright : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedContainer(
            duration: AppDurations.fast,
            curve: CinematicCurves.hoverLift,
            height: 1,
            width: _hovered ? _labelWidth(widget.label) : 0,
            color: AppColors.accent.withValues(alpha: 0.6),
          ),
        ],
      ),
    ),
  );

  /// Estimate the rendered width of the label text for the underline.
  double _labelWidth(String text) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.jetBrainsMono(fontSize: 13),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }
}

/// Subtle "View Source" link pointing to the GitHub repo.
class _ViewSourceLink extends StatefulWidget {
  const _ViewSourceLink({required this.repoUrl});

  final String repoUrl;

  @override
  State<_ViewSourceLink> createState() => _ViewSourceLinkState();
}

class _ViewSourceLinkState extends State<_ViewSourceLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final brightColor = isDark ? AppColors.textBright : AppColors.lightTextBright;

    return CinematicFocusable(
      onTap: () async {
        final uri = Uri.parse(widget.repoUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      onHoverChanged: (hovered) => setState(() => _hovered = hovered),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.code_rounded,
            size: 14,
            color: _hovered
                ? brightColor
                : secondaryColor.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 6),
          Text(
            Get.find<LanguageController>().getText('footer.view_source', defaultValue: 'View Source'),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: _hovered
                  ? brightColor
                  : secondaryColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle keyboard shortcut hint for the command palette.
class _CommandPaletteHint extends StatelessWidget {
  const _CommandPaletteHint();

  @override
  Widget build(BuildContext context) {
    final isMac =
        defaultTargetPlatform == TargetPlatform.macOS;
    final shortcut = isMac ? '\u2318K' : 'Ctrl+K';

    final languageController = Get.find<LanguageController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${languageController.getText('footer.command_hint_prefix', defaultValue: 'Press')} ',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: secondaryColor.withValues(alpha: 0.5),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: (Theme.of(context).brightness == Brightness.dark
                ? Colors.white : Colors.black).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white : Colors.black).withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            shortcut,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: secondaryColor.withValues(alpha: 0.7),
            ),
          ),
        ),
        Text(
          ' ${languageController.getText('footer.command_hint_suffix', defaultValue: 'to open command palette')}',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: secondaryColor.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
