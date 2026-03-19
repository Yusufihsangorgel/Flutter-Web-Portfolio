import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

class CustomSliverAppBar extends StatelessWidget {
  const CustomSliverAppBar({
    super.key,
    required this.languageController,
    required this.scrollController,
    this.actions,
  });

  final LanguageController languageController;
  final AppScrollController scrollController;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return SliverAppBar(
      floating: false,
      snap: false,
      pinned: true,
      toolbarHeight: 70,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withValues(alpha: 0.9),
                  AppColors.background.withValues(alpha: 0.7),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
      title: Text(
        languageController.getText('app.short_name', defaultValue: 'YIG'),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
          letterSpacing: 2,
        ),
      ),
      leading: isMobile
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                onPressed: () => _showMobileMenu(context),
              ),
            )
          : null,
      actions: [
        if (!isMobile) ...[
          _buildNavItems(context),
          const SizedBox(width: 24),
        ],
        ...?actions,
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildNavItems(BuildContext context) => Obx(() {
    final currentSection = scrollController.activeSection.value;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (final id in ['home', 'about', 'skills', 'experience', 'projects', 'contact'])
          _buildNavItem(context, id, isActive: currentSection == id),
      ],
    );
  });

  Widget _buildNavItem(BuildContext context, String sectionId, {bool isActive = false}) {
    final title = languageController.getText(
      'nav.$sectionId',
      defaultValue: sectionId.capitalize ?? sectionId,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: () => scrollController.scrollToSection(sectionId),
        style: TextButton.styleFrom(
          foregroundColor: isActive ? AppColors.primary : Colors.white70,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isActive ? 20 : 0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              for (final id in ['home', 'about', 'skills', 'experience', 'projects', 'contact'])
                _buildMobileNavItem(context, id),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavItem(BuildContext context, String sectionId) {
    final title = languageController.getText(
      'nav.$sectionId',
      defaultValue: sectionId.capitalize ?? sectionId,
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        scrollController.scrollToSection(sectionId);
      },
      leading: Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: AppColors.primary.withValues(alpha: 0.05),
    );
  }
}
