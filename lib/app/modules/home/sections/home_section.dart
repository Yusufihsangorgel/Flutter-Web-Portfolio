import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/mouse_effects.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ana sayfa karşılama bölümü
class HomeSection extends StatelessWidget {
  const HomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final themeController = Get.find<ThemeController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      // Tam ekran yüksekliği, alt kısımda herhangi bir boşluk kalmaması için
      height: screenHeight - 80, // AppBar yüksekliği çıkarıldı
      // Minimum yükseklik kısıtlamasını kaldırıyoruz, böylece tam ekran yüksekliğini alacak
      constraints: BoxConstraints(maxHeight: screenHeight - 80),
      // Tamamen şeffaf
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: screenWidth > 800 ? 100 : 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animasyonlu giriş metni
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
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: themeController.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Obx(() {
                  final isEnglish = languageController.currentLanguage == 'en';
                  return Text(
                    isEnglish
                        ? 'Welcome to my portfolio'
                        : 'Portfolyoma hoş geldiniz',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color:
                          themeController.isDarkMode
                              ? Colors.white70
                              : Colors.black87,
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),

            // Ana başlık
            FadeInDown(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(milliseconds: 800),
              child: Obx(() {
                final isEnglish = languageController.currentLanguage == 'en';
                return Text(
                  isEnglish
                      ? 'I\'m Yusuf İhsan Görgel'
                      : 'Ben Yusuf İhsan Görgel',
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 60 : 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: themeController.primaryColor.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // Alt başlık
            FadeInDown(
              delay: const Duration(milliseconds: 600),
              duration: const Duration(milliseconds: 800),
              child: Obx(() {
                final isEnglish = languageController.currentLanguage == 'en';
                return Text(
                  isEnglish
                      ? 'Software Developer & UI/UX Designer'
                      : 'Yazılım Geliştirici & UI/UX Tasarımcı',
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 24 : 20,
                    fontWeight: FontWeight.w300,
                    color:
                        themeController.isDarkMode
                            ? Colors.white70
                            : Colors.black87,
                  ),
                );
              }),
            ),

            const SizedBox(height: 40),

            // Son içerik kısmında alt boşluğu kaldırıyoruz
            Padding(
              // Alt kısımda about section'a doğru uzanan extra padding
              padding: const EdgeInsets.only(bottom: 10),
              child: FadeInDown(
                delay: const Duration(milliseconds: 900),
                duration: const Duration(milliseconds: 800),
                child: Row(
                  children: [
                    // CV indirme butonu
                    _buildButton(
                      context,
                      icon: Icons.download_outlined,
                      text: Obx(() {
                        final isEnglish =
                            languageController.currentLanguage == 'en';
                        return Text(isEnglish ? 'Download CV' : 'CV İndir');
                      }),
                      onTap: () {
                        _downloadCV();
                      },
                      isPrimary: true,
                      themeController: themeController,
                    ),

                    const SizedBox(width: 16),

                    // İletişim butonu
                    _buildButton(
                      context,
                      icon: Icons.mail_outline,
                      text: Obx(() {
                        final isEnglish =
                            languageController.currentLanguage == 'en';
                        return Text(isEnglish ? 'Contact' : 'İletişim');
                      }),
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

  // CV İndirme fonksiyonu
  Future<void> _downloadCV() async {
    const cvUrl = '/assets/data/cv.pdf';

    if (await canLaunchUrl(Uri.parse(cvUrl))) {
      await launchUrl(Uri.parse(cvUrl));
    } else {
      // Fallback yöntemi - tarayıcıda açma
      final baseUrl = Uri.base.toString();
      final fullUrl = baseUrl + cvUrl;
      await launchUrl(Uri.parse(fullUrl));
    }
  }

  // Buton widget'ı
  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required Widget text,
    required VoidCallback onTap,
    required bool isPrimary,
    required ThemeController themeController,
  }) {
    return MouseLight(
      lightColor: themeController.primaryColor,
      lightSize: 150,
      intensity: 0.2,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: isPrimary ? Colors.white : themeController.primaryColor,
        ),
        label: text,
        style: ElevatedButton.styleFrom(
          foregroundColor:
              isPrimary ? Colors.white : themeController.primaryColor,
          backgroundColor:
              isPrimary ? themeController.primaryColor : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: themeController.primaryColor, width: 2),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
