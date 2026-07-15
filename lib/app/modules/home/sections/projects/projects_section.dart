import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';
import 'package:url_launcher/url_launcher.dart';

/// A spatial product archive: four full-width stages followed by an index.
///
/// There are deliberately no floating dashboard cards or device mock-ups.
/// Each featured product owns a distinct code-native signal composition.
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
      final archive = projects.skip(featured.length).toList();

      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
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
            const SizedBox(height: 22),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text(
                language.getText(
                  'projects_section.subtitle',
                  defaultValue:
                      'Products I designed, built, and continue to improve.',
                ),
                style: AppFonts.spaceGrotesk(
                  fontSize: 19,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                  height: 1.5,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(height: 58),
            for (var index = 0; index < featured.length; index++)
              _ProjectStage(
                project: featured[index],
                index: index,
                language: language,
              ),
            if (archive.isNotEmpty) ...[
              const SizedBox(height: 88),
              _ProjectIndex(
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

class _ProjectStage extends StatefulWidget {
  const _ProjectStage({
    required this.project,
    required this.index,
    required this.language,
  });

  final Map<String, dynamic> project;
  final int index;
  final LanguageCubit language;

  @override
  State<_ProjectStage> createState() => _ProjectStageState();
}

class _ProjectStageState extends State<_ProjectStage> {
  static const _signals = [
    AppColors.electricCobalt,
    AppColors.signalLime,
    AppColors.hotCoral,
    AppColors.digitalIce,
  ];

  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final title = project['title'] as String? ?? '';
    final description = project['description'] as String? ?? '';
    final category = project['category'] as String? ?? 'Product';
    final url = project['url'] as String? ?? '';
    final domain = _domain(url);
    final accent = _signals[widget.index % _signals.length];
    final openLabel = widget.language.getText(
      'projects_section.open_project',
      defaultValue: 'Open Project',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 880;
        final signal = _ProjectSignal(
          kind: widget.index,
          accent: accent,
          active: _hovered,
        );
        final copy = _ProjectStageCopy(
          title: title,
          description: description,
          category: category,
          domain: domain,
          index: widget.index,
          accent: accent,
          active: _hovered,
        );

        return CinematicFocusable(
          onTap: () => _openProject(url),
          onHoverChanged: (value) => setState(() => _hovered = value),
          semanticLabel: '$openLabel: $title',
          semanticRole: CinematicControlRole.link,
          focusColor: accent,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            height: desktop ? 440 : 520,
            decoration: BoxDecoration(
              color: _hovered
                  ? accent.withValues(alpha: 0.055)
                  : AppColors.backgroundDark.withValues(alpha: 0.42),
              border: Border(
                top: BorderSide(
                  color: _hovered
                      ? accent.withValues(alpha: 0.82)
                      : AppColors.textBright.withValues(alpha: 0.18),
                ),
              ),
            ),
            child: desktop
                ? Row(
                    textDirection: widget.index.isOdd
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    children: [
                      Expanded(
                        flex: 11,
                        child: Directionality(
                          textDirection: Directionality.of(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 46,
                              vertical: 40,
                            ),
                            child: copy,
                          ),
                        ),
                      ),
                      Expanded(flex: 9, child: signal),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(flex: 5, child: signal),
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
                          child: copy,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _ProjectStageCopy extends StatelessWidget {
  const _ProjectStageCopy({
    required this.title,
    required this.description,
    required this.category,
    required this.domain,
    required this.index,
    required this.accent,
    required this.active,
  });

  final String title;
  final String description;
  final String category;
  final String domain;
  final int index;
  final Color accent;
  final bool active;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            '${index + 1}'.padLeft(2, '0'),
            style: AppFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 34, height: 1, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: AppFonts.jetBrainsMono(
                fontSize: 9,
                color: AppColors.textPrimary,
                letterSpacing: 1.3,
              ),
            ),
          ),
          AnimatedRotation(
            turns: active ? 0.125 : 0,
            duration: AppDurations.fast,
            child: Icon(
              Icons.north_east_rounded,
              size: 19,
              color: active ? accent : AppColors.textSecondary,
            ),
          ),
        ],
      ),
      const Spacer(),
      AnimatedSlide(
        offset: active ? const Offset(0.02, 0) : Offset.zero,
        duration: AppDurations.fast,
        curve: Curves.easeOutCubic,
        child: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.instrumentSerif(
            fontSize: MediaQuery.sizeOf(context).width < Breakpoints.tablet
                ? 48
                : 68,
            fontStyle: FontStyle.italic,
            color: AppColors.textBright,
            height: 0.9,
            letterSpacing: -1.6,
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        description,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: AppFonts.inter(
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.6,
        ),
      ),
      const SizedBox(height: 18),
      Text(
        domain.toUpperCase(),
        overflow: TextOverflow.ellipsis,
        style: AppFonts.jetBrainsMono(
          fontSize: 9,
          color: active ? accent : AppColors.textSecondary,
          letterSpacing: 0.9,
        ),
      ),
    ],
  );
}

class _ProjectSignal extends StatelessWidget {
  const _ProjectSignal({
    required this.kind,
    required this.accent,
    required this.active,
  });

  final int kind;
  final Color accent;
  final bool active;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedContainer(
      duration: AppDurations.fast,
      color: accent.withValues(alpha: active ? 0.16 : 0.075),
      child: CustomPaint(
        painter: _ProjectSignalPainter(
          kind: kind,
          accent: accent,
          active: active,
        ),
        size: Size.infinite,
      ),
    ),
  );
}

class _ProjectSignalPainter extends CustomPainter {
  const _ProjectSignalPainter({
    required this.kind,
    required this.accent,
    required this.active,
  });

  final int kind;
  final Color accent;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final unit = math.min(size.width, size.height);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = active ? 1.8 : 1.1
      ..color = accent.withValues(alpha: active ? 0.88 : 0.58);
    final ghost = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = AppColors.textBright.withValues(alpha: 0.16);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withValues(alpha: active ? 0.22 : 0.11);

    _drawGrid(canvas, size, ghost);
    switch (kind % 4) {
      case 0:
        for (var index = 1; index <= 4; index++) {
          canvas.drawCircle(
            center,
            unit * index * 0.085,
            index.isEven ? line : ghost,
          );
        }
        canvas.drawLine(
          Offset(center.dx - unit * 0.32, center.dy + unit * 0.24),
          Offset(center.dx + unit * 0.32, center.dy - unit * 0.24),
          line,
        );
        canvas.drawCircle(center, unit * 0.055, fill);
      case 1:
        for (var index = 0; index < 7; index++) {
          final width = unit * (0.54 - index * 0.045);
          final height = unit * (0.1 + index * 0.025);
          final rect = Rect.fromCenter(
            center: center + Offset((index - 3) * 8, (index - 3) * 12),
            width: width,
            height: height,
          );
          canvas
            ..save()
            ..translate(rect.center.dx, rect.center.dy)
            ..rotate(-0.16)
            ..translate(-rect.center.dx, -rect.center.dy)
            ..drawRect(rect, index == 3 ? fill : line)
            ..restore();
        }
      case 2:
        final rect = Rect.fromCircle(center: center, radius: unit * 0.3);
        for (var index = 0; index < 5; index++) {
          canvas.drawArc(
            rect.deflate(index * unit * 0.035),
            -math.pi / 2 + index * 0.34,
            math.pi * (0.48 + index * 0.12),
            false,
            index.isEven ? line : ghost,
          );
        }
        canvas.drawLine(
          center,
          center + Offset(unit * 0.18, -unit * 0.12),
          line,
        );
      default:
        final barWidth = unit * 0.055;
        const heights = [0.18, 0.32, 0.48, 0.28, 0.58, 0.38, 0.22];
        for (var index = 0; index < heights.length; index++) {
          final x = center.dx + (index - 3) * barWidth * 1.65;
          final height = unit * heights[index];
          canvas.drawRect(
            Rect.fromLTWH(
              x - barWidth / 2,
              center.dy - height / 2,
              barWidth,
              height,
            ),
            index == 4 ? fill : line,
          );
        }
    }
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    const divisions = 8;
    for (var index = 1; index < divisions; index++) {
      final x = size.width * index / divisions;
      final y = size.height * index / divisions;
      canvas
        ..drawLine(Offset(x, 0), Offset(x, size.height), paint)
        ..drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ProjectSignalPainter oldDelegate) =>
      kind != oldDelegate.kind ||
      accent != oldDelegate.accent ||
      active != oldDelegate.active;
}

class _ProjectIndex extends StatelessWidget {
  const _ProjectIndex({
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
      Row(
        children: [
          Text(
            title.toUpperCase(),
            style: AppFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.contactAccent,
              letterSpacing: 1.45,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(child: Divider(color: Color(0x2EF2F0E9))),
          const SizedBox(width: 16),
          Text(
            '${projects.length.toString().padLeft(2, '0')} ENTRIES',
            style: AppFonts.jetBrainsMono(
              fontSize: 9,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      for (var index = 0; index < projects.length; index++)
        _IndexRow(
          project: projects[index],
          index: startIndex + index,
          language: language,
          isLast: index == projects.length - 1,
        ),
    ],
  );
}

class _IndexRow extends StatefulWidget {
  const _IndexRow({
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
  State<_IndexRow> createState() => _IndexRowState();
}

class _IndexRowState extends State<_IndexRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final title = project['title'] as String? ?? '';
    final category = project['category'] as String? ?? '';
    final url = project['url'] as String? ?? '';
    final domain = _domain(url);
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    final openLabel = widget.language.getText(
      'projects_section.open_project',
      defaultValue: 'Open Project',
    );

    return CinematicFocusable(
      onTap: () => _openProject(url),
      onHoverChanged: (value) => setState(() => _hovered = value),
      semanticLabel: '$openLabel: $title',
      semanticRole: CinematicControlRole.link,
      focusColor: AppColors.contactAccent,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: EdgeInsets.symmetric(
          horizontal: _hovered ? 16 : 0,
          vertical: compact ? 22 : 28,
        ),
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.contactAccent.withValues(alpha: 0.07)
              : Colors.transparent,
          border: Border(
            top: const BorderSide(color: Color(0x2EF2F0E9)),
            bottom: widget.isLast
                ? const BorderSide(color: Color(0x2EF2F0E9))
                : BorderSide.none,
          ),
        ),
        child: compact
            ? Row(
                children: [
                  SizedBox(width: 38, child: _IndexNumber(index: widget.index)),
                  Expanded(
                    child: _IndexTitle(title: title, active: _hovered),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.north_east_rounded,
                    size: 17,
                    color: _hovered
                        ? AppColors.contactAccent
                        : AppColors.textSecondary,
                  ),
                ],
              )
            : Row(
                children: [
                  SizedBox(width: 70, child: _IndexNumber(index: widget.index)),
                  Expanded(
                    flex: 4,
                    child: _IndexTitle(title: title, active: _hovered),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      category.toUpperCase(),
                      style: AppFonts.jetBrainsMono(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      domain.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.jetBrainsMono(
                        fontSize: 9,
                        color: _hovered
                            ? AppColors.contactAccent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.north_east_rounded,
                    size: 17,
                    color: _hovered
                        ? AppColors.contactAccent
                        : AppColors.textSecondary,
                  ),
                ],
              ),
      ),
    );
  }
}

class _IndexNumber extends StatelessWidget {
  const _IndexNumber({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) => Text(
    '${index + 1}'.padLeft(2, '0'),
    style: AppFonts.jetBrainsMono(fontSize: 9, color: AppColors.textSecondary),
  );
}

class _IndexTitle extends StatelessWidget {
  const _IndexTitle({required this.title, required this.active});
  final String title;
  final bool active;

  @override
  Widget build(BuildContext context) => Text(
    title,
    overflow: TextOverflow.ellipsis,
    style: AppFonts.spaceGrotesk(
      fontSize: MediaQuery.sizeOf(context).width < Breakpoints.tablet ? 19 : 25,
      fontWeight: FontWeight.w600,
      color: active ? AppColors.contactAccent : AppColors.textBright,
      letterSpacing: -0.45,
    ),
  );
}

String _domain(String url) =>
    Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? url;

Future<void> _openProject(String rawUrl) async {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) return;
  await launchUrl(uri, webOnlyWindowName: '_blank');
}
