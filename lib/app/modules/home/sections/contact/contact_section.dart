import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/widgets/animated_entrance.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/shared_background_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/section_title.dart';
import 'widgets/contact_form.dart';
import 'widgets/contact_info_panel.dart';

// Re-export widgets so consumers that relied on the old single-file
// location can still access the holographic helpers if needed.
export 'widgets/holographic_painters.dart';
export 'widgets/contact_form.dart';
export 'widgets/contact_info_panel.dart';

/// ContactSection
///
/// Main layout shell for the contact section. Composes a [ContactForm]
/// and a [ContactInfoPanel] in a responsive two-column (or stacked) layout.
class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final languageController = Get.find<LanguageController>();

    return MouseRegion(
      onHover: (event) {
        // Update mouse position via SharedBackgroundController
        SharedBackgroundController.updateMousePosition(event.localPosition);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: 100,
          horizontal: screenWidth > 800 ? 100 : 30,
        ),
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 80,
        ),
        // NOTE: No background color or gradient here --
        // the Cosmic Background provides the backdrop automatically.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Obx(() {
              final isEnglish = languageController.currentLanguage == 'en';
              return SectionTitle(title: isEnglish ? 'Contact Me' : 'İletişim');
            }),

            const SizedBox(height: 40),

            // Contact form and info panel
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contact form
                    Expanded(
                      flex: 3,
                      child: AnimatedEntrance.fadeInLeft(
                        duration: const Duration(milliseconds: 800),
                        child: ContactForm(isWideLayout: screenWidth > 800),
                      ),
                    ),

                    if (screenWidth > 800) ...[
                      const SizedBox(width: 40),

                      // Contact info panel (side column)
                      Expanded(
                        flex: 2,
                        child: AnimatedEntrance.fadeInRight(
                          duration: const Duration(milliseconds: 800),
                          child: ContactInfoPanel(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Contact info panel below the form on narrow screens
            if (screenWidth <= 800) ...[
              const SizedBox(height: 40),
              AnimatedEntrance.fadeInUp(
                duration: const Duration(milliseconds: 800),
                child: ContactInfoPanel(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
