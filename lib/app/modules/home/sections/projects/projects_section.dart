import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-width engineering case studies sourced from the portfolio manifest.
///
/// This is intentionally not a card grid. Each system gets one complete stage
/// for its context, the decision that shaped it, and a direct source link.
final class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) {
          final language = context.read<LanguageCubit>();
          final portfolio = context.read<PortfolioDocument>();

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SceneAccentBuilder(
                  builder: (context, accent) => NumberedSectionHeading(
                    number: '04',
                    title: language.getText(
                      'projects_section.title',
                      defaultValue: 'Selected Systems',
                    ),
                    accent: accent,
                  ),
                ),
                const SizedBox(height: 52),
                for (var index = 0; index < portfolio.systems.length; index++)
                  SceneAccentBuilder(
                    builder: (context, accent) => _SystemCaseStudy(
                      system: portfolio.systems[index],
                      index: index,
                      accent: accent,
                      openLabel: language.getText(
                        'projects_section.open_project',
                        defaultValue: 'Open source',
                      ),
                      isLast: index == portfolio.systems.length - 1,
                    ),
                  ),
              ],
            ),
          );
        },
      );
}

final class _SystemCaseStudy extends StatelessWidget {
  const _SystemCaseStudy({
    required this.system,
    required this.index,
    required this.accent,
    required this.openLabel,
    required this.isLast,
  });

  final PortfolioSystem system;
  final int index;
  final Color accent;
  final String openLabel;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.desktop;
    final copy = _SystemCopy(
      system: system,
      index: index,
      accent: accent,
      openLabel: openLabel,
    );
    final visual = _SystemVisualStage(system: system, accent: accent);

    return Container(
      constraints: const BoxConstraints(minHeight: 660),
      padding: EdgeInsets.symmetric(vertical: compact ? 62 : 92),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: accent.withValues(alpha: 0.36)),
          bottom: isLast
              ? BorderSide(color: accent.withValues(alpha: 0.36))
              : BorderSide.none,
        ),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 48), visual],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              textDirection: index.isEven
                  ? TextDirection.ltr
                  : TextDirection.rtl,
              children: [
                Expanded(flex: 10, child: copy),
                const SizedBox(width: 84),
                Expanded(flex: 11, child: visual),
              ],
            ),
    );
  }
}

final class _SystemCopy extends StatelessWidget {
  const _SystemCopy({
    required this.system,
    required this.index,
    required this.accent,
    required this.openLabel,
  });

  final PortfolioSystem system;
  final int index;
  final Color accent;
  final String openLabel;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Directionality(
      textDirection: Directionality.of(context),
      child: Column(
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
              const SizedBox(width: 18),
              Expanded(
                child: Container(
                  height: 1,
                  color: accent.withValues(alpha: 0.42),
                ),
              ),
              const SizedBox(width: 18),
              Flexible(
                child: Text(
                  system.kind.toUpperCase(),
                  textAlign: TextAlign.end,
                  style: AppFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 38),
          Text(
            system.name,
            style: AppFonts.instrumentSerif(
              fontSize: width < Breakpoints.tablet ? 49 : 70,
              fontStyle: FontStyle.italic,
              color: AppColors.textBright,
              height: 0.93,
              letterSpacing: -1.8,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            system.summary,
            style: AppFonts.inter(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.72,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsetsDirectional.only(start: 18),
            decoration: BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(color: accent, width: 2),
              ),
            ),
            child: Text(
              system.decision,
              style: AppFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppColors.textBright,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 34),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              for (final technology in system.technologies)
                Text(
                  technology.toUpperCase(),
                  style: AppFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.65,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 38),
          CinematicFocusable(
            onTap: () => launchUrl(system.url, webOnlyWindowName: '_blank'),
            semanticLabel: '$openLabel: ${system.name}',
            semanticRole: CinematicControlRole.link,
            focusColor: accent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    openLabel.toUpperCase(),
                    style: AppFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.north_east_rounded, size: 16, color: accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _SystemVisualStage extends StatelessWidget {
  const _SystemVisualStage({required this.system, required this.accent});

  final PortfolioSystem system;
  final Color accent;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AspectRatio(
      aspectRatio: 1.15,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.backgroundDark.withValues(alpha: 0.62),
          border: Border.all(color: accent.withValues(alpha: 0.34)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _SystemVisualPainter(
                visual: system.visual,
                accent: accent,
              ),
            ),
            PositionedDirectional(
              start: 22,
              top: 20,
              child: Text(
                system.visual.wireValue.toUpperCase(),
                style: AppFonts.jetBrainsMono(
                  fontSize: 8,
                  color: accent,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            PositionedDirectional(
              end: 22,
              bottom: 20,
              child: Text(
                system.id.toUpperCase(),
                style: AppFonts.jetBrainsMono(
                  fontSize: 8,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

final class _SystemVisualPainter extends CustomPainter {
  const _SystemVisualPainter({required this.visual, required this.accent});

  final PortfolioVisual visual;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    switch (visual) {
      case PortfolioVisual.framePipeline:
        _drawFramePipeline(canvas, size);
        break;
      case PortfolioVisual.queueStates:
        _drawQueueStates(canvas, size);
        break;
      case PortfolioVisual.tenantRouting:
        _drawTenantRouting(canvas, size);
        break;
      case PortfolioVisual.weightedQueue:
        _drawWeightedQueue(canvas, size);
        break;
      case PortfolioVisual.spatialGrid:
        _drawSpatialGrid(canvas, size);
        break;
    }
    _drawRegistration(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.08)
      ..strokeWidth = 0.7;
    final step = size.shortestSide / 8;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawFramePipeline(Canvas canvas, Size size) {
    final line = Paint()
      ..color = accent.withValues(alpha: 0.68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final fill = Paint()..color = accent.withValues(alpha: 0.055);
    for (var index = 0; index < 5; index++) {
      final t = index / 4;
      final width = size.width * (0.18 + t * 0.24);
      final height = width * 0.62;
      final center = Offset(
        size.width * (0.18 + t * 0.64),
        size.height * (0.72 - math.sin(t * math.pi) * 0.44),
      );
      final rect = Rect.fromCenter(
        center: center,
        width: width,
        height: height,
      );
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate((t - 0.5) * 0.24)
        ..translate(-center.dx, -center.dy)
        ..drawRect(rect, fill)
        ..drawRect(rect, line..color = accent.withValues(alpha: 0.3 + t * 0.55))
        ..restore()
        ..drawCircle(center, 3.5 + t * 2, Paint()..color = accent);
    }
  }

  void _drawQueueStates(Canvas canvas, Size size) {
    final line = Paint()
      ..color = accent.withValues(alpha: 0.5)
      ..strokeWidth = 1.2;
    const columns = 4;
    for (var column = 0; column < columns; column++) {
      final x = size.width * (0.16 + column * 0.225);
      canvas.drawLine(
        Offset(x, size.height * 0.2),
        Offset(x, size.height * 0.82),
        line,
      );
      for (var row = 0; row < 3 + column % 2; row++) {
        final y = size.height * (0.28 + row * 0.145);
        final rect = Rect.fromCenter(
          center: Offset(x, y),
          width: size.width * 0.12,
          height: size.height * 0.07,
        );
        canvas
          ..drawRect(
            rect,
            Paint()
              ..color = accent.withValues(alpha: 0.06 + row * 0.025)
              ..style = PaintingStyle.fill,
          )
          ..drawRect(rect, line);
      }
      if (column < columns - 1) {
        canvas.drawLine(
          Offset(x + size.width * 0.06, size.height * 0.52),
          Offset(x + size.width * 0.165, size.height * 0.52),
          line,
        );
      }
    }
  }

  void _drawTenantRouting(Canvas canvas, Size size) {
    final line = Paint()
      ..color = accent.withValues(alpha: 0.68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final gateway = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.5),
      width: size.width * 0.22,
      height: size.height * 0.14,
    );
    canvas.drawRect(gateway, line);
    for (var index = 0; index < 4; index++) {
      final y = size.height * (0.23 + index * 0.18);
      final source = Offset(size.width * 0.12, y);
      final target = Offset(size.width * 0.88, y);
      final path = Path()
        ..moveTo(source.dx, source.dy)
        ..cubicTo(
          size.width * 0.3,
          y,
          size.width * 0.36,
          size.height * 0.5,
          gateway.left,
          size.height * 0.5,
        )
        ..moveTo(gateway.right, size.height * 0.5)
        ..cubicTo(
          size.width * 0.64,
          size.height * 0.5,
          size.width * 0.7,
          y,
          target.dx,
          target.dy,
        );
      canvas
        ..drawPath(
          path,
          line..color = accent.withValues(alpha: 0.28 + index * 0.13),
        )
        ..drawCircle(source, 4, Paint()..color = accent)
        ..drawCircle(target, 4, Paint()..color = accent);
    }
  }

  void _drawWeightedQueue(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.52);
    final maxRadius = size.shortestSide * 0.34;
    for (var ring = 0; ring < 4; ring++) {
      final radius = maxRadius * (0.36 + ring * 0.21);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi * 0.75,
        math.pi * (0.55 + ring * 0.24),
        false,
        Paint()
          ..color = accent.withValues(alpha: 0.3 + ring * 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3 + ring * 0.55,
      );
      final angle = -math.pi * 0.75 + math.pi * (0.55 + ring * 0.24);
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        4.0 + ring,
        Paint()..color = accent,
      );
    }
    canvas.drawCircle(center, 8, Paint()..color = accent);
  }

  void _drawSpatialGrid(Canvas canvas, Size size) {
    final points = <Offset>[];
    for (var row = 0; row < 5; row++) {
      for (var column = 0; column < 6; column++) {
        final jitterX = math.sin((row * 7 + column) * 1.8) * 9;
        final jitterY = math.cos((row + column * 5) * 1.4) * 8;
        points.add(
          Offset(
            size.width * (0.12 + column * 0.15) + jitterX,
            size.height * (0.2 + row * 0.15) + jitterY,
          ),
        );
      }
    }
    final line = Paint()
      ..color = accent.withValues(alpha: 0.2)
      ..strokeWidth = 0.9;
    for (var a = 0; a < points.length; a++) {
      for (var b = a + 1; b < points.length; b++) {
        if ((points[a] - points[b]).distance < size.shortestSide * 0.19) {
          canvas.drawLine(points[a], points[b], line);
        }
      }
      canvas.drawCircle(
        points[a],
        a % 5 == 0 ? 4.5 : 2.5,
        Paint()..color = accent.withValues(alpha: a % 5 == 0 ? 1 : 0.62),
      );
    }
  }

  void _drawRegistration(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.48)
      ..strokeWidth = 1;
    const inset = 14.0;
    const length = 12.0;
    for (final point in [
      const Offset(inset, inset),
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset),
    ]) {
      final dx = point.dx < size.width / 2 ? length : -length;
      final dy = point.dy < size.height / 2 ? length : -length;
      canvas
        ..drawLine(point, point + Offset(dx, 0), paint)
        ..drawLine(point, point + Offset(0, dy), paint);
    }
  }

  @override
  bool shouldRepaint(_SystemVisualPainter oldDelegate) =>
      oldDelegate.visual != visual || oldDelegate.accent != accent;
}
