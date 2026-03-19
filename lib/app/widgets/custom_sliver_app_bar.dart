import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';

/// Custom SliverAppBar widget
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
    final isMobile = screenWidth < 600;

    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      toolbarHeight: 80,
      expandedHeight: 0,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      shadowColor: Colors.transparent,
      title: const SizedBox.shrink(),
      leadingWidth: 80,
      leading:
          isMobile
              ? Builder(
                builder:
                    (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
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

  Widget _buildNavItems(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildNavItem(context, 'home'),
          _buildNavItem(context, 'about'),
          _buildNavItem(context, 'skills'),
          _buildNavItem(context, 'experience'),
          _buildNavItem(context, 'projects'),
          _buildNavItem(context, 'contact'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String sectionId) {
    final title = languageController.getText(
      'nav.$sectionId',
      defaultValue: sectionId.capitalize ?? sectionId,
    );

    final horizontalPadding = ResponsiveUtils.getValueForScreenType<double>(
      context: context,
      mobile: 4.0,
      tablet: 5.0,
      desktop: 6.0,
      largeDesktop: 8.0,
    );

    final fontSize = ResponsiveUtils.getValueForScreenType<double>(
      context: context,
      mobile: 12.0,
      tablet: 13.0,
      desktop: 14.0,
      largeDesktop: 16.0,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          hoverColor: Colors.purple.withOpacity(0.1),
          splashColor: Colors.purple.withOpacity(0.2),
          onTap: () {
            scrollController.scrollToSection(sectionId);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF00101F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      elevation: 8,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          languageController.getText(
                            'app.menu',
                            defaultValue: 'Menü',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      // Drag handle indicator
                      Container(
                        height: 4,
                        width: 40,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      _buildMobileNavItem(context, 'home'),
                      _buildMobileNavItem(context, 'about'),
                      _buildMobileNavItem(context, 'skills'),
                      _buildMobileNavItem(context, 'experience'),
                      _buildMobileNavItem(context, 'projects'),
                      _buildMobileNavItem(context, 'contact'),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

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
        Navigator.pop(context);
        scrollController.scrollToSection(sectionId);
      },
      leading: const Icon(Icons.circle, color: Colors.white54, size: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: Colors.transparent,
    );
  }
}
