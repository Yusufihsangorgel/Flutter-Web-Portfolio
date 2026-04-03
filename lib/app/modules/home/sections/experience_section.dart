import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';

/// Experience Section — "The Journey"
/// Cinematic upgrade: vertical line + animated dot markers, crossfade tabs.
class ExperienceSection extends StatelessWidget {
  const ExperienceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -10,
              child: Obx(() => Text(
                languageController.getText('nav.experience', defaultValue: 'Experience').toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: ResponsiveUtils.getValueForScreenType<double>(
                    context: context,
                    mobile: 48.0,
                    tablet: screenWidth * 0.14,
                    desktop: screenWidth * 0.18,
                  ),
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.03),
                  letterSpacing: -3,
                ),
              )),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                ScrollFadeIn(
                  child: Obx(() {
                    final accent = Get.find<SceneDirector>().currentAccent.value;
                    return NumberedSectionHeading(
                      number: '02',
                      title: languageController.getText(
                        'experience_section.title',
                        defaultValue: "Where I've Worked",
                      ),
                      accent: accent,
                    );
                  }),
                ),
                const SizedBox(height: 32),
                Obx(() {
                  final raw = languageController.cvData['experiences'] as List? ?? [];
                  final experiences = raw.cast<Map<String, dynamic>>();
                  if (experiences.isEmpty) return const SizedBox.shrink();
                  return _ExperienceTabs(
                    experiences: experiences,
                    languageController: languageController,
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Tabbed experience — crossfade + animated markers
class _ExperienceTabs extends StatefulWidget {
  const _ExperienceTabs({
    required this.experiences,
    required this.languageController,
  });

  final List<Map<String, dynamic>> experiences;
  final LanguageController languageController;

  @override
  State<_ExperienceTabs> createState() => _ExperienceTabsState();
}

class _ExperienceTabsState extends State<_ExperienceTabs> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < Breakpoints.mobile;
    final sceneDirector = Get.find<SceneDirector>();

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.experiences.length,
              itemBuilder: (context, i) {
                final exp = widget.experiences[i];
                final isActive = i == _selectedIndex;
                return Obx(() => _TabButton(
                  label: (exp['company'] as String?) ?? '',
                  isActive: isActive,
                  isVertical: false,
                  accent: sceneDirector.currentAccent.value,
                  onTap: () => setState(() => _selectedIndex = i),
                ));
              },
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: AppDurations.crossfade,
            switchInCurve: CinematicCurves.revealDecel,
            switchOutCurve: Curves.easeIn,
            child: _ExperienceDetail(
              key: ValueKey(_selectedIndex),
              experience: widget.experiences[_selectedIndex],
              languageController: widget.languageController,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vertical timeline with dot markers
        SizedBox(
          width: 200,
          child: Obx(() => _VerticalTimeline(
            experiences: widget.experiences,
            selectedIndex: _selectedIndex,
            accent: sceneDirector.currentAccent.value,
            onSelect: (i) => setState(() => _selectedIndex = i),
          )),
        ),
        const SizedBox(width: 32),
        // Detail panel with crossfade
        Expanded(
          child: AnimatedSwitcher(
            duration: AppDurations.crossfade,
            switchInCurve: CinematicCurves.revealDecel,
            switchOutCurve: Curves.easeIn,
            child: _ExperienceDetail(
              key: ValueKey(_selectedIndex),
              experience: widget.experiences[_selectedIndex],
              languageController: widget.languageController,
            ),
          ),
        ),
      ],
    );
  }
}

// Vertical timeline with animated dot markers
class _VerticalTimeline extends StatelessWidget {
  const _VerticalTimeline({
    required this.experiences,
    required this.selectedIndex,
    required this.accent,
    required this.onSelect,
  });

  final List<Map<String, dynamic>> experiences;
  final int selectedIndex;
  final Color accent;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (int i = 0; i < experiences.length; i++)
        _TimelineEntry(
          label: (experiences[i]['company'] as String?) ?? '',
          isActive: i == selectedIndex,
          accent: accent,
          isLast: i == experiences.length - 1,
          onTap: () => onSelect(i),
        ),
    ],
  );
}

class _TimelineEntry extends StatefulWidget {
  const _TimelineEntry({
    required this.label,
    required this.isActive,
    required this.accent,
    required this.isLast,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color accent;
  final bool isLast;
  final VoidCallback onTap;

  @override
  State<_TimelineEntry> createState() => _TimelineEntryState();
}

class _TimelineEntryState extends State<_TimelineEntry> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: widget.onTap,
    onHoverChanged: (hovered) => setState(() => _hovered = hovered),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: AppDurations.medium,
                  curve: CinematicCurves.hoverLift,
                  width: widget.isActive ? 10 : 6,
                  height: widget.isActive ? 10 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isActive
                        ? widget.accent
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color: widget.accent.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.only(top: 4),
                      color: AppColors.textSecondary.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Label
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: AnimatedDefaultTextStyle(
                duration: AppDurations.fast,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  color: widget.isActive
                      ? widget.accent
                      : (_hovered ? AppColors.textBright : AppColors.textPrimary),
                ),
                child: Text(widget.label),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TabButton extends StatefulWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.isVertical,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final bool isVertical;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: widget.onTap,
    onHoverChanged: (hovered) => setState(() => _hovered = hovered),
    child: AnimatedContainer(
      duration: AppDurations.fast,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isActive || _hovered
            ? widget.accent.withValues(alpha: 0.08)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: widget.isActive
                ? widget.accent
                : AppColors.textSecondary.withValues(alpha: 0.2),
            width: widget.isActive ? 2 : 1,
          ),
        ),
      ),
      child: Text(
        widget.label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          color: widget.isActive ? widget.accent : AppColors.textPrimary,
        ),
      ),
    ),
  );
}

// Experience detail panel
class _ExperienceDetail extends StatelessWidget {
  const _ExperienceDetail({
    super.key,
    required this.experience,
    required this.languageController,
  });

  final Map<String, dynamic> experience;
  final LanguageController languageController;

  @override
  Widget build(BuildContext context) {
    final exp = experience;
    final position = (exp['position'] as String?) ?? '';
    final company = (exp['company'] as String?) ?? '';
    final startDate = (exp['start_date'] as String?) ?? '';
    final endDate = (exp['end_date'] as String?) ??
        languageController.getText('experience_section.present', defaultValue: 'Present');
    final description = (exp['description'] as String?) ?? '';

    final bullets = description.toString().split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (bullets.isEmpty && description.toString().isNotEmpty) {
      bullets.add(description.toString());
    }

    return Obx(() {
      final accent = Get.find<SceneDirector>().currentAccent.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            position,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textBright,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@ $company',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$startDate — $endDate',
            style: AppTypography.mono.copyWith(letterSpacing: 1),
          ),
          const SizedBox(height: 24),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '▸ ',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      color: accent,
                      height: 1.6,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      bullet.trim(),
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}
