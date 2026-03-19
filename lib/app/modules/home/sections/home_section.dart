import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/mouse_effects.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// Home page welcome section
class HomeSection extends StatelessWidget {
  const HomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final themeController = Get.find<ThemeController>();
    final screenHeight = MediaQuery.of(context).size.height;

    // AppBar height (responsive)
    final appBarHeight = ResponsiveUtils.getValueForScreenType<double>(
      context: context,
      mobile: 60,
      tablet: 70,
      desktop: 80,
    );

    // Responsive padding values
    final horizontalPadding = ResponsiveUtils.getValueForScreenType<double>(
      context: context,
      mobile: 20,
      tablet: 40,
      desktop: 80,
      largeDesktop: 100,
    );

    // Responsive font sizes
    final titleFontSize = ResponsiveUtils.getValueForScreenType<double>(
      context: context,
      mobile: 32,
      tablet: 40,
      desktop: 50,
      largeDesktop: 60,
    );

    final subtitleFontSize = ResponsiveUtils.getValueForScreenType<double>(
      context: context,
      mobile: 18,
      tablet: 20,
      desktop: 22,
      largeDesktop: 24,
    );

    // Horizontal/vertical button layout
    final isVerticalLayout = ResponsiveUtils.isMobile(context);

    return Container(
      width: double.infinity,
      height: screenHeight - appBarHeight,
      constraints: BoxConstraints(maxHeight: screenHeight - appBarHeight),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated intro text
            FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      themeController.isDarkMode
                          ? Colors.white.withValues(alpha:0.1)
                          : Colors.black.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: themeController.primaryColor.withValues(alpha:0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  languageController.getText(
                    'home_section.welcome',
                    defaultValue: 'Portfolyoma hoş geldiniz',
                  ),
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getValueForScreenType<double>(
                      context: context,
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                    fontWeight: FontWeight.w500,
                    color:
                        themeController.isDarkMode
                            ? Colors.white70
                            : Colors.black87,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Main title
            FadeInDown(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(milliseconds: 800),
              child: Text(
                languageController.getText(
                  'home_section.title',
                  defaultValue: 'Ben Yusuf İhsan Görgel',
                ),
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: themeController.primaryColor.withValues(alpha:0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Subtitle
            FadeInDown(
              delay: const Duration(milliseconds: 600),
              duration: const Duration(milliseconds: 800),
              child: Text(
                languageController.getText(
                  'home_section.subtitle',
                  defaultValue: 'Yazılım Geliştirici & UI/UX Tasarımcı',
                ),
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.w300,
                  color:
                      themeController.isDarkMode
                          ? Colors.white70
                          : Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FadeInDown(
                delay: const Duration(milliseconds: 900),
                duration: const Duration(milliseconds: 800),
                child:
                    isVerticalLayout
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildButton(
                              context,
                              icon: Icons.download_outlined,
                              text: Text(
                                languageController.getText(
                                  'home_section.download_cv',
                                  defaultValue: 'CV İndir',
                                ),
                              ),
                              onTap: _downloadCV,
                              isPrimary: true,
                              themeController: themeController,
                              isFullWidth: true,
                            ),

                            const SizedBox(height: 16),

                            _buildButton(
                              context,
                              icon: Icons.mail_outline,
                              text: Text(
                                languageController.getText(
                                  'home_section.contact',
                                  defaultValue: 'İletişim',
                                ),
                              ),
                              onTap: () {
                                final scrollController =
                                    Get.find<AppScrollController>();
                                scrollController.scrollToSection('contact');
                              },
                              isPrimary: false,
                              themeController: themeController,
                              isFullWidth: true,
                            ),
                          ],
                        )
                        : Row(
                          children: [
                            _buildButton(
                              context,
                              icon: Icons.download_outlined,
                              text: Text(
                                languageController.getText(
                                  'home_section.download_cv',
                                  defaultValue: 'CV İndir',
                                ),
                              ),
                              onTap: _downloadCV,
                              isPrimary: true,
                              themeController: themeController,
                            ),

                            const SizedBox(width: 16),

                            _buildButton(
                              context,
                              icon: Icons.mail_outline,
                              text: Text(
                                languageController.getText(
                                  'home_section.contact',
                                  defaultValue: 'İletişim',
                                ),
                              ),
                              onTap: () {
                                final scrollController =
                                    Get.find<AppScrollController>();
                                scrollController.scrollToSection('contact');
                              },
                              isPrimary: false,
                              themeController: themeController,
                            ),
                          ],
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CV download handler
  Future<void> _downloadCV() async {
    const cvUrl = '/assets/data/cv.pdf';

    if (await canLaunchUrl(Uri.parse(cvUrl))) {
      await launchUrl(Uri.parse(cvUrl));
    } else {
      // Fallback: open in browser
      final baseUrl = Uri.base.toString();
      final fullUrl = baseUrl + cvUrl;
      await launchUrl(Uri.parse(fullUrl));
    }
  }

  // Button builder
  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required Widget text,
    required VoidCallback onTap,
    required bool isPrimary,
    required ThemeController themeController,
    bool isFullWidth = false,
  }) {
    // Responsive button dimensions
    final horizontalPadding = ResponsiveUtils.getValueForScreenType<double>(
      context: context,
      mobile: 16,
      tablet: 20,
      desktop: 24,
    );

    final verticalPadding = ResponsiveUtils.getValueForScreenType<double>(
      context: context,
      mobile: 12,
      tablet: 14,
      desktop: 16,
    );

    return MouseLight(
      lightColor: themeController.primaryColor,
      lightSize: 150,
      intensity: 0.2,
      child: SizedBox(
        width: isFullWidth ? double.infinity : null,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(
            icon,
            color: isPrimary ? Colors.white : themeController.primaryColor,
            size: ResponsiveUtils.getValueForScreenType<double>(
              context: context,
              mobile: 18,
              tablet: 20,
              desktop: 24,
            ),
          ),
          label: text,
          style: ElevatedButton.styleFrom(
            foregroundColor:
                isPrimary ? Colors.white : themeController.primaryColor,
            backgroundColor:
                isPrimary ? themeController.primaryColor : Colors.transparent,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: BorderSide(color: themeController.primaryColor, width: 2),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
