import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/narrative/application/narrative_position.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';
import 'package:flutter_web_portfolio/app/utils/motion_preference.dart';

/// A quiet chapter seam inside the portfolio's persistent narrative stage.
///
/// The former full-screen portals restarted the visual language between every
/// section. This seam only identifies the next chapter and leaves the measured
/// content-to-content signal in [NarrativeStage] visually uninterrupted.
class NarrativeChapterHandoff extends StatefulWidget {
  const NarrativeChapterHandoff({
    super.key,
    required this.from,
    required this.to,
    required this.position,
    required this.chapterNumber,
    required this.label,
  });

  final NarrativeChapter from;
  final NarrativeChapter to;
  final ValueListenable<NarrativePosition> position;
  final String chapterNumber;
  final String label;

  @override
  State<NarrativeChapterHandoff> createState() =>
      _NarrativeChapterHandoffState();
}

final class _NarrativeChapterHandoffState
    extends State<NarrativeChapterHandoff> {
  final _HandoffTypographyCache _typography = _HandoffTypographyCache();
  _NarrativeBoundaryProgress? _progress;
  List<NarrativeChapter>? _chapterOrder;
  bool? _reducedMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _synchronizeProgress();
  }

  @override
  void didUpdateWidget(covariant NarrativeChapterHandoff oldWidget) {
    super.didUpdateWidget(oldWidget);
    _synchronizeProgress();
  }

  void _synchronizeProgress() {
    final chapterOrder = context.read<NarrativeDocument>().chapters;
    final reducedMotion = prefersReducedMotion(context);
    final current = _progress;
    if (current != null &&
        identical(current.source, widget.position) &&
        current.from == widget.from &&
        current.to == widget.to &&
        listEquals(_chapterOrder, chapterOrder) &&
        _reducedMotion == reducedMotion) {
      return;
    }

    current?.dispose();
    _chapterOrder = chapterOrder;
    _reducedMotion = reducedMotion;
    _progress = _NarrativeBoundaryProgress(
      source: widget.position,
      chapterOrder: chapterOrder,
      from: widget.from,
      to: widget.to,
      reducedMotion: reducedMotion,
    );
  }

  @override
  void dispose() {
    _progress?.dispose();
    _typography.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = width >= Breakpoints.desktop
        ? 104.0
        : width >= Breakpoints.tablet
        ? 88.0
        : 72.0;
    final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');

    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: SizedBox(
            key: ValueKey(
              'handoff-${widget.from.id.value}-${widget.to.id.value}',
            ),
            width: double.infinity,
            height: height,
            child: CustomPaint(
              painter: _NarrativeChapterHandoffPainter(
                to: widget.to,
                progress: _progress!,
                textDirection: Directionality.of(context),
                locale: locale,
                chapterNumber: widget.chapterNumber,
                label: widget.label,
                typography: _typography,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _NarrativeChapterHandoffPainter extends CustomPainter {
  _NarrativeChapterHandoffPainter({
    required this.to,
    required this.progress,
    required this.textDirection,
    required this.locale,
    required this.chapterNumber,
    required this.label,
    required this.typography,
  }) : super(repaint: progress);

  final NarrativeChapter to;
  final ValueListenable<double> progress;
  final TextDirection textDirection;
  final Locale locale;
  final String chapterNumber;
  final String label;
  final _HandoffTypographyCache typography;

  final Paint _trackPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _fillPaint = Paint()..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final accent = _accentFor(to.motif);
    final eased = _smoothStep(progress.value.clamp(0.0, 1.0));
    final inset = size.width >= Breakpoints.tablet ? 36.0 : 20.0;
    final y = size.height * 0.5;
    final labelPainter = typography.layout(
      chapterNumber: chapterNumber,
      label: label,
      locale: locale,
      textDirection: textDirection,
      maxWidth: math.max(1, size.width * 0.46),
    );
    final rtl = textDirection == TextDirection.rtl;
    final labelX = rtl ? size.width - inset - labelPainter.width : inset;
    labelPainter.paint(canvas, Offset(labelX, y - labelPainter.height * 0.5));

    final lineStart = rtl
        ? Offset(labelX - 16, y)
        : Offset(labelX + labelPainter.width + 16, y);
    final lineEnd = rtl ? Offset(inset, y) : Offset(size.width - inset, y);
    if ((lineEnd.dx - lineStart.dx).abs() < 1) return;

    _trackPaint
      ..strokeWidth = 0.8
      ..color = AppColors.textBright.withValues(alpha: 0.18);
    canvas.drawLine(lineStart, lineEnd, _trackPaint);

    final active = Offset(ui.lerpDouble(lineStart.dx, lineEnd.dx, eased)!, y);
    _trackPaint
      ..strokeWidth = 1.5
      ..color = accent.withValues(alpha: 0.78);
    canvas.drawLine(lineStart, active, _trackPaint);

    _fillPaint.color = AppColors.paper.withValues(alpha: 0.96);
    canvas.drawCircle(active, 4.6, _fillPaint);
    _trackPaint
      ..strokeWidth = 1.2
      ..color = accent;
    canvas.drawCircle(active, 4.6, _trackPaint);
  }

  static Color _accentFor(NarrativeMotif motif) => switch (motif) {
    NarrativeMotif.origin => AppColors.cobalt,
    NarrativeMotif.thread => const Color(0xFFFF704F),
    NarrativeMotif.timeline => AppColors.cobalt,
    NarrativeMotif.branches => AppColors.textBright,
    NarrativeMotif.bracket => AppColors.cobalt,
  };

  static double _smoothStep(double value) => value * value * (3 - 2 * value);

  @override
  bool shouldRepaint(_NarrativeChapterHandoffPainter oldDelegate) =>
      oldDelegate.to != to ||
      !identical(oldDelegate.progress, progress) ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.locale != locale ||
      oldDelegate.chapterNumber != chapterNumber ||
      oldDelegate.label != label ||
      !identical(oldDelegate.typography, typography);
}

/// Measured single-line typography used by a chapter seam.
///
/// This public metric surface keeps locale and narrow-layout regressions
/// testable without relying on screenshot pixel sampling.
@immutable
final class NarrativeHandoffTypographyMetrics {
  const NarrativeHandoffTypographyMetrics({
    required this.normalizedLabel,
    required this.titleFontSize,
    required this.titleSize,
    required this.railFontSize,
    required this.railSize,
    required this.maxRailWidth,
  });

  final String normalizedLabel;
  final double titleFontSize;
  final Size titleSize;
  final double railFontSize;
  final Size railSize;
  final double maxRailWidth;
}

abstract final class NarrativeHandoffTypography {
  static String uppercaseLabel(String label, Locale locale) {
    final languageCode = locale.languageCode.toLowerCase();
    if (languageCode == 'tr' || languageCode == 'az') {
      return label.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
    }
    return label.toUpperCase();
  }

  static NarrativeHandoffTypographyMetrics resolve({
    required Size size,
    required String chapterNumber,
    required String label,
    required Locale locale,
    required TextDirection textDirection,
  }) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      throw ArgumentError.value(size, 'size', 'must be finite and positive');
    }
    final normalizedLabel = uppercaseLabel(label.trim(), locale);
    final titleFontSize = size.width >= Breakpoints.tablet ? 11.0 : 9.0;
    final railFontSize = titleFontSize;
    final maxRailWidth = math.max(1.0, size.width * 0.46);
    final titleSize = _measure(
      text: chapterNumber,
      textDirection: textDirection,
      style: _style(fontSize: titleFontSize, color: AppColors.cobalt),
    );
    final railSize = _measureFitted(
      text: '$chapterNumber  $normalizedLabel',
      textDirection: textDirection,
      maxWidth: maxRailWidth,
      maxFontSize: railFontSize,
    );
    return NarrativeHandoffTypographyMetrics(
      normalizedLabel: normalizedLabel,
      titleFontSize: titleFontSize,
      titleSize: titleSize,
      railFontSize: railSize.$2,
      railSize: railSize.$1,
      maxRailWidth: maxRailWidth,
    );
  }

  static (Size, double) _measureFitted({
    required String text,
    required TextDirection textDirection,
    required double maxWidth,
    required double maxFontSize,
  }) {
    var lower = 6.0;
    var upper = maxFontSize;
    for (var iteration = 0; iteration < 12; iteration += 1) {
      final candidate = (lower + upper) * 0.5;
      final size = _measure(
        text: text,
        textDirection: textDirection,
        style: _style(fontSize: candidate, color: AppColors.textBright),
      );
      if (size.width <= maxWidth) {
        lower = candidate;
      } else {
        upper = candidate;
      }
    }
    final size = _measure(
      text: text,
      textDirection: textDirection,
      style: _style(fontSize: lower, color: AppColors.textBright),
    );
    return (size, lower);
  }

  static Size _measure({
    required String text,
    required TextDirection textDirection,
    required TextStyle style,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: textDirection,
    )..layout();
    final size = painter.size;
    painter.dispose();
    return size;
  }

  static TextStyle _style({required double fontSize, required Color color}) =>
      AppFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: color,
      );
}

final class _HandoffTypographyCache {
  TextPainter? _painter;
  String? _text;
  TextDirection? _textDirection;
  double? _maxWidth;
  double? _fontSize;

  TextPainter layout({
    required String chapterNumber,
    required String label,
    required Locale locale,
    required TextDirection textDirection,
    required double maxWidth,
  }) {
    final text =
        '$chapterNumber  '
        '${NarrativeHandoffTypography.uppercaseLabel(label.trim(), locale)}';
    final measured = NarrativeHandoffTypography._measureFitted(
      text: text,
      textDirection: textDirection,
      maxWidth: maxWidth,
      maxFontSize: maxWidth >= Breakpoints.tablet ? 11 : 9,
    );
    if (_painter != null &&
        _text == text &&
        _textDirection == textDirection &&
        _maxWidth == maxWidth &&
        _fontSize == measured.$2) {
      return _painter!;
    }
    _painter?.dispose();
    _text = text;
    _textDirection = textDirection;
    _maxWidth = maxWidth;
    _fontSize = measured.$2;
    _painter = TextPainter(
      text: TextSpan(
        text: text,
        style: NarrativeHandoffTypography._style(
          fontSize: measured.$2,
          color: AppColors.textBright,
        ),
      ),
      maxLines: 1,
      textDirection: textDirection,
    )..layout(maxWidth: maxWidth);
    return _painter!;
  }

  void dispose() {
    _painter?.dispose();
    _painter = null;
  }
}

final class _NarrativeBoundaryProgress extends ChangeNotifier
    implements ValueListenable<double> {
  _NarrativeBoundaryProgress({
    required this.source,
    required this.chapterOrder,
    required this.from,
    required this.to,
    required this.reducedMotion,
  }) : _value = NarrativeHandoffReveal.resolve(
         snapshot: source.value,
         chapterOrder: chapterOrder,
         from: from,
         to: to,
         reducedMotion: reducedMotion,
       ) {
    if (!reducedMotion) source.addListener(_handleSourceChanged);
  }

  final ValueListenable<NarrativePosition> source;
  final List<NarrativeChapter> chapterOrder;
  final NarrativeChapter from;
  final NarrativeChapter to;
  final bool reducedMotion;
  double _value;

  @override
  double get value => _value;

  void _handleSourceChanged() {
    final next = NarrativeHandoffReveal.resolve(
      snapshot: source.value,
      chapterOrder: chapterOrder,
      from: from,
      to: to,
      reducedMotion: reducedMotion,
    );
    if (next == _value) return;
    _value = next;
    notifyListeners();
  }

  @override
  void dispose() {
    if (!reducedMotion) source.removeListener(_handleSourceChanged);
    super.dispose();
  }
}

/// Resolves the persistent reveal state of one chapter boundary.
///
/// Only the current seam interpolates. Earlier seams remain complete and later
/// seams stay quiet until the reader reaches them.
abstract final class NarrativeHandoffReveal {
  static double resolve({
    required NarrativePosition snapshot,
    required List<NarrativeChapter> chapterOrder,
    required NarrativeChapter from,
    required NarrativeChapter to,
    required bool reducedMotion,
  }) {
    if (reducedMotion) return 1;

    final fromIndex = chapterOrder.indexWhere(
      (chapter) => chapter.id == from.id,
    );
    final toIndex = chapterOrder.indexWhere((chapter) => chapter.id == to.id);
    assert(
      fromIndex >= 0 && toIndex == fromIndex + 1,
      'A handoff must connect adjacent chapters in narrative order.',
    );
    if (fromIndex < 0 || toIndex != fromIndex + 1) return 0;

    if (snapshot.currentSectionId == from.id.value &&
        snapshot.nextSectionId == to.id.value) {
      return snapshot.boundaryProgress.clamp(0.0, 1.0);
    }

    final currentIndex = chapterOrder.indexWhere(
      (chapter) => chapter.id.value == snapshot.currentSectionId,
    );
    if (currentIndex >= toIndex) return 1;

    final activeIndex = chapterOrder.indexWhere(
      (chapter) => chapter.id.value == snapshot.activeSectionId,
    );
    return activeIndex >= toIndex ? 1 : 0;
  }
}
