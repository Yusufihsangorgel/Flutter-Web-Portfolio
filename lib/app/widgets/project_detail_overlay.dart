import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';

/// Full-screen overlay that shows a project case study.
/// Frosted glass backdrop with fade+scale entrance animation.
class ProjectDetailOverlay extends StatefulWidget {
  const ProjectDetailOverlay({
    super.key,
    required this.project,
  });

  final Map<String, dynamic> project;

  /// Show the overlay as a modal route.
  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> project,
  ) =>
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Close project detail',
        barrierColor: Colors.transparent,
        transitionDuration: AppDurations.medium,
        pageBuilder: (_, __, ___) => ProjectDetailOverlay(project: project),
        transitionBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      );

  @override
  State<ProjectDetailOverlay> createState() => _ProjectDetailOverlayState();
}

class _ProjectDetailOverlayState extends State<ProjectDetailOverlay> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final horizontalPadding = ResponsiveUtils.getValueForScreenType<double>(
      context: context,
      mobile: 16,
      tablet: 48,
      desktop: 80,
    );
    final maxContentWidth = ResponsiveUtils.getValueForScreenType<double>(
      context: context,
      mobile: double.infinity,
      tablet: 720,
      desktop: 800,
    );

    return Focus(
      focusNode: _focusNode..requestFocus(),
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Frosted glass backdrop
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: ColoredBox(
                    color: AppColors.background.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
            // Content
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isMobile ? 24 : 48,
                  ),
                  child: _Content(project: widget.project),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: isMobile ? 16 : 32,
              right: isMobile ? 16 : 32,
              child: _CloseButton(onTap: () => Navigator.of(context).pop()),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Content body — scrollable project detail
// ──────────────────────────────────────────────────────────────────────────────

class _Content extends StatelessWidget {
  const _Content({required this.project});
  final Map<String, dynamic> project;

  @override
  Widget build(BuildContext context) {
    final langCtrl = Get.find<LanguageController>();
    final title = (project['title'] as String?) ?? 'Project';
    final description = (project['description'] as String?) ?? '';
    final technologies = _extractTechnologies(project);
    final urls = _extractAllUrls(project);
    final caseStudy = project['case_study'] as Map<String, dynamic>?;
    final projectImage = project['image'] as String?;

    return Obx(() {
      final accent = Get.find<SceneDirector>().currentAccent.value;

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header image
            if (projectImage != null && projectImage.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: projectImage.startsWith('assets/')
                      ? Image.asset(
                          projectImage,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        )
                      : Image.network(
                          projectImage,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Title
            Text(
              title,
              style: AppTypography.h1.copyWith(
                color: accent,
                fontSize: ResponsiveUtils.getValueForScreenType<double>(
                  context: context,
                  mobile: 28,
                  desktop: 36,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Description
            Text(description, style: AppTypography.body),
            const SizedBox(height: 28),

            // Technologies
            if (technologies.isNotEmpty) ...[
              Text(
                langCtrl.getText(
                  'projects_section.technologies',
                  defaultValue: 'Technologies',
                ),
                style: AppTypography.label.copyWith(color: accent),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: technologies
                    .map((tech) => _TechPill(label: tech, accent: accent))
                    .toList(),
              ),
              const SizedBox(height: 32),
            ],

            // Case study sections
            if (caseStudy != null) ...[
              _Divider(accent: accent),
              const SizedBox(height: 28),
              if (caseStudy['problem'] case final String problem
                  when problem.isNotEmpty) ...[
                _CaseStudyBlock(
                  heading: langCtrl.getText(
                    'projects_section.case_study_problem',
                    defaultValue: 'The Challenge',
                  ),
                  body: problem,
                  accent: accent,
                  imageUrl: caseStudy['problem_image'] as String?,
                ),
                const SizedBox(height: 24),
              ],
              if (caseStudy['solution'] case final String solution
                  when solution.isNotEmpty) ...[
                _CaseStudyBlock(
                  heading: langCtrl.getText(
                    'projects_section.case_study_solution',
                    defaultValue: 'The Approach',
                  ),
                  body: solution,
                  accent: accent,
                  imageUrl: caseStudy['solution_image'] as String?,
                ),
                const SizedBox(height: 24),
              ],
              if (caseStudy['result'] case final String result
                  when result.isNotEmpty) ...[
                _CaseStudyBlock(
                  heading: langCtrl.getText(
                    'projects_section.case_study_result',
                    defaultValue: 'The Result',
                  ),
                  body: result,
                  accent: accent,
                  imageUrl: caseStudy['result_image'] as String?,
                ),
                const SizedBox(height: 24),
              ],
              const SizedBox(height: 8),
            ],

            // Links
            if (urls.isNotEmpty) ...[
              _Divider(accent: accent),
              const SizedBox(height: 24),
              Text(
                langCtrl.getText(
                  'projects_section.links',
                  defaultValue: 'Links',
                ),
                style: AppTypography.label.copyWith(color: accent),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: urls.entries
                    .map((e) => _LinkChip(
                          label: _urlLabel(e.key),
                          url: e.value,
                          accent: accent,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      );
    });
  }

  List<String> _extractTechnologies(Map<String, dynamic> project) {
    if (project['technologies'] case final List<dynamic> techs) {
      return List<String>.from(techs);
    }
    return [];
  }

  Map<String, String> _extractAllUrls(Map<String, dynamic> project) {
    final result = <String, String>{};
    switch (project['url']) {
      case final String url:
        result['website'] = url;
      case final Map<String, dynamic> urls:
        for (final entry in urls.entries) {
          if (entry.value is String) {
            result[entry.key] = entry.value as String;
          }
        }
    }
    return result;
  }

  String _urlLabel(String key) {
    final lang = Get.find<LanguageController>();
    return switch (key) {
      'google_play' => lang.getText('projects_section.link_labels.google_play', defaultValue: 'Google Play'),
      'app_store' => lang.getText('projects_section.link_labels.app_store', defaultValue: 'App Store'),
      'website' => lang.getText('projects_section.link_labels.website', defaultValue: 'Website'),
      _ => key,
    };
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ──────────────────────────────────────────────────────────────────────────────

class _CaseStudyBlock extends StatelessWidget {
  const _CaseStudyBlock({
    required this.heading,
    required this.body,
    required this.accent,
    this.imageUrl,
  });

  final String heading;
  final String body;
  final Color accent;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(heading, style: AppTypography.h2.copyWith(color: accent)),
          ),
          const SizedBox(height: 10),
          Text(body, style: AppTypography.body),
          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: Image.network(
                  imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ],
      );
}

class _TechPill extends StatelessWidget {
  const _TechPill({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(fontSize: 12, color: accent),
        ),
      );
}

class _Divider extends StatelessWidget {
  const _Divider({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        color: accent.withValues(alpha: 0.12),
      );
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({
    required this.label,
    required this.url,
    required this.accent,
  });

  final String label;
  final String url;
  final Color accent;

  @override
  Widget build(BuildContext context) => Semantics(
        link: true,
        label: '$label: $url',
        child: CinematicFocusable(
          onTap: () async {
            var urlString = url;
            if (!urlString.startsWith('http://') &&
                !urlString.startsWith('https://')) {
              urlString = 'https://$urlString';
            }
            final uri = Uri.parse(urlString);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: accent.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.open_in_new_rounded, size: 16, color: accent),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(color: accent),
                ),
              ],
            ),
          ),
        ),
      );
}

class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
        onTap: widget.onTap,
        onHoverChanged: (hovered) => setState(() => _hovered = hovered),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: _hovered ? 0.1 : 0.04),
            border: Border.all(
              color: Colors.white.withValues(alpha: _hovered ? 0.2 : 0.08),
            ),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 20,
            color: _hovered ? AppColors.textBright : AppColors.textPrimary,
          ),
        ),
      );
}
