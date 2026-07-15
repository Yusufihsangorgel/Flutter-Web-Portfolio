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
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';
import 'package:url_launcher/url_launcher.dart';

/// Selected products with four visual highlights and a compact product index.
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
      if (projects.isEmpty) return const SizedBox.shrink();

      final featured = projects.take(4).toList();
      final archive = projects.skip(4).toList();

      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SceneAccentBuilder(
              builder: (context, accent) => NumberedSectionHeading(
                number: '04',
                title: language.getText(
                  'projects_section.title',
                  defaultValue: 'Selected Work',
                ),
                accent: accent,
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Text(
                language.getText(
                  'projects_section.subtitle',
                  defaultValue:
                      'Products I designed, built, and continue to improve.',
                ),
                style: AppTypography.body.copyWith(height: 1.65),
              ),
            ),
            const SizedBox(height: 44),
            _FeaturedWork(projects: featured, language: language),
            if (archive.isNotEmpty) ...[
              const SizedBox(height: 72),
              _ProjectArchive(
                projects: archive,
                startIndex: featured.length,
                title: language.getText(
                  'projects_section.archive',
                  defaultValue: 'More products',
                ),
                language: language,
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _FeaturedWork extends StatelessWidget {
  const _FeaturedWork({required this.projects, required this.language});

  final List<Map<String, dynamic>> projects;
  final LanguageCubit language;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 980;
      if (!desktop) {
        return Column(
          children: [
            for (var index = 0; index < projects.length; index++) ...[
              SizedBox(
                height: 440,
                child: _ProjectFeatureCard(
                  project: projects[index],
                  index: index,
                  language: language,
                  wide: false,
                ),
              ),
              if (index < projects.length - 1) const SizedBox(height: 18),
            ],
          ],
        );
      }

      return Column(
        children: [
          if (projects.isNotEmpty)
            SizedBox(
              height: 410,
              child: _ProjectFeatureCard(
                project: projects[0],
                index: 0,
                language: language,
                wide: true,
              ),
            ),
          if (projects.length > 1) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 430,
              child: Row(
                children: [
                  Expanded(
                    child: _ProjectFeatureCard(
                      project: projects[1],
                      index: 1,
                      language: language,
                      wide: false,
                    ),
                  ),
                  if (projects.length > 2) ...[
                    const SizedBox(width: 18),
                    Expanded(
                      child: _ProjectFeatureCard(
                        project: projects[2],
                        index: 2,
                        language: language,
                        wide: false,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (projects.length > 3) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 330,
              child: _ProjectFeatureCard(
                project: projects[3],
                index: 3,
                language: language,
                wide: true,
                reverse: true,
              ),
            ),
          ],
        ],
      );
    },
  );
}

class _ProjectFeatureCard extends StatefulWidget {
  const _ProjectFeatureCard({
    required this.project,
    required this.index,
    required this.language,
    required this.wide,
    this.reverse = false,
  });

  final Map<String, dynamic> project;
  final int index;
  final LanguageCubit language;
  final bool wide;
  final bool reverse;

  @override
  State<_ProjectFeatureCard> createState() => _ProjectFeatureCardState();
}

class _ProjectFeatureCardState extends State<_ProjectFeatureCard> {
  static const _palette = [
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFF43F5E),
  ];

  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final title = project['title'] as String? ?? '';
    final description = project['description'] as String? ?? '';
    final category = project['category'] as String? ?? 'Product';
    final url = project['url'] as String? ?? '';
    final accent = _palette[widget.index % _palette.length];
    final domain = _domain(url);
    final semanticLabel = widget.language.getText(
      'projects_section.open_project',
      defaultValue: 'Open Project',
    );

    final copy = _ProjectCopy(
      index: widget.index,
      title: title,
      description: description,
      category: category,
      domain: domain,
      accent: accent,
    );
    final preview = _ProjectPreview(kind: widget.index, accent: accent);

    return CinematicFocusable(
      onTap: () => _openProject(url),
      onHoverChanged: (hovered) => setState(() => _hovered = hovered),
      semanticLabel: '$semanticLabel: $title',
      semanticRole: CinematicControlRole.link,
      borderRadius: BorderRadius.circular(26),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: _hovered
                ? accent.withValues(alpha: 0.46)
                : Colors.white.withValues(alpha: 0.1),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: _hovered ? 0.2 : 0.13),
              AppColors.backgroundLight.withValues(alpha: 0.88),
              AppColors.background.withValues(alpha: 0.96),
            ],
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.12),
                    blurRadius: 36,
                    offset: const Offset(0, 18),
                  ),
                ]
              : const [],
        ),
        child: widget.wide
            ? Row(
                textDirection: widget.reverse
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                children: [
                  Expanded(
                    flex: 5,
                    child: Directionality(
                      textDirection: Directionality.of(context),
                      child: Padding(
                        padding: const EdgeInsets.all(36),
                        child: copy,
                      ),
                    ),
                  ),
                  Expanded(flex: 5, child: preview),
                ],
              )
            : Column(
                children: [
                  Expanded(flex: 5, child: preview),
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(26, 22, 26, 26),
                      child: copy,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProjectCopy extends StatelessWidget {
  const _ProjectCopy({
    required this.index,
    required this.title,
    required this.description,
    required this.category,
    required this.domain,
    required this.accent,
  });

  final int index;
  final String title;
  final String description;
  final String category;
  final String domain;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            category.toUpperCase(),
            style: AppFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: 1.4,
            ),
          ),
          const Spacer(),
          Text(
            '${index + 1}'.padLeft(2, '0'),
            style: AppFonts.jetBrainsMono(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.north_east_rounded,
            size: 17,
            color: AppColors.textSecondary,
          ),
        ],
      ),
      const SizedBox(height: 26),
      Text(
        title,
        style: AppFonts.spaceGrotesk(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.textBright,
          height: 1.05,
          letterSpacing: -0.7,
        ),
      ),
      const SizedBox(height: 13),
      Text(
        description,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(height: 1.6),
      ),
      const SizedBox(height: 20),
      Text(
        domain,
        style: AppFonts.jetBrainsMono(
          fontSize: 10,
          color: AppColors.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    ],
  );
}

class _ProjectPreview extends StatelessWidget {
  const _ProjectPreview({required this.kind, required this.accent});

  final int kind;
  final Color accent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF050412).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: switch (kind % 4) {
          0 => _CallPreview(accent: accent),
          1 => _GalleryPreview(accent: accent),
          2 => _FocusPreview(accent: accent),
          _ => _MoodPreview(accent: accent),
        },
      ),
    ),
  );
}

class _CallPreview extends StatelessWidget {
  const _CallPreview({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [accent, const Color(0xFF06B6D4)]),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 28),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Container(
        width: 120,
        height: 7,
        decoration: _barDecoration(Colors.white),
      ),
      const SizedBox(height: 9),
      Container(
        width: 74,
        height: 5,
        decoration: _barDecoration(AppColors.textSecondary),
      ),
      const Spacer(),
      const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RoundAction(color: Color(0xFFF43F5E), icon: Icons.call_end_rounded),
          SizedBox(width: 28),
          _RoundAction(color: Color(0xFF10B981), icon: Icons.videocam_rounded),
        ],
      ),
    ],
  );
}

class _GalleryPreview extends StatelessWidget {
  const _GalleryPreview({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 78,
            height: 6,
            decoration: _barDecoration(Colors.white),
          ),
          const Spacer(),
          Container(
            width: 42,
            height: 20,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Expanded(
        child: GridView.count(
          crossAxisCount: 3,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 7,
          crossAxisSpacing: 7,
          children: [
            for (var index = 0; index < 6; index++)
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.22 + index * 0.035),
                      const Color(0xFF1E1B4B),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: LinearProgressIndicator(
          value: 0.72,
          minHeight: 5,
          color: accent,
          backgroundColor: Colors.white.withValues(alpha: 0.07),
        ),
      ),
    ],
  );
}

class _FocusPreview extends StatelessWidget {
  const _FocusPreview({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Center(
          child: SizedBox.square(
            dimension: 118,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 0.76,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  color: accent,
                  backgroundColor: Colors.white.withValues(alpha: 0.07),
                ),
                Text(
                  '25:00',
                  style: AppFonts.spaceGrotesk(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textBright,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 18),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final width in const [82.0, 112.0, 94.0]) ...[
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Container(
                    width: width,
                    height: 5,
                    decoration: _barDecoration(AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    ],
  );
}

class _MoodPreview extends StatelessWidget {
  const _MoodPreview({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'WEEKLY PATTERN',
        style: AppFonts.jetBrainsMono(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: accent,
          letterSpacing: 1.1,
        ),
      ),
      const Spacer(),
      Expanded(
        flex: 4,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final height in const [
              0.42,
              0.65,
              0.5,
              0.82,
              0.74,
              0.92,
              0.68,
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FractionallySizedBox(
                    heightFactor: height,
                    alignment: Alignment.bottomCenter,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [accent.withValues(alpha: 0.35), accent],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          for (var index = 0; index < 4; index++) ...[
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12 + index * 0.08),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    ],
  );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Icon(icon, color: Colors.white, size: 20),
  );
}

class _ProjectArchive extends StatelessWidget {
  const _ProjectArchive({
    required this.projects,
    required this.startIndex,
    required this.title,
    required this.language,
  });

  final List<Map<String, dynamic>> projects;
  final int startIndex;
  final String title;
  final LanguageCubit language;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title.toUpperCase(),
        style: AppFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1.5,
        ),
      ),
      const SizedBox(height: 20),
      for (var index = 0; index < projects.length; index++)
        _ArchiveRow(
          project: projects[index],
          index: startIndex + index,
          language: language,
          isLast: index == projects.length - 1,
        ),
    ],
  );
}

class _ArchiveRow extends StatefulWidget {
  const _ArchiveRow({
    required this.project,
    required this.index,
    required this.language,
    required this.isLast,
  });

  final Map<String, dynamic> project;
  final int index;
  final LanguageCubit language;
  final bool isLast;

  @override
  State<_ArchiveRow> createState() => _ArchiveRowState();
}

class _ArchiveRowState extends State<_ArchiveRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.project['title'] as String? ?? '';
    final description = widget.project['description'] as String? ?? '';
    final url = widget.project['url'] as String? ?? '';
    final domain = _domain(url);
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    final semanticLabel = widget.language.getText(
      'projects_section.open_project',
      defaultValue: 'Open Project',
    );

    return CinematicFocusable(
      onTap: () => _openProject(url),
      onHoverChanged: (hovered) => setState(() => _hovered = hovered),
      semanticLabel: '$semanticLabel: $title',
      semanticRole: CinematicControlRole.link,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: EdgeInsets.symmetric(
          horizontal: _hovered ? 14 : 0,
          vertical: compact ? 24 : 28,
        ),
        decoration: BoxDecoration(
          color: _hovered
              ? Colors.white.withValues(alpha: 0.035)
              : Colors.transparent,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
            bottom: widget.isLast
                ? BorderSide(color: Colors.white.withValues(alpha: 0.09))
                : BorderSide.none,
          ),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _ArchiveNumber(index: widget.index),
                      const SizedBox(width: 14),
                      Expanded(child: _ArchiveTitle(title: title)),
                      const Icon(
                        Icons.north_east_rounded,
                        size: 17,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(description, style: AppTypography.bodySmall),
                  const SizedBox(height: 12),
                  _ArchiveDomain(domain: domain),
                ],
              )
            : Row(
                children: [
                  SizedBox(
                    width: 58,
                    child: _ArchiveNumber(index: widget.index),
                  ),
                  SizedBox(width: 210, child: _ArchiveTitle(title: title)),
                  const SizedBox(width: 26),
                  Expanded(
                    child: Text(description, style: AppTypography.bodySmall),
                  ),
                  const SizedBox(width: 28),
                  SizedBox(width: 160, child: _ArchiveDomain(domain: domain)),
                  const Icon(
                    Icons.north_east_rounded,
                    size: 17,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
      ),
    );
  }
}

class _ArchiveNumber extends StatelessWidget {
  const _ArchiveNumber({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) => Text(
    '${index + 1}'.padLeft(2, '0'),
    style: AppFonts.jetBrainsMono(fontSize: 10, color: AppColors.textSecondary),
  );
}

class _ArchiveTitle extends StatelessWidget {
  const _ArchiveTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: AppFonts.spaceGrotesk(
      fontSize: 19,
      fontWeight: FontWeight.w600,
      color: AppColors.textBright,
    ),
  );
}

class _ArchiveDomain extends StatelessWidget {
  const _ArchiveDomain({required this.domain});
  final String domain;

  @override
  Widget build(BuildContext context) => Text(
    domain,
    overflow: TextOverflow.ellipsis,
    style: AppFonts.jetBrainsMono(fontSize: 10, color: AppColors.textSecondary),
  );
}

BoxDecoration _barDecoration(Color color) => BoxDecoration(
  color: color.withValues(alpha: 0.6),
  borderRadius: BorderRadius.circular(8),
);

String _domain(String url) =>
    Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? url;

Future<void> _openProject(String rawUrl) async {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) return;
  await launchUrl(uri, webOnlyWindowName: '_blank');
}
