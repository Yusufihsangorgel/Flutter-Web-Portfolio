import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/mouse_effects.dart';
import 'holographic_painters.dart';

/// Contact Info Panel
///
/// Displays contact information (email, phone, location) and
/// social media buttons inside a holographic container.
class ContactInfoPanel extends StatelessWidget {
  final LanguageController languageController = Get.find<LanguageController>();
  final ThemeController themeController = Get.find<ThemeController>();

  ContactInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return HolographicContainer(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Obx(() {
          final data = languageController.cvData;
          final isEnglish = languageController.currentLanguage == 'en';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title
              Text(
                isEnglish ? 'Contact Information' : 'İletişim Bilgileri',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // Contact info items
              _buildContactInfoItem(
                Icons.email,
                isEnglish ? 'Email' : 'E-posta',
                data['email'] ?? '',
              ),

              const SizedBox(height: 16),

              _buildContactInfoItem(
                Icons.phone,
                isEnglish ? 'Phone' : 'Telefon',
                data['phone'] ?? '',
              ),

              const SizedBox(height: 16),

              _buildContactInfoItem(
                Icons.location_on,
                isEnglish ? 'Location' : 'Konum',
                data['location'] ?? '',
              ),

              const SizedBox(height: 30),

              // Social media heading
              Text(
                isEnglish ? 'Find Me On' : 'Sosyal Medya',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Social media buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildSocialButton(Icons.language, 'Website', () {}),
                  const SizedBox(width: 12),
                  _buildSocialButton(Icons.code, 'GitHub', () {}),
                  const SizedBox(width: 12),
                  _buildSocialButton(Icons.link, 'LinkedIn', () {}),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  // Contact info item row
  Widget _buildContactInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: themeController.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: themeController.primaryColor),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Social media button
  Widget _buildSocialButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return HoverAnimatedWidget(
      hoverScale: 1.1,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
