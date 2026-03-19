import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/widgets/animated_entrance.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeSection extends StatelessWidget {
  const HomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final themeController = Get.find<ThemeController>();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveUtils.isMobile(context);

    final appBarHeight = ResponsiveUtils.getValueForScreenType<double>(
      context: context,
      mobile: 60,
      tablet: 70,
      desktop: 80,
    );

    final horizontalPadding = ResponsiveUtils.getValueForScreenType<double>(
      context: context,
      mobile: 24,
      tablet: 48,
      desktop: 80,
      largeDesktop: 120,
    );

    final titleFontSize = ResponsiveUtils.getValueForScreenType<double>(
      context: context,
      mobile: 28,
      tablet: 36,
      desktop: 48,
      largeDesktop: 56,
    );

    final subtitleFontSize = ResponsiveUtils.getValueForScreenType<double>(
      context: context,
      mobile: 16,
      tablet: 18,
      desktop: 20,
      largeDesktop: 22,
    );

    return SizedBox(
      width: double.infinity,
      height: screenHeight - appBarHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: isMobile
            ? _buildMobileLayout(context, languageController, themeController, titleFontSize, subtitleFontSize)
            : _buildDesktopLayout(context, languageController, themeController, titleFontSize, subtitleFontSize),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    LanguageController languageController,
    ThemeController themeController,
    double titleFontSize,
    double subtitleFontSize,
  ) => Row(
    children: [
      Expanded(
        flex: 3,
        child: _buildTextContent(context, languageController, themeController, titleFontSize, subtitleFontSize),
      ),
      const SizedBox(width: 40),
      Expanded(
        flex: 2,
        child: AnimatedEntrance.fadeInRight(
          duration: const Duration(milliseconds: 1000),
          delay: const Duration(milliseconds: 500),
          child: _buildProfileImage(themeController),
        ),
      ),
    ],
  );

  Widget _buildMobileLayout(
    BuildContext context,
    LanguageController languageController,
    ThemeController themeController,
    double titleFontSize,
    double subtitleFontSize,
  ) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      AnimatedEntrance.fadeInDown(
        duration: const Duration(milliseconds: 800),
        child: _buildProfileImage(themeController, size: 120),
      ),
      const SizedBox(height: 32),
      _buildTextContent(context, languageController, themeController, titleFontSize, subtitleFontSize, centered: true),
    ],
  );

  Widget _buildProfileImage(ThemeController themeController, {double size = 200}) => Center(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/me.jpeg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.surface,
            child: Icon(Icons.person, size: size * 0.5, color: AppColors.primary),
          ),
        ),
      ),
    ),
  );

  Widget _buildTextContent(
    BuildContext context,
    LanguageController languageController,
    ThemeController themeController,
    double titleFontSize,
    double subtitleFontSize, {
    bool centered = false,
  }) {
    final alignment = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedEntrance.fadeInDown(
          duration: const Duration(milliseconds: 800),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              languageController.getText('home_section.welcome', defaultValue: 'Welcome to my portfolio'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        AnimatedEntrance.fadeInDown(
          delay: const Duration(milliseconds: 300),
          duration: const Duration(milliseconds: 800),
          child: Text(
            languageController.getText('home_section.title', defaultValue: 'Yusuf Ihsan Gorgel'),
            textAlign: textAlign,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.1,
              shadows: [
                Shadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedEntrance.fadeInDown(
          delay: const Duration(milliseconds: 600),
          duration: const Duration(milliseconds: 800),
          child: Text(
            languageController.getText('home_section.subtitle', defaultValue: 'Flutter Developer & Software Engineer'),
            textAlign: textAlign,
            style: TextStyle(
              fontSize: subtitleFontSize,
              fontWeight: FontWeight.w300,
              color: AppColors.primary.withValues(alpha: 0.9),
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 40),
        AnimatedEntrance.fadeInDown(
          delay: const Duration(milliseconds: 900),
          duration: const Duration(milliseconds: 800),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: centered ? WrapAlignment.center : WrapAlignment.start,
            children: [
              _ActionButton(
                icon: Icons.arrow_downward_rounded,
                label: languageController.getText('home_section.view_work', defaultValue: 'View My Work'),
                onTap: () => Get.find<AppScrollController>().scrollToSection('projects'),
                isPrimary: true,
              ),
              _ActionButton(
                icon: Icons.download_outlined,
                label: languageController.getText('home_section.download_cv', defaultValue: 'Download CV'),
                onTap: _downloadCV,
                isPrimary: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _downloadCV() async {
    final baseUrl = Uri.base.toString();
    final cvUrl = '${baseUrl}assets/data/cv.pdf';
    final uri = Uri.parse(cvUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 18),
    label: Text(label),
    style: ElevatedButton.styleFrom(
      foregroundColor: isPrimary ? Colors.white : AppColors.primary,
      backgroundColor: isPrimary ? AppColors.primary : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(
          color: AppColors.primary,
          width: isPrimary ? 0 : 1.5,
        ),
      ),
      elevation: 0,
    ),
  );
}
