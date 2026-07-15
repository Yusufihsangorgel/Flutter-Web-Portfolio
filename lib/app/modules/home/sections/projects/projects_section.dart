import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';
import 'package:flutter_web_portfolio/app/widgets/border_light_card.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';
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
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) => _buildContent(context),
      );

  Widget _buildContent(BuildContext context) {
    final languageController = context.read<LanguageCubit>();
    final isMobile = ResponsiveUtils.isMobile(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final projectsData = languageController.cvData['projects'] as List? ?? [];
    final categories = _extractCategories(projectsData);
    final filteredProjects = _filterProjects(projectsData);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1100),
      child: Stack(
        children: [
          // Giant watermark — derived from nav i18n
          Positioned(
            top: -20,
            left: -10,
            child: Text(
              languageController
                  .getText('nav.projects', defaultValue: 'Projects')
                  .toUpperCase(),
              style: AppFonts.spaceGrotesk(
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
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              ScrollFadeIn(
                child: SceneAccentBuilder(
                  builder: (context, accent) => NumberedSectionHeading(
                    number: '05',
                    title: languageController.getText(
                      'projects_section.title',
                      defaultValue: "Things I've Built",
                    ),
                    accent: accent,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Category filter chips
              if (categories.length > 1)
                ScrollFadeIn(
                  child: SceneAccentBuilder(
                    builder: (context, accent) {
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
                              onTap: () =>
                                  setState(() => _selectedCategory = ''),
                            ),
                            for (final category in categories)
                              _CategoryChip(
                                label: category,
                                isSelected: _selectedCategory == category,
                                accent: accent,
                                onTap: () => setState(
                                  () => _selectedCategory = category,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
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
                        delay: Duration(
                          milliseconds:
                              i * AppDurations.staggerShort.inMilliseconds,
                        ),
                        child: _ProjectCard(
                          project: filteredProjects[i] as Map<String, dynamic>,
                          isReversed: !isMobile && i.isOdd,
                          isMobile: isMobile,
                        ),
                      ),
                      if (i < filteredProjects.length - 1)
                        const SizedBox(height: 32),
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
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: widget.onTap,
    onHoverChanged: (hovered) => setState(() => _hovered = hovered),
    semanticLabel: widget.label,
    selected: widget.isSelected,
    borderRadius: BorderRadius.circular(20),
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
        style: AppFonts.jetBrainsMono(
          fontSize: 13,
          fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
          color: widget.isSelected ? widget.accent : AppColors.textPrimary,
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

    return SceneAccentBuilder(
      builder: (context, accent) {
        final frontCard = MouseRegion(
          cursor: _hasCaseStudy
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: Curves.easeOut,
            transform: Matrix4.identity()
              ..scaleByDouble(
                _hovered ? 1.02 : 1.0,
                _hovered ? 1.02 : 1.0,
                1.0,
                1.0,
              ),
            transformAlignment: Alignment.center,
            child: AnimatedOpacity(
              duration: AppDurations.fast,
              opacity: _hovered ? 1.0 : 0.92,
              child: BorderLightCard(
                glowColor: accent,
                child: Stack(
                  children: [
                    isMobile
                        ? _buildMobileContent(
                            title,
                            description,
                            technologies,
                            url,
                            accent,
                          )
                        : _buildDesktopContent(
                            title,
                            description,
                            technologies,
                            url,
                            accent,
                          ),
                    if (_hasCaseStudy && !isMobile)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Tooltip(
                          message: context.read<LanguageCubit>().getText(
                            'projects_section.flip_hint',
                            defaultValue: 'Click to view case study',
                          ),
                          child: Icon(
                            Icons.flip_rounded,
                            size: 16,
                            color: accent.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );

        if (!_hasCaseStudy) {
          return frontCard;
        }

        final caseStudyLabel = context.read<LanguageCubit>().getText(
          'projects_section.case_study_label',
          defaultValue: 'Case Study',
        );
        final semanticLabel = '$caseStudyLabel: $title';

        // On mobile, show case study in a bottom sheet instead of 3D flip
        if (isMobile) {
          return CinematicFocusable(
            onTap: () => _showCaseStudySheet(context, project, accent),
            semanticLabel: semanticLabel,
            child: Stack(
              children: [
                frontCard,
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_stories_rounded,
                          size: 12,
                          color: accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.read<LanguageCubit>().getText(
                            'projects_section.case_study_label',
                            defaultValue: 'Case Study',
                          ),
                          style: AppFonts.jetBrainsMono(
                            fontSize: 10,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return _FlipCard(
          semanticLabel: semanticLabel,
          front: frontCard,
          back: _ProjectCardBack(
            project: project,
            isMobile: isMobile,
            accent: accent,
          ),
        );
      },
    );
  }

  Widget _buildDesktopContent(
    String title,
    String description,
    List<String> technologies,
    String url,
    Color accent,
  ) {
    final category = (project['category'] as String?) ?? '';
    final urls = _extractAllUrls(project);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: category badge + title
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        category.toUpperCase(),
                        style: AppFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accent,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  TextScramble(
                    text: title,
                    style: AppFonts.spaceGrotesk(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBright,
                    ),
                  ),
                ],
              ),
            ),
            // Platform icons
            if (urls.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in urls.entries)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _PlatformIcon(
                        projectTitle: title,
                        platform: entry.key,
                        url: entry.value,
                        accent: accent,
                      ),
                    ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 14),
        // Description
        Text(
          description,
          style: AppTypography.body.copyWith(height: 1.7),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 18),
        // Tech pills + Visit CTA row
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: technologies
                    .take(6)
                    .map(
                      (tech) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tech,
                          style: AppFonts.jetBrainsMono(
                            fontSize: 12,
                            color: accent,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            if (url.isNotEmpty) ...[
              const SizedBox(width: 16),
              _VisitButton(projectTitle: title, url: url, accent: accent),
            ],
          ],
        ),
      ],
    );
  }

  /// Extract all URL types (website, google_play, app_store).
  Map<String, String> _extractAllUrls(Map<String, dynamic> project) {
    final result = <String, String>{};
    if (project['url'] case final String url) {
      result['website'] = url;
    } else if (project['url'] case final Map<String, dynamic> urls) {
      for (final key in ['website', 'google_play', 'app_store']) {
        if (urls[key] case final String url) result[key] = url;
      }
    }
    return result;
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
            child: Text(
              title,
              style: AppFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textBright,
              ),
            ),
          ),
          if (url.isNotEmpty)
            _ProjectLink(projectTitle: title, url: url, accent: accent),
        ],
      ),
      const SizedBox(height: 12),
      Text(description, style: AppTypography.bodySmall),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: technologies
            .map(
              (tech) => Container(
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
                  style: AppFonts.jetBrainsMono(fontSize: 11, color: accent),
                ),
              ),
            )
            .toList(),
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
    final Map<String, dynamic> urls =>
      [
            for (final key in ['website', 'google_play', 'app_store'])
              if (urls[key] case final String url) url,
          ].firstOrNull ??
          '',
    _ => '',
  };
}

// Project link icon
class _ProjectLink extends StatefulWidget {
  const _ProjectLink({
    required this.projectTitle,
    required this.url,
    required this.accent,
  });

  final String projectTitle;
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
      if (!urlString.startsWith('http://') &&
          !urlString.startsWith('https://')) {
        urlString = 'https://$urlString';
      }
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    },
    onHoverChanged: (hovered) => setState(() => _hovered = hovered),
    semanticLabel:
        '${context.read<LanguageCubit>().getText('projects_section.open_project', defaultValue: 'Open project')}: ${widget.projectTitle}',
    semanticRole: CinematicControlRole.link,
    borderRadius: BorderRadius.circular(6),
    child: AnimatedContainer(
      duration: AppDurations.fast,
      padding: const EdgeInsets.all(8),
      transform: Matrix4.diagonal3Values(
        _hovered ? 1.1 : 1.0,
        _hovered ? 1.1 : 1.0,
        1.0,
      ),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: _hovered
            ? widget.accent.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        boxShadow: _hovered
            ? [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.2),
                  blurRadius: 12,
                ),
              ]
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

/// Small platform icon (web, Play Store, App Store) with tooltip + launch.
class _PlatformIcon extends StatefulWidget {
  const _PlatformIcon({
    required this.projectTitle,
    required this.platform,
    required this.url,
    required this.accent,
  });

  final String projectTitle;
  final String platform;
  final String url;
  final Color accent;

  @override
  State<_PlatformIcon> createState() => _PlatformIconState();
}

class _PlatformIconState extends State<_PlatformIcon> {
  bool _hovered = false;

  IconData get _icon => switch (widget.platform) {
    'google_play' => Icons.android_rounded,
    'app_store' => Icons.apple_rounded,
    _ => Icons.language_rounded,
  };

  String get _label => switch (widget.platform) {
    'google_play' => 'Google Play',
    'app_store' => 'App Store',
    _ => 'Website',
  };

  @override
  Widget build(BuildContext context) {
    final label = context.read<LanguageCubit>().getText(
      'projects_section.link_labels.${widget.platform}',
      defaultValue: _label,
    );

    return Tooltip(
      message: label,
      child: CinematicFocusable(
        onTap: () async {
          var urlString = widget.url;
          if (!urlString.startsWith('http')) urlString = 'https://$urlString';
          final uri = Uri.tryParse(urlString);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        onHoverChanged: (hovered) => setState(() => _hovered = hovered),
        semanticLabel: '$label: ${widget.projectTitle}',
        semanticRole: CinematicControlRole.link,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.accent.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            _icon,
            size: 18,
            color: _hovered ? widget.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Prominent "Visit" CTA button for project cards.
class _VisitButton extends StatefulWidget {
  const _VisitButton({
    required this.projectTitle,
    required this.url,
    required this.accent,
  });

  final String projectTitle;
  final String url;
  final Color accent;

  @override
  State<_VisitButton> createState() => _VisitButtonState();
}

class _VisitButtonState extends State<_VisitButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: () async {
      var urlString = widget.url;
      if (!urlString.startsWith('http')) urlString = 'https://$urlString';
      final uri = Uri.tryParse(urlString);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    },
    onHoverChanged: (hovered) => setState(() => _hovered = hovered),
    semanticLabel:
        '${context.read<LanguageCubit>().getText('projects_section.open_project', defaultValue: 'Open project')}: ${widget.projectTitle}',
    semanticRole: CinematicControlRole.link,
    borderRadius: BorderRadius.circular(8),
    child: AnimatedContainer(
      duration: AppDurations.fast,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _hovered
            ? widget.accent.withValues(alpha: 0.15)
            : widget.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _hovered
              ? widget.accent
              : widget.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.read<LanguageCubit>().getText(
              'projects_section.open_project',
              defaultValue: 'Visit',
            ),
            style: AppFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.accent,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_outward_rounded, size: 14, color: widget.accent),
        ],
      ),
    ),
  );
}

/// Shows a bottom sheet with the case study on mobile.
void _showCaseStudySheet(
  BuildContext context,
  Map<String, dynamic> project,
  Color accent,
) {
  final langCtrl = context.read<LanguageCubit>();
  final caseStudy = project['case_study'] as Map<String, dynamic>? ?? {};
  final title = (project['title'] as String?) ?? 'Project';
  final problem = caseStudy['problem'] as String? ?? '';
  final solution = caseStudy['solution'] as String? ?? '';
  final result = caseStudy['result'] as String? ?? '';

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(title, style: AppTypography.h3.copyWith(color: accent)),
            const SizedBox(height: 20),
            if (problem.isNotEmpty) ...[
              _BackSection(
                heading: langCtrl.getText(
                  'projects_section.case_study_problem',
                  defaultValue: 'The Challenge',
                ),
                body: problem,
                accent: accent,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
            ],
            if (result.isNotEmpty)
              _BackSection(
                heading: langCtrl.getText(
                  'projects_section.case_study_result',
                  defaultValue: 'The Result',
                ),
                body: result,
                accent: accent,
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// 3D flip card — rotates 180° around Y-axis to reveal back content (desktop)
// ──────────────────────────────────────────────────────────────────────────────

class _FlipCard extends StatefulWidget {
  const _FlipCard({
    required this.semanticLabel,
    required this.front,
    required this.back,
  });
  final String semanticLabel;
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
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: _flip,
    semanticLabel: widget.semanticLabel,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final curved = CinematicCurves.dramaticEntrance.transform(
          _controller.value,
        );
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
    final langCtrl = context.read<LanguageCubit>();

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
                Text(title, style: AppTypography.h3.copyWith(color: accent)),
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
                        .map(
                          (tech) => Container(
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
                              style: AppFonts.jetBrainsMono(
                                fontSize: 11,
                                color: accent,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],

                // Link button
                if (url.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ProjectLink(projectTitle: title, url: url, accent: accent),
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
    final Map<String, dynamic> urls =>
      [
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
