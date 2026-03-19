import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

class SkillsSection extends StatelessWidget {
  const SkillsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final screenWidth = MediaQuery.of(context).size.width;

    final maxWidth = screenWidth > 1200 ? 1100.0 : screenWidth * 0.9;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              languageController.getText('skills_section.title', defaultValue: 'Skills & Technologies'),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              languageController.getText('skills_section.subtitle', defaultValue: 'Technologies I work with daily'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 48),
            Obx(() {
              final skillsList = languageController.cvData['skills'] as List<dynamic>? ?? [];
              if (skillsList.isEmpty) return const SizedBox.shrink();

              return Column(
                children: [
                  for (final category in skillsList)
                    _SkillCategoryCard(category: category),
                ],
              );
            }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SkillCategoryCard extends StatelessWidget {
  const _SkillCategoryCard({required this.category});

  final dynamic category;

  static const _categoryIcons = {
    'Mobile': Icons.phone_android_rounded,
    'Frontend': Icons.web_rounded,
    'Backend': Icons.dns_rounded,
    'DevOps': Icons.cloud_rounded,
    'Database': Icons.storage_rounded,
    'Programming': Icons.code_rounded,
  };

  static const _categoryColors = {
    'Mobile': AppColors.skillMobile,
    'Frontend': AppColors.skillFrontend,
    'Backend': AppColors.skillBackend,
    'DevOps': AppColors.skillDevOps,
    'Database': AppColors.skillDatabase,
  };

  @override
  Widget build(BuildContext context) {
    final String name = category['category'] ?? '';
    final List<dynamic> items = category['items'] ?? [];
    if (name.isEmpty || items.isEmpty) return const SizedBox.shrink();

    final color = _categoryColors[name] ?? AppColors.primary;
    final icon = _categoryIcons[name] ?? Icons.code_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final skill in items)
                if (skill is String) _SkillChip(name: skill, color: color),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatefulWidget {
  const _SkillChip({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  State<_SkillChip> createState() => _SkillChipState();
}

class _SkillChipState extends State<_SkillChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _hovered
            ? widget.color.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _hovered
              ? widget.color.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Text(
        widget.name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: _hovered ? FontWeight.w600 : FontWeight.w400,
          color: _hovered ? widget.color : Colors.white.withValues(alpha: 0.8),
          letterSpacing: 0.3,
        ),
      ),
    ),
  );
}
