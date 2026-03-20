import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';
import 'package:flutter_web_portfolio/app/widgets/magnetic_button.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';

/// Contact Section — "The Finale"
/// White particles on deep black, shader reveal title, magnetic CTA button.
class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final data = languageController.cvData['personal_info'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final email = (data['email'] as String?) ?? 'developeryusuf@icloud.com';
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.sizeOf(context).height * 0.6,
      ),
      child: Stack(
        children: [
          // Giant watermark — derived from nav i18n
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Obx(() => Text(
                languageController.getText('nav.contact', defaultValue: 'Contact').toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: ResponsiveUtils.getValueForScreenType<double>(
                    context: context,
                    mobile: 48.0,
                    tablet: screenWidth * 0.14,
                    desktop: screenWidth * 0.18,
                  ),
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.02),
                  letterSpacing: -2,
                ),
              )),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  // Title
                  ScrollFadeIn(
                    child: Obx(() {
                      final accent = Get.find<SceneDirector>().currentAccent.value;
                      return Text(
                        languageController.getText(
                          'contact_section.title',
                          defaultValue: 'Get In Touch',
                        ),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  // Description
                  ScrollFadeIn(
                    delay: AppDurations.staggerMedium,
                    child: Text(
                      languageController.getText(
                        'contact_section.description',
                        defaultValue: 'Although I\'m not currently looking for any new '
                            'opportunities, my inbox is always open. Whether you '
                            'have a question or just want to say hi, I\'ll try my '
                            'best to get back to you!',
                      ),
                      style: AppTypography.body,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Magnetic CTA button
                  ScrollFadeIn(
                    delay: AppDurations.normal,
                    child: _MagneticCTA(email: email),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Magnetic CTA — cursor-attracting "Say Hello"
class _MagneticCTA extends StatelessWidget {
  const _MagneticCTA({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) => Obx(() {
    final accent = Get.find<SceneDirector>().currentAccent.value;
    final label = Get.find<LanguageController>().getText(
      'translations.send_message',
      defaultValue: 'Say Hello',
    );
    return Semantics(
      button: true,
      label: label,
      child: MagneticButton(
        onTap: () async {
          final uri = Uri.parse('mailto:$email');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
          child: _HoverContainer(
          accent: accent,
          label: label,
        ),
      ),
    );
  });
}

class _HoverContainer extends StatefulWidget {
  const _HoverContainer({required this.accent, required this.label});
  final Color accent;
  final String label;

  @override
  State<_HoverContainer> createState() => _HoverContainerState();
}

class _HoverContainerState extends State<_HoverContainer> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedContainer(
      duration: AppDurations.buttonHover,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: _hovered
            ? widget.accent.withValues(alpha: 0.08)
            : Colors.transparent,
        border: Border.all(
          color: _hovered
              ? widget.accent
              : widget.accent.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: _hovered
            ? [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.15),
                  blurRadius: 20,
                ),
              ]
            : [],
      ),
      child: Text(
        widget.label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: widget.accent,
          letterSpacing: 2,
        ),
      ),
    ),
  );
}
