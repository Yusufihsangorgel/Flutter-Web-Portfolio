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
      toolbarHeight: 64,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Column(
        children: [
          Expanded(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.85),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.06),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Scroll progress indicator
          _ScrollProgressBar(scrollController: scrollController),
        ],
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            languageController.getText('app.short_name', defaultValue: 'yusuf gorgel'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      leading: isMobile
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white70, size: 24),
                onPressed: () => _showMobileMenu(context),
              ),
            )
          : null,
      actions: [
        if (!isMobile) ...[
          _buildNavItems(context),
          const SizedBox(width: 16),
        ],
        ...?actions,
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildNavItems(BuildContext context) => Obx(() {
    final currentSection = scrollController.activeSection.value;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (final id in ['home', 'about', 'skills', 'experience', 'projects', 'contact'])
          _NavItem(
            label: languageController.getText('nav.$id', defaultValue: id.capitalize ?? id),
            isActive: currentSection == id,
            onTap: () => scrollController.scrollToSection(id),
          ),
      ],
    );
  });

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
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              for (final id in ['home', 'about', 'skills', 'experience', 'projects', 'contact'])
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                  title: Text(
                    languageController.getText('nav.$id', defaultValue: id.capitalize ?? id),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    scrollController.scrollToSection(id);
                  },
                  leading: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : (_hovered ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
            color: widget.isActive
                ? AppColors.primary
                : (_hovered ? Colors.white : Colors.white.withValues(alpha: 0.6)),
            letterSpacing: 0.3,
          ),
        ),
      ),
    ),
  );
}

class _ScrollProgressBar extends StatefulWidget {
  const _ScrollProgressBar({required this.scrollController});

  final AppScrollController scrollController;

  @override
  State<_ScrollProgressBar> createState() => _ScrollProgressBarState();
}

class _ScrollProgressBarState extends State<_ScrollProgressBar> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final controller = widget.scrollController.scrollController;
    if (!controller.hasClients) return;

    final maxExtent = controller.position.maxScrollExtent;
    if (maxExtent <= 0) return;

    setState(() {
      _progress = (controller.offset / maxExtent).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 2,
    child: LinearProgressIndicator(
      value: _progress,
      backgroundColor: Colors.transparent,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      minHeight: 2,
    ),
  );
}
