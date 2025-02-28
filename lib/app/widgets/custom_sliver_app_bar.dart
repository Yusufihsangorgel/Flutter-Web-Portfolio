import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';

/// Özel SliverAppBar widget'ı
class CustomSliverAppBar extends StatelessWidget {
  final LanguageController languageController;
  final AppScrollController scrollController;
  final List<Widget>? actions;

  const CustomSliverAppBar({
    super.key,
    required this.languageController,
    required this.scrollController,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    return SliverAppBar(
      floating: false,
      pinned: true,
      snap: false,
      backgroundColor: Colors.transparent, // Tamamen şeffaf
      elevation: 0,
      centerTitle: false,
      expandedHeight: 0,
      toolbarHeight: 80,
      // Arka plan filtresini kaldır
      flexibleSpace: Container(color: Colors.transparent),
      title: const SizedBox.shrink(), // Başlık kısmını boş bırak
      actions:
          isMobile
              ? [
                // Mobil modda hamburger menü
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => _showMobileMenu(context),
                ),
                // Sağdaki aksiyonlar
                if (actions != null) ...actions!,
              ]
              : null,
      bottom:
          isMobile
              ? null
              : PreferredSize(
                preferredSize: const Size.fromHeight(0),
                child: Container(
                  padding: const EdgeInsets.only(right: 16.0),
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(child: _buildDesktopNavItems(context)),
                      // Sağdaki aksiyonlar
                      if (actions != null) ...actions!,
                    ],
                  ),
                ),
              ),
    );
  }

  // Masaüstü navigasyon öğeleri
  Widget _buildDesktopNavItems(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildNavItem(context, 'home'),
        _buildNavItem(context, 'about'),
        _buildNavItem(context, 'skills'),
        _buildNavItem(context, 'experience'),
        _buildNavItem(context, 'projects'),
        _buildNavItem(context, 'contact'),
        const SizedBox(width: 24),
      ],
    );
  }

  // Tekil navigasyon öğesi - seçili olma özelliği kaldırıldı
  Widget _buildNavItem(BuildContext context, String sectionId) {
    final title = languageController.getText(
      'nav.$sectionId',
      defaultValue: sectionId.capitalize ?? sectionId,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          hoverColor: Colors.purple.withOpacity(0.1),
          splashColor: Colors.purple.withOpacity(0.2),
          onTap: () {
            // AppScrollController'ın kendi scrollToSection metodunu kullan
            scrollController.scrollToSection(sectionId);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
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
              _buildMobileNavItem(context, 'home'),
              _buildMobileNavItem(context, 'about'),
              _buildMobileNavItem(context, 'skills'),
              _buildMobileNavItem(context, 'experience'),
              _buildMobileNavItem(context, 'projects'),
              _buildMobileNavItem(context, 'contact'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Mobil navigasyon öğesi - seçili olma özelliği kaldırıldı
  Widget _buildMobileNavItem(BuildContext context, String sectionId) {
    final title = languageController.getText(
      'nav.$sectionId',
      defaultValue: sectionId.capitalize ?? sectionId,
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 18,
        ),
      ),
      onTap: () {
        // Önce menüyü kapat
        Navigator.pop(context);

        // AppScrollController kullan
        scrollController.scrollToSection(sectionId);
      },
      leading: const Icon(Icons.circle, color: Colors.white54, size: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: Colors.transparent,
    );
  }
}
