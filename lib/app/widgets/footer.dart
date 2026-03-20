import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
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
            // Social links
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (github.isNotEmpty) _SocialLink(label: 'GitHub', url: github),
                if (github.isNotEmpty && linkedin.isNotEmpty) _dot(),
                if (linkedin.isNotEmpty) _SocialLink(label: 'LinkedIn', url: linkedin),
                if (linkedin.isNotEmpty && email.isNotEmpty) _dot(),
                if (email.isNotEmpty) _SocialLink(label: 'Email', url: 'mailto:$email'),
              ],
            ),
            const SizedBox(height: 24),
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

  static Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(
      '\u00B7',
      style: GoogleFonts.jetBrainsMono(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
    ),
  );
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
      child: Text(
        widget.label,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 13,
        color: _hovered ? AppColors.textBright : AppColors.textSecondary,
      ),
    )),
  );
}

/// Subtle keyboard shortcut hint for the command palette.
class _CommandPaletteHint extends StatelessWidget {
  const _CommandPaletteHint();

  @override
  Widget build(BuildContext context) {
    final isMac =
        defaultTargetPlatform == TargetPlatform.macOS;
    final shortcut = isMac ? '\u2318K' : 'Ctrl+K';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Press ',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            shortcut,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ),
        Text(
          ' to open command palette',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
