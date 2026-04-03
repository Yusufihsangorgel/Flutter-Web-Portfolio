import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';
import 'package:flutter_web_portfolio/app/widgets/border_light_card.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/project_detail_overlay.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';
import 'package:flutter_web_portfolio/app/widgets/text_scramble.dart';

/// Projects Section — "The Showcase"
/// Film strip layout with border-light cards + category filter chips.
class ProjectsSection extends StatefulWidget {
  const ProjectsSection({super.key});

  @override
  State<ProjectsSection> createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection> {
  String _selectedCategory = '';

  /// Extract unique category values from the projects list.
  List<String> _extractCategories(List<Object?> projects) {
    final categories = <String>{};
    for (final project in projects) {
      if (project case final Map<String, dynamic> p) {
        final category = p['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }
    }
    return categories.toList()..sort();
  }

  /// Filter projects by the selected category.
  List<Object?> _filterProjects(List<Object?> projects) {
    if (_selectedCategory.isEmpty) return projects;
    return projects.where((project) {
      if (project case final Map<String, dynamic> p) {
        return p['category'] == _selectedCategory;
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final isMobile = ResponsiveUtils.isMobile(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final projectsData = languageController.cvData['projects'] as List? ?? [];
    final categories = _extractCategories(projectsData);
    final filteredProjects = _filterProjects(projectsData);

    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // Giant watermark — derived from nav i18n
          Positioned(
            top: -20,
            left: -10,
            child: Obx(() => Text(
              languageController.getText('nav.projects', defaultValue: 'Projects').toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: ResponsiveUtils.getValueForScreenType<double>(
                  context: context,
                  mobile: 48.0,
                  tablet: screenWidth * 0.14,
                  desktop: screenWidth * 0.18,
                ),
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.03),
                letterSpacing: -4,
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
                    number: '05',
                    title: languageController.getText(
                      'projects_section.title',
                      defaultValue: "Things I've Built",
                    ),
                    accent: accent,
                  );
                }),
              ),
              const SizedBox(height: 24),
              // Category filter chips
              if (categories.isNotEmpty)
                ScrollFadeIn(
                  child: Obx(() {
                    final accent = Get.find<SceneDirector>().currentAccent.value;
                    final filterAllLabel = languageController.getText(
                      'projects_section.filter_all',
                      defaultValue: 'All',
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _CategoryChip(
                            label: filterAllLabel,
                            isSelected: _selectedCategory.isEmpty,
                            accent: accent,
                            onTap: () => setState(() => _selectedCategory = ''),
                          ),
                          for (final category in categories)
                            _CategoryChip(
                              label: category,
                              isSelected: _selectedCategory == category,
                              accent: accent,
                              onTap: () => setState(() => _selectedCategory = category),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              const SizedBox(height: 16),
              // Featured projects — full width, alternating
              AnimatedSwitcher(
                duration: AppDurations.medium,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Column(
                  key: ValueKey<String>(_selectedCategory),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < filteredProjects.length; i++) ...[
                      ScrollFadeIn(
                        delay: Duration(milliseconds: i * AppDurations.staggerShort.inMilliseconds),
                        child: _ProjectCard(
                          project: filteredProjects[i] as Map<String, dynamic>,
                          isReversed: !isMobile && i.isOdd,
                          isMobile: isMobile,
                        ),
                      ),
                      if (i < filteredProjects.length - 1) const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Category filter chip with accent color highlight.
class _CategoryChip extends StatefulWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? widget.accent.withValues(alpha: 0.15)
              : _hovered
                  ? widget.accent.withValues(alpha: 0.06)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isSelected
                ? widget.accent
                : _hovered
                    ? widget.accent.withValues(alpha: 0.4)
                    : AppColors.textSecondary.withValues(alpha: 0.3),
            width: widget.isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
            color: widget.isSelected ? widget.accent : AppColors.textPrimary,
          ),
        ),
      ),
    ),
  );
}

// Project card — film strip style with border light + scale on hover
class _ProjectCard extends StatefulWidget {
  const _ProjectCard({
    required this.project,
    this.isReversed = false,
    this.isMobile = false,
  });

  final Map<String, dynamic> project;
  final bool isReversed;
  final bool isMobile;

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _hovered = false;

  Map<String, dynamic> get project => widget.project;
  bool get isReversed => widget.isReversed;
  bool get isMobile => widget.isMobile;

  bool get _hasCaseStudy {
    final cs = project['case_study'] as Map<String, dynamic>?;
    if (cs == null) return false;
    return (cs['problem'] as String?)?.isNotEmpty == true ||
        (cs['solution'] as String?)?.isNotEmpty == true ||
        (cs['result'] as String?)?.isNotEmpty == true;
  }

  @override
  Widget build(BuildContext context) {
    final p = project;
    final title = (p['title'] as String?) ?? 'Project';
    final description = (p['description'] as String?) ?? '';
    final technologies = _extractTechnologies(p);
    final url = _extractUrl(p);

    return Obx(() {
      final accent = Get.find<SceneDirector>().currentAccent.value;

      final frontCard = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..scaleByDouble(_hovered ? 1.02 : 1.0, _hovered ? 1.02 : 1.0, 1.0, 1.0),
          transformAlignment: Alignment.center,
          child: AnimatedOpacity(
            duration: AppDurations.fast,
            opacity: _hovered ? 1.0 : 0.92,
            child: BorderLightCard(
              glowColor: accent,
              child: Stack(
                children: [
                  isMobile
                      ? _buildMobileContent(title, description, technologies, url, accent)
                      : _buildDesktopContent(title, description, technologies, url, accent),
                  if (_hasCaseStudy)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Icon(
                        Icons.sync_rounded,
                        size: 18,
                        color: accent.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      if (!_hasCaseStudy) {
        return GestureDetector(
          onTap: () => ProjectDetailOverlay.show(context, project),
          child: frontCard,
        );
      }

      return _FlipCard(
        front: frontCard,
        back: _ProjectCardBack(
          project: project,
          isMobile: isMobile,
          accent: accent,
        ),
      );
    });
  }

  Widget _buildDesktopContent(
    String title,
    String description,
    List<String> technologies,
    String url,
    Color accent,
  ) {
    final content = [
      Expanded(
        flex: 3,
        child: Column(
          crossAxisAlignment: isReversed ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            TextScramble(
              text: title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textBright,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: AppTypography.body,
              textAlign: isReversed ? TextAlign.right : TextAlign.left,
            ),
            const SizedBox(height: 20),
            // Tech pills
            Wrap(
              alignment: isReversed ? WrapAlignment.end : WrapAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: technologies.map((tech) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  tech,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: accent,
                  ),
                ),
              )).toList(),
            ),
            if (url.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: isReversed ? Alignment.centerRight : Alignment.centerLeft,
                child: _ProjectLink(url: url, accent: accent),
              ),
            ],
          ],
        ),
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: isReversed ? content.reversed.toList() : content,
    );
  }

  Widget _buildMobileContent(
    String title,
    String description,
    List<String> technologies,
    String url,
    Color accent,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TextScramble(
              text: title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textBright,
              ),
            ),
          ),
          if (url.isNotEmpty) _ProjectLink(url: url, accent: accent),
        ],
      ),
      const SizedBox(height: 12),
      Text(description, style: AppTypography.bodySmall),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: technologies.map((tech) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tech,
            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: accent),
          ),
        )).toList(),
      ),
    ],
  );

  List<String> _extractTechnologies(Map<String, dynamic> project) {
    if (project['technologies'] case final List<dynamic> techs) {
      return List<String>.from(techs);
    }
    return [];
  }

  String _extractUrl(Map<String, dynamic> project) => switch (project['url']) {
    final String url => url,
    final Map<String, dynamic> urls => [
      for (final key in ['website', 'google_play', 'app_store'])
        if (urls[key] case final String url) url,
    ].firstOrNull ?? '',
    _ => '',
  };
}

// Project link icon
class _ProjectLink extends StatefulWidget {
  const _ProjectLink({required this.url, required this.accent});
  final String url;
  final Color accent;

  @override
  State<_ProjectLink> createState() => _ProjectLinkState();
}

class _ProjectLinkState extends State<_ProjectLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: () async {
      var urlString = widget.url;
      if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
        urlString = 'https://$urlString';
      }
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    },
    onHoverChanged: (hovered) => setState(() => _hovered = hovered),
    borderRadius: BorderRadius.circular(6),
    child: AnimatedContainer(
      duration: AppDurations.fast,
      padding: const EdgeInsets.all(8),
      transform: Matrix4.diagonal3Values(_hovered ? 1.1 : 1.0, _hovered ? 1.1 : 1.0, 1.0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: _hovered ? widget.accent.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        boxShadow: _hovered
            ? [BoxShadow(color: widget.accent.withValues(alpha: 0.2), blurRadius: 12)]
            : [],
      ),
      child: Icon(
        Icons.open_in_new_rounded,
        size: 20,
        color: _hovered ? widget.accent : AppColors.textPrimary,
      ),
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// 3D flip card — rotates 180° around Y-axis to reveal back content
// ──────────────────────────────────────────────────────────────────────────────

class _FlipCard extends StatefulWidget {
  const _FlipCard({required this.front, required this.back});
  final Widget front;
  final Widget back;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppDurations.entrance, // 600ms
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _showFront = !_showFront;
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _flip,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final curved = CinematicCurves.dramaticEntrance
            .transform(_controller.value);
        final angle = curved * pi;
        final isFront = angle < pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: isFront
              ? widget.front
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: widget.back,
                ),
        );
      },
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Project card back face — compact case study view
// ──────────────────────────────────────────────────────────────────────────────

class _ProjectCardBack extends StatelessWidget {
  const _ProjectCardBack({
    required this.project,
    required this.isMobile,
    required this.accent,
  });

  final Map<String, dynamic> project;
  final bool isMobile;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final title = (project['title'] as String?) ?? 'Project';
    final caseStudy = project['case_study'] as Map<String, dynamic>? ?? {};
    final problem = caseStudy['problem'] as String? ?? '';
    final solution = caseStudy['solution'] as String? ?? '';
    final result = caseStudy['result'] as String? ?? '';
    final technologies = _extractTechnologies(project);
    final url = _extractUrl(project);
    final langCtrl = Get.find<LanguageController>();

    return BorderLightCard(
      glowColor: accent,
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: AppTypography.h3.copyWith(color: accent),
                ),
                const SizedBox(height: 16),

                // Case study sections
                if (problem.isNotEmpty) ...[
                  _BackSection(
                    heading: langCtrl.getText(
                      'projects_section.case_study_problem',
                      defaultValue: 'The Challenge',
                    ),
                    body: problem,
                    accent: accent,
                  ),
                  const SizedBox(height: 12),
                ],
                if (solution.isNotEmpty) ...[
                  _BackSection(
                    heading: langCtrl.getText(
                      'projects_section.case_study_solution',
                      defaultValue: 'The Approach',
                    ),
                    body: solution,
                    accent: accent,
                  ),
                  const SizedBox(height: 12),
                ],
                if (result.isNotEmpty) ...[
                  _BackSection(
                    heading: langCtrl.getText(
                      'projects_section.case_study_result',
                      defaultValue: 'The Result',
                    ),
                    body: result,
                    accent: accent,
                  ),
                  const SizedBox(height: 12),
                ],

                // Technologies
                if (technologies.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: technologies
                        .map((tech) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tech,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  color: accent,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],

                // Link button
                if (url.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ProjectLink(url: url, accent: accent),
                ],
              ],
            ),
          ),

          // Flip-back icon
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.flip_to_front_rounded,
              size: 18,
              color: accent.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _extractTechnologies(Map<String, dynamic> project) {
    if (project['technologies'] case final List<dynamic> techs) {
      return List<String>.from(techs);
    }
    return [];
  }

  String _extractUrl(Map<String, dynamic> project) => switch (project['url']) {
        final String url => url,
        final Map<String, dynamic> urls => [
            for (final key in ['website', 'google_play', 'app_store'])
              if (urls[key] case final String url) url,
          ].firstOrNull ??
            '',
        _ => '',
      };
}

// Compact case study section for the back face
class _BackSection extends StatelessWidget {
  const _BackSection({
    required this.heading,
    required this.body,
    required this.accent,
  });

  final String heading;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: AppTypography.caption.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: AppTypography.bodySmall,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
}
