import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';
import 'package:url_launcher/url_launcher.dart';

/// A restrained, content-first showcase of selected products.
class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LanguageCubit, LanguageState>(
    builder: (context, _) {
      final language = context.read<LanguageCubit>();
      final projects = (language.cvData['projects'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();

      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScrollFadeIn(
              child: SceneAccentBuilder(
                builder: (context, accent) => NumberedSectionHeading(
                  number: '04',
                  title: language.getText(
                    'projects_section.title',
                    defaultValue: 'Selected Work',
                  ),
                  accent: accent,
                ),
              ),
            ),
            const SizedBox(height: 18),
            ScrollFadeIn(
              delay: AppDurations.staggerShort,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Text(
                  language.getText(
                    'projects_section.subtitle',
                    defaultValue:
                        'Products I designed, built, and continue to improve.',
                  ),
                  style: AppTypography.body.copyWith(height: 1.65),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _ProjectGrid(projects: projects),
          ],
        ),
      );
    },
  );
}

class _ProjectGrid extends StatelessWidget {
  const _ProjectGrid({required this.projects});

  final List<Map<String, dynamic>> projects;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 18.0;
      final isDesktop = constraints.maxWidth >= Breakpoints.desktop;
      final isTablet = constraints.maxWidth >= Breakpoints.tablet;
      final columnWidth = isDesktop
          ? (constraints.maxWidth - gap * 2) / 3
          : isTablet
          ? (constraints.maxWidth - gap) / 2
          : constraints.maxWidth;

      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (var index = 0; index < projects.length; index++)
            SizedBox(
              width: _cardWidth(
                index: index,
                isDesktop: isDesktop,
                columnWidth: columnWidth,
                gap: gap,
              ),
              child: ScrollFadeIn(
                delay: Duration(milliseconds: 55 * index),
                child: _ProjectCard(project: projects[index], index: index),
              ),
            ),
        ],
      );
    },
  );

  double _cardWidth({
    required int index,
    required bool isDesktop,
    required double columnWidth,
    required double gap,
  }) {
    if (!isDesktop) return columnWidth;
    if (index == 0 || index == 3) return columnWidth * 2 + gap;
    return columnWidth;
  }
}

class _ProjectCard extends StatefulWidget {
  const _ProjectCard({required this.project, required this.index});

  final Map<String, dynamic> project;
  final int index;

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _hovered = false;

  static const _palette = <Color>[
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFF0F766E),
    Color(0xFFBE123C),
    Color(0xFFC2410C),
    Color(0xFF4F46E5),
  ];

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final title = project['title'] as String? ?? 'Project';
    final description = project['description'] as String? ?? '';
    final category = project['category'] as String? ?? 'Product';
    final url = _projectUrl(project['url']);
    final domain = _domain(url);
    final accent = _palette[widget.index % _palette.length];
    final openLabel = context.read<LanguageCubit>().getText(
      'projects_section.open_project',
      defaultValue: 'Open Project',
    );

    return CinematicFocusable(
      semanticLabel: '$openLabel: $title',
      semanticRole: CinematicControlRole.link,
      borderRadius: BorderRadius.circular(24),
      onHoverChanged: (hovered) => setState(() => _hovered = hovered),
      onTap: () => _open(url),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 300),
        transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Color.lerp(
            AppColors.backgroundLight,
            accent,
            _hovered ? 0.10 : 0.055,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _hovered
                ? accent.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.09),
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.15),
                    blurRadius: 34,
                    offset: const Offset(0, 14),
                  ),
                ]
              : const [],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -24,
              child: Text(
                '${widget.index + 1}'.padLeft(2, '0'),
                style: AppFonts.spaceGrotesk(
                  fontSize: 112,
                  fontWeight: FontWeight.w800,
                  color: accent.withValues(alpha: 0.07),
                  height: 1,
                  letterSpacing: -8,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        category.toUpperCase(),
                        style: AppFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accent,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _hovered ? 0.06 : 0,
                      duration: AppDurations.fast,
                      child: Icon(
                        Icons.north_east_rounded,
                        color: _hovered ? accent : AppColors.textSecondary,
                        size: 23,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 58),
                Text(
                  title,
                  style: AppFonts.spaceGrotesk(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textBright,
                    height: 1.05,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  domain,
                  style: AppFonts.jetBrainsMono(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _projectUrl(Object? value) => switch (value) {
    final String url => url,
    final Map<String, dynamic> urls =>
      (urls['website'] ?? urls['google_play'] ?? urls['app_store'])
              ?.toString() ??
          '',
    _ => '',
  };

  String _domain(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;
    await launchUrl(uri, webOnlyWindowName: '_blank');
  }
}
