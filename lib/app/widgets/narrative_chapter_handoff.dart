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
import 'package:flutter_web_portfolio/app/narrative/domain/smooth_step.dart';
import 'package:flutter_web_portfolio/app/utils/motion_preference.dart';

/// Marks the transition between adjacent chapters.
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
    _progress = _NarrativeBoundaryProgress((
      source: widget.position,
      chapterOrder: chapterOrder,
      from: widget.from,
      to: widget.to,
      reducedMotion: reducedMotion,
    ));
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
              painter: _NarrativeChapterHandoffPainter((
                to: widget.to,
                progress: _progress!,
                textDirection: Directionality.of(context),
                locale: locale,
                chapterNumber: widget.chapterNumber,
                label: widget.label,
                typography: _typography,
              )),
            ),
          ),
        ),
      ),
    );
  }
}

final class _NarrativeChapterHandoffPainter extends CustomPainter {
  _NarrativeChapterHandoffPainter(this.input) : super(repaint: input.progress);

  final ({
    NarrativeChapter to,
    ValueListenable<double> progress,
    TextDirection textDirection,
    Locale locale,
    String chapterNumber,
    String label,
    _HandoffTypographyCache typography,
  })
  input;

  NarrativeChapter get to => input.to;
  ValueListenable<double> get progress => input.progress;
  TextDirection get textDirection => input.textDirection;
  Locale get locale => input.locale;
  String get chapterNumber => input.chapterNumber;
  String get label => input.label;
  _HandoffTypographyCache get typography => input.typography;

  final Paint _trackPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _fillPaint = Paint()..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final accent = _accentFor(to.motif);
    final eased = smoothStep(progress.value.clamp(0.0, 1.0));
    final inset = size.width >= Breakpoints.tablet ? 36.0 : 20.0;
    final y = size.height * 0.5;
    final labelPainter = typography.layout((
      chapterNumber: chapterNumber,
      label: label,
      locale: locale,
      textDirection: textDirection,
      maxWidth: math.max(1, size.width * 0.46),
    ));
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

abstract final class NarrativeHandoffTypography {
  static String uppercaseLabel(String label, Locale locale) {
    final languageCode = locale.languageCode.toLowerCase();
    if (languageCode == 'tr' || languageCode == 'az') {
      return label.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
    }
    return label.toUpperCase();
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

  TextPainter layout(
    ({
      String chapterNumber,
      String label,
      Locale locale,
      TextDirection textDirection,
      double maxWidth,
    })
    input,
  ) {
    final (:chapterNumber, :label, :locale, :textDirection, :maxWidth) = input;
    final text =
        '$chapterNumber  '
        '${NarrativeHandoffTypography.uppercaseLabel(label.trim(), locale)}';
    if (_painter != null &&
        _text == text &&
        _textDirection == textDirection &&
        _maxWidth == maxWidth) {
      return _painter!;
    }
    final measured = NarrativeHandoffTypography._measureFitted(
      text: text,
      textDirection: textDirection,
      maxWidth: maxWidth,
      maxFontSize: maxWidth >= Breakpoints.tablet ? 11 : 9,
    );
    _painter?.dispose();
    _text = text;
    _textDirection = textDirection;
    _maxWidth = maxWidth;
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
  _NarrativeBoundaryProgress(
    ({
      ValueListenable<NarrativePosition> source,
      List<NarrativeChapter> chapterOrder,
      NarrativeChapter from,
      NarrativeChapter to,
      bool reducedMotion,
    })
    input,
  ) : source = input.source,
      chapterOrder = input.chapterOrder,
      from = input.from,
      to = input.to,
      reducedMotion = input.reducedMotion,
      _value = NarrativeHandoffReveal.resolve((
        snapshot: input.source.value,
        chapterOrder: input.chapterOrder,
        from: input.from,
        to: input.to,
        reducedMotion: input.reducedMotion,
      )) {
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
    final next = NarrativeHandoffReveal.resolve((
      snapshot: source.value,
      chapterOrder: chapterOrder,
      from: from,
      to: to,
      reducedMotion: reducedMotion,
    ));
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

/// Keeps completed chapter seams visible.
abstract final class NarrativeHandoffReveal {
  static double resolve(
    ({
      NarrativePosition snapshot,
      List<NarrativeChapter> chapterOrder,
      NarrativeChapter from,
      NarrativeChapter to,
      bool reducedMotion,
    })
    input,
  ) {
    final (:snapshot, :chapterOrder, :from, :to, :reducedMotion) = input;
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
