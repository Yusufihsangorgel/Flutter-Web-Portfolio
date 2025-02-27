import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';

/// Özel SliverAppBar widget'ı
class CustomSliverAppBar extends StatelessWidget {
  final LanguageController languageController;
  final ThemeController themeController;
  final AppScrollController scrollController;
  final List<Widget>? actions;

  const CustomSliverAppBar({
    super.key,
    required this.languageController,
    required this.themeController,
    required this.scrollController,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: false,
      backgroundColor: Colors.transparent, // Şeffaf arka plan
      elevation: 0, // Gölge yok
      centerTitle: false,
      expandedHeight: 80,
      toolbarHeight: 80,
      title: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: _buildLogo(),
      ),
      actions: actions,
    );
  }

  // Logo widget'ı
  Widget _buildLogo() {
    return Text(
      'Yusuf.',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
    );
  }

  // Masaüstü navigasyon öğeleri
  Widget _buildDesktopNavItems(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildNavItem('Home', 'home'),
          _buildNavItem('About', 'about'),
          _buildNavItem('Experience', 'experience'),
          _buildNavItem('Projects', 'projects'),
          _buildNavItem('Skills', 'skills'),
          _buildNavItem('References', 'references'),
          _buildNavItem('Contact', 'contact'),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  // Tekil navigasyon öğesi
  Widget _buildNavItem(String title, String sectionId) {
    return Obx(() {
      final isActive = scrollController.activeSection.value == sectionId;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            hoverColor: themeController.primaryColor.withOpacity(0.1),
            splashColor: themeController.primaryColor.withOpacity(0.2),
            onTap: () {
              // Aktif bölümü HEMEN değiştir (UI yanıt versin)
              scrollController.activeSection.value = sectionId;

              // Hemen ardından bölüme kaydır
              scrollController.scrollToSection(sectionId);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color:
                          isActive
                              ? themeController.primaryColor
                              : Colors.white,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Aktif indikatör
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 2,
                    width: isActive ? 32 : 0,
                    curve: Curves.easeInOut,
                    color: themeController.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // Mobil menü
  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF00101F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      elevation: 8,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMobileNavItem('Home', 'home'),
              _buildMobileNavItem('About', 'about'),
              _buildMobileNavItem('Experience', 'experience'),
              _buildMobileNavItem('Projects', 'projects'),
              _buildMobileNavItem('Skills', 'skills'),
              _buildMobileNavItem('References', 'references'),
              _buildMobileNavItem('Contact', 'contact'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Mobil navigasyon öğesi
  Widget _buildMobileNavItem(String title, String sectionId) {
    return Obx(() {
      final isActive = scrollController.activeSection.value == sectionId;

      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? themeController.primaryColor : Colors.white,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 18,
          ),
        ),
        onTap: () {
          // Önce menüyü kapat
          Navigator.pop(Get.context!);

          // Aktif bölümü HEMEN değiştir (UI yanıt versin)
          scrollController.activeSection.value = sectionId;

          // Ardından bölüme kaydır
          scrollController.scrollToSection(sectionId);
        },
        leading: Icon(
          isActive ? Icons.arrow_right : Icons.circle,
          color: isActive ? themeController.primaryColor : Colors.white54,
          size: isActive ? 28 : 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor:
            isActive
                ? themeController.primaryColor.withOpacity(0.1)
                : Colors.transparent,
      );
    });
  }
}
