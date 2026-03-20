import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';
import 'package:flutter_web_portfolio/app/widgets/border_light_card.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/widgets/project_detail_overlay.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';

/// Projects Section — "The Showcase"
/// Film strip layout with border-light cards.
class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final isMobile = ResponsiveUtils.isMobile(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final projectsData = languageController.cvData['projects'] as List? ?? [];

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
                color: Colors.white.withValues(alpha: 0.02),
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
                  return Text(
                    languageController.getText(
                      'projects_section.title',
                      defaultValue: "Things I've Built",
                    ),
                    style: AppTypography.h1.copyWith(color: accent),
                  );
                }),
              ),
              const SizedBox(height: 40),
              // Featured projects — full width, alternating
              for (int i = 0; i < projectsData.length; i++) ...[
                ScrollFadeIn(
                  delay: Duration(milliseconds: i * AppDurations.staggerShort.inMilliseconds),
                  child: _ProjectCard(
                    project: projectsData[i] as Map<String, dynamic>,
                    isReversed: !isMobile && i.isOdd,
                    isMobile: isMobile,
                  ),
                ),
                if (i < projectsData.length - 1) const SizedBox(height: 32),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// Project card — film strip style with border light
class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    this.isReversed = false,
    this.isMobile = false,
  });

  final Map<String, dynamic> project;
  final bool isReversed;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final p = project;
    final title = (p['title'] as String?) ?? 'Project';
    final description = (p['description'] as String?) ?? '';
    final technologies = _extractTechnologies(p);
    final url = _extractUrl(p);

    return Obx(() {
      final accent = Get.find<SceneDirector>().currentAccent.value;
      return GestureDetector(
        onTap: () => ProjectDetailOverlay.show(context, project),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: BorderLightCard(
            glowColor: accent,
            child: isMobile
                ? _buildMobileContent(title, description, technologies, url, accent)
                : _buildDesktopContent(title, description, technologies, url, accent),
          ),
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
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textBright,
              ),
              textAlign: isReversed ? TextAlign.right : TextAlign.left,
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
            child: Text(
              title,
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
