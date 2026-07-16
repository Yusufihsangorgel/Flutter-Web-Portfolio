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
import 'package:flutter_web_portfolio/app/narrative/rendering/narrative_handoff_geometry.dart';
import 'package:flutter_web_portfolio/app/utils/motion_preference.dart';

/// A scroll-driven editorial portal carrying one chapter into the next.
///
/// The visible label and number are supplied by the external locale and
/// narrative documents. The portal remains decorative: the destination
/// chapter owns the actual heading and semantic node.
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
  final _typography = _HandoffTypographyCache();
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
        ? 360.0
        : width >= Breakpoints.tablet
        ? 280.0
        : 220.0;
    final progress = _progress!;
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
                from: widget.from,
                to: widget.to,
                progress: progress,
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
    required this.from,
    required this.to,
    required this.progress,
    required this.textDirection,
    required this.locale,
    required this.chapterNumber,
    required this.label,
    required this.typography,
  }) : super(repaint: progress);

  final NarrativeChapter from;
  final NarrativeChapter to;
  final ValueListenable<double> progress;
  final TextDirection textDirection;
  final Locale locale;
  final String chapterNumber;
  final String label;
  final _HandoffTypographyCache typography;

  final Paint _fillPaint = Paint()..isAntiAlias = true;
  final Paint _trackPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 0.8;
  final Paint _revealPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.3;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final palette = _ChapterPortalPalette.forMotif(to.motif);
    final eased = _smoothStep(progress.value.clamp(0.0, 1.0));
    final rtl = textDirection == TextDirection.rtl;

    _fillPaint
      ..style = PaintingStyle.fill
      ..color = palette.background;
    canvas.drawRect(Offset.zero & size, _fillPaint);
    _drawGrid(canvas, size, palette);

    final shape = NarrativeHandoffGeometry.resolve(
      size: size,
      from: from.motif,
      to: to.motif,
      textDirection: textDirection,
    );
    final path = shape.toPath();
    _trackPaint.color = palette.foreground.withValues(alpha: 0.18);
    canvas.drawPath(path, _trackPaint);

    _revealPaint.color = palette.foreground.withValues(alpha: 0.72);
    final pathReveal = rtl
        ? Rect.fromLTWH(
            size.width * (1 - eased),
            0,
            size.width * eased,
            size.height,
          )
        : Rect.fromLTWH(0, 0, size.width * eased, size.height);
    canvas
      ..save()
      ..clipRect(pathReveal)
      ..drawPath(path, _revealPaint)
      ..restore();

    typography.layout(
      size: size,
      palette: palette,
      textDirection: textDirection,
      locale: locale,
      chapterNumber: chapterNumber,
      label: label,
    );
    final outlineTitle = typography.outlineTitle;
    final filledTitle = typography.filledTitle;
    final invertedTitle = typography.invertedTitle;
    final titleStart = rtl
        ? size.width - outlineTitle.width + outlineTitle.width * 0.2
        : -outlineTitle.width * 0.2;
    final titleEnd = (size.width - outlineTitle.width) / 2;
    final titleX = ui.lerpDouble(titleStart, titleEnd, eased)!;
    final titleY = size.height * 0.38;
    final titleOffset = Offset(titleX, titleY);

    outlineTitle.paint(canvas, titleOffset);

    final textReveal = rtl
        ? Rect.fromLTWH(
            size.width * (1 - eased),
            0,
            size.width * eased,
            size.height,
          )
        : Rect.fromLTWH(0, 0, size.width * eased, size.height);
    canvas
      ..save()
      ..clipRect(textReveal);
    filledTitle.paint(canvas, titleOffset);
    canvas.restore();

    final bandWidth =
        size.width * (size.width >= Breakpoints.tablet ? 0.12 : 0.18);
    final bandInset = size.width >= Breakpoints.tablet ? 24.0 : 14.0;
    final bandLeading = ui.lerpDouble(
      rtl ? size.width + bandWidth : -bandWidth,
      rtl ? bandInset : size.width - bandWidth - bandInset,
      eased,
    )!;
    final band = Rect.fromLTWH(
      bandLeading,
      size.height * 0.2,
      bandWidth,
      size.height * 0.62,
    );
    _fillPaint.color = palette.accent;
    canvas
      ..drawRect(band, _fillPaint)
      ..save()
      ..clipRect(band);
    invertedTitle.paint(canvas, titleOffset);
    canvas.restore();

    _drawRail(canvas, size, palette, eased);
    _drawNodes(canvas, shape, palette, eased);
  }

  void _drawGrid(Canvas canvas, Size size, _ChapterPortalPalette palette) {
    _trackPaint
      ..strokeWidth = 0.65
      ..color = palette.foreground.withValues(alpha: 0.12);
    final upperY = size.height * 0.2;
    final lowerY = size.height * 0.82;
    canvas
      ..drawLine(Offset(0, upperY), Offset(size.width, upperY), _trackPaint)
      ..drawLine(Offset(0, lowerY), Offset(size.width, lowerY), _trackPaint);
    for (var column = 1; column < 4; column += 1) {
      final x = size.width * column / 4;
      canvas.drawLine(Offset(x, upperY), Offset(x, lowerY), _trackPaint);
    }
  }

  void _drawRail(
    Canvas canvas,
    Size size,
    _ChapterPortalPalette palette,
    double progress,
  ) {
    final railText = typography.railText;
    final inset = size.width >= Breakpoints.tablet ? 36.0 : 20.0;
    final rail = NarrativeHandoffRailGeometry.resolve(
      size: size,
      labelSize: railText.size,
      textDirection: textDirection,
      inset: inset,
      labelY: size.height * 0.085,
      lineY: size.height * 0.115,
    );
    railText.paint(canvas, rail.labelOffset);

    _trackPaint
      ..strokeWidth = 1
      ..color = palette.foreground.withValues(alpha: 0.3);
    canvas.drawLine(rail.lineStart, rail.lineEnd, _trackPaint);

    final progressEnd = Offset(
      ui.lerpDouble(rail.lineStart.dx, rail.lineEnd.dx, progress)!,
      rail.lineStart.dy,
    );
    _revealPaint
      ..strokeWidth = 2
      ..color = palette.accent;
    canvas.drawLine(rail.lineStart, progressEnd, _revealPaint);
  }

  void _drawNodes(
    Canvas canvas,
    NarrativeHandoffShape shape,
    _ChapterPortalPalette palette,
    double progress,
  ) {
    _fillPaint.color = palette.background;
    _revealPaint
      ..strokeWidth = 1.2
      ..color = palette.foreground.withValues(alpha: 0.65);
    for (final point in [shape.start, shape.end]) {
      canvas
        ..drawCircle(point, 4.5, _fillPaint)
        ..drawCircle(point, 4.5, _revealPaint);
    }
    final active = shape.pointAt(progress);
    _fillPaint.color = palette.accent;
    canvas.drawCircle(active, 4.2, _fillPaint);
  }

  static double _smoothStep(double value) => value * value * (3 - 2 * value);

  @override
  bool shouldRepaint(_NarrativeChapterHandoffPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      !identical(oldDelegate.progress, progress) ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.locale != locale ||
      oldDelegate.chapterNumber != chapterNumber ||
      oldDelegate.label != label ||
      !identical(oldDelegate.typography, typography);
}

/// Measured single-line typography used by a chapter handoff.
///
/// Exposed so narrow translated labels can be regression-tested without
/// relying on pixel sampling.
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

/// Locale-aware, measured typography for the decorative portal.
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
    final inset = size.width >= Breakpoints.tablet ? 36.0 : 20.0;
    final titleMaxWidth = math.max(1.0, size.width - inset * 2);
    final titleMaxHeight = size.height * 0.42;
    final titleFontSize = _fitSingleLineFontSize(
      text: chapterNumber,
      textDirection: textDirection,
      minFontSize: 36,
      maxFontSize: math.min(176, size.height * 0.43),
      maxWidth: titleMaxWidth,
      maxHeight: titleMaxHeight,
      styleFor: (fontSize) =>
          _titleStyle(fontSize: fontSize, color: AppColors.textBright),
    );
    final titleSize = _measure(
      text: chapterNumber,
      textDirection: textDirection,
      style: _titleStyle(fontSize: titleFontSize, color: AppColors.textBright),
    );

    // Preserve a visible rail after the full translated label. The text is
    // scaled from measured paragraph bounds; it is never clipped heuristically.
    final maxRailWidth = math.max(1.0, size.width - inset * 2 - 40);
    final railFontSize = _fitSingleLineFontSize(
      text: normalizedLabel,
      textDirection: textDirection,
      minFontSize: 6,
      maxFontSize: size.width >= Breakpoints.tablet ? 12 : 10,
      maxWidth: maxRailWidth,
      maxHeight: size.height * 0.12,
      styleFor: (fontSize) =>
          _railStyle(fontSize: fontSize, color: AppColors.textBright),
    );
    final railSize = _measure(
      text: normalizedLabel,
      textDirection: textDirection,
      style: _railStyle(fontSize: railFontSize, color: AppColors.textBright),
    );

    return NarrativeHandoffTypographyMetrics(
      normalizedLabel: normalizedLabel,
      titleFontSize: titleFontSize,
      titleSize: titleSize,
      railFontSize: railFontSize,
      railSize: railSize,
      maxRailWidth: maxRailWidth,
    );
  }

  static double _fitSingleLineFontSize({
    required String text,
    required TextDirection textDirection,
    required double minFontSize,
    required double maxFontSize,
    required double maxWidth,
    required double maxHeight,
    required TextStyle Function(double fontSize) styleFor,
  }) {
    var lower = minFontSize;
    var upper = math.max(minFontSize, maxFontSize);
    for (var iteration = 0; iteration < 14; iteration += 1) {
      final candidate = (lower + upper) / 2;
      final measured = _measure(
        text: text,
        textDirection: textDirection,
        style: styleFor(candidate),
      );
      if (measured.width <= maxWidth && measured.height <= maxHeight) {
        lower = candidate;
      } else {
        upper = candidate;
      }
    }
    return lower;
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

  static TextStyle _titleStyle({
    required double fontSize,
    required Color color,
  }) => AppFonts.spaceGrotesk(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    height: 0.9,
    letterSpacing: -fontSize * 0.045,
    color: color,
  );

  static TextStyle _railStyle({
    required double fontSize,
    required Color color,
  }) => AppFonts.jetBrainsMono(
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: color,
  );
}

final class _HandoffTypographyCache {
  TextPainter? _outlineTitle;
  TextPainter? _filledTitle;
  TextPainter? _invertedTitle;
  TextPainter? _railText;
  Size? _size;
  String? _chapterNumber;
  String? _normalizedLabel;
  TextDirection? _textDirection;
  Locale? _locale;
  _ChapterPortalPalette? _palette;

  TextPainter get outlineTitle => _outlineTitle!;
  TextPainter get filledTitle => _filledTitle!;
  TextPainter get invertedTitle => _invertedTitle!;
  TextPainter get railText => _railText!;

  void layout({
    required Size size,
    required _ChapterPortalPalette palette,
    required TextDirection textDirection,
    required Locale locale,
    required String chapterNumber,
    required String label,
  }) {
    final normalizedLabel = NarrativeHandoffTypography.uppercaseLabel(
      label.trim(),
      locale,
    );
    if (_size == size &&
        _chapterNumber == chapterNumber &&
        _normalizedLabel == normalizedLabel &&
        _textDirection == textDirection &&
        _locale == locale &&
        _palette == palette) {
      return;
    }

    _disposePainters();
    _size = size;
    _chapterNumber = chapterNumber;
    _normalizedLabel = normalizedLabel;
    _textDirection = textDirection;
    _locale = locale;
    _palette = palette;

    final metrics = NarrativeHandoffTypography.resolve(
      size: size,
      chapterNumber: chapterNumber,
      label: label,
      locale: locale,
      textDirection: textDirection,
    );
    final outline = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width >= Breakpoints.tablet ? 1.35 : 1
      ..color = palette.foreground.withValues(alpha: 0.42);
    _outlineTitle = TextPainter(
      text: TextSpan(
        text: chapterNumber,
        style: AppFonts.spaceGrotesk(
          fontSize: metrics.titleFontSize,
          fontWeight: FontWeight.w700,
          height: 0.9,
          letterSpacing: -metrics.titleFontSize * 0.045,
          foreground: outline,
        ),
      ),
      maxLines: 1,
      textDirection: textDirection,
    )..layout();
    _filledTitle = _titlePainter(
      text: chapterNumber,
      fontSize: metrics.titleFontSize,
      color: palette.foreground,
      textDirection: textDirection,
    );
    _invertedTitle = _titlePainter(
      text: chapterNumber,
      fontSize: metrics.titleFontSize,
      color: palette.onAccent,
      textDirection: textDirection,
    );
    _railText = TextPainter(
      text: TextSpan(
        text: metrics.normalizedLabel,
        style: AppFonts.jetBrainsMono(
          fontSize: metrics.railFontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: palette.foreground,
        ),
      ),
      maxLines: 1,
      textDirection: textDirection,
    )..layout();
  }

  TextPainter _titlePainter({
    required String text,
    required double fontSize,
    required Color color,
    required TextDirection textDirection,
  }) => TextPainter(
    text: TextSpan(
      text: text,
      style: AppFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 0.9,
        letterSpacing: -fontSize * 0.045,
        color: color,
      ),
    ),
    maxLines: 1,
    textDirection: textDirection,
  )..layout();

  void _disposePainters() {
    _outlineTitle?.dispose();
    _filledTitle?.dispose();
    _invertedTitle?.dispose();
    _railText?.dispose();
    _outlineTitle = null;
    _filledTitle = null;
    _invertedTitle = null;
    _railText = null;
  }

  void dispose() => _disposePainters();
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

@immutable
final class _ChapterPortalPalette {
  const _ChapterPortalPalette({
    required this.background,
    required this.foreground,
    required this.accent,
    required this.onAccent,
  });

  final Color background;
  final Color foreground;
  final Color accent;
  final Color onAccent;

  static _ChapterPortalPalette forMotif(NarrativeMotif motif) =>
      switch (motif) {
        NarrativeMotif.origin => const _ChapterPortalPalette(
          background: AppColors.paper,
          foreground: AppColors.textBright,
          accent: AppColors.cobalt,
          onAccent: AppColors.white,
        ),
        NarrativeMotif.timeline => const _ChapterPortalPalette(
          background: AppColors.cobalt,
          foreground: AppColors.white,
          accent: AppColors.acid,
          onAccent: AppColors.textBright,
        ),
        NarrativeMotif.branches => const _ChapterPortalPalette(
          background: AppColors.textBright,
          foreground: AppColors.white,
          accent: AppColors.cobalt,
          onAccent: AppColors.white,
        ),
        NarrativeMotif.bracket => const _ChapterPortalPalette(
          background: AppColors.acid,
          foreground: AppColors.textBright,
          accent: AppColors.cobalt,
          onAccent: AppColors.white,
        ),
        NarrativeMotif.thread => const _ChapterPortalPalette(
          background: Color(0xFFFF704F),
          foreground: AppColors.textBright,
          accent: AppColors.white,
          onAccent: AppColors.textBright,
        ),
      };
}

/// Resolves the persistent reveal state of one chapter boundary.
///
/// Only the currently active boundary interpolates. Boundaries earlier in the
/// configured narrative remain fully drawn, while later boundaries stay on
/// their quiet track until the reading position reaches them.
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
