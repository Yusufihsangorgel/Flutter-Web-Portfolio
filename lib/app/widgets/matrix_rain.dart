import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Matrix digital rain overlay — green falling characters on a black backdrop.
///
/// Automatically dismisses after [duration] (default 3 seconds).
/// Triggered as an easter egg by the Konami code sequence.
class MatrixRain extends StatefulWidget {
  const MatrixRain({
    super.key,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  });

  final Duration duration;
  final VoidCallback? onDismiss;

  @override
  State<MatrixRain> createState() => _MatrixRainState();
}

class _MatrixRainState extends State<MatrixRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Timer _dismissTimer;
  final _random = Random();

  // Column state — each column has its own speed, head position, and chars
  final List<_RainColumn> _columns = [];
  static const _columnWidth = 16.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    )..addListener(_tick);
    _controller.repeat();

    _dismissTimer = Timer(widget.duration, () {
      widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _dismissTimer.cancel();
    _controller
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      for (final column in _columns) {
        column.advance(_random);
      }
    });
  }

  void _initColumns(double width, double height) {
    final columnCount = (width / _columnWidth).ceil();
    if (_columns.length == columnCount) return;

    _columns.clear();
    final rowCount = (height / _columnWidth).ceil() + 4;

    for (var i = 0; i < columnCount; i++) {
      _columns.add(_RainColumn(
        rowCount: rowCount,
        initialOffset: _random.nextInt(rowCount),
        speed: 0.3 + _random.nextDouble() * 0.7,
        random: _random,
      ));
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          _initColumns(constraints.maxWidth, constraints.maxHeight);
          final rowCount =
              (constraints.maxHeight / _columnWidth).ceil() + 4;

          return Container(
            color: Colors.black.withValues(alpha: 0.92),
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _MatrixPainter(
                columns: _columns,
                columnWidth: _columnWidth,
                rowCount: rowCount,
                textStyle: GoogleFonts.jetBrainsMono(fontSize: 13),
              ),
            ),
          );
        },
      );
}

/// Tracks a single column's rain state.
class _RainColumn {
  _RainColumn({
    required this.rowCount,
    required int initialOffset,
    required this.speed,
    required Random random,
  }) : headPosition = initialOffset.toDouble() {
    chars = List.generate(
      rowCount,
      (_) => _randomChar(random),
    );
  }

  final int rowCount;
  final double speed;
  double headPosition;
  late final List<String> chars;

  static const _matrixChars =
      'abcdefghijklmnopqrstuvwxyz0123456789@#\$%&*+=<>{}[]|';

  static String _randomChar(Random random) =>
      _matrixChars[random.nextInt(_matrixChars.length)];

  void advance(Random random) {
    headPosition += speed;
    if (headPosition > rowCount + 12) {
      headPosition = -4;
    }
    // Randomly mutate one character per tick for glitch effect
    final mutateIndex = random.nextInt(chars.length);
    chars[mutateIndex] = _randomChar(random);
  }
}

/// Paints all rain columns using Canvas for performance.
class _MatrixPainter extends CustomPainter {
  _MatrixPainter({
    required this.columns,
    required this.columnWidth,
    required this.rowCount,
    required this.textStyle,
  });

  final List<_RainColumn> columns;
  final double columnWidth;
  final int rowCount;
  final TextStyle textStyle;

  static final Map<int, TextPainter> _painterCache = {};

  TextPainter _getPainter(String char, Color color) {
    final key = char.hashCode ^ color.toARGB32();
    var painter = _painterCache[key];
    if (painter == null) {
      painter = TextPainter(
        text: TextSpan(
          text: char,
          style: textStyle.copyWith(color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      _painterCache[key] = painter;
    }
    return painter;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var col = 0; col < columns.length; col++) {
      final column = columns[col];
      final x = col * columnWidth;
      final headRow = column.headPosition.floor();

      for (var row = 0; row < column.chars.length && row < rowCount; row++) {
        final y = row * columnWidth;
        if (y > size.height) break;

        final distFromHead = headRow - row;

        // Only draw characters near the trail
        if (distFromHead < 0 || distFromHead > 20) continue;

        final double alpha;
        if (distFromHead == 0) {
          alpha = 1.0;
        } else {
          alpha = (1.0 - distFromHead / 20.0).clamp(0.0, 0.8);
        }

        if (alpha <= 0.02) continue;

        final Color color;
        if (distFromHead == 0) {
          color = const Color(0xFFFFFFFF);
        } else if (distFromHead <= 2) {
          color = Color.fromRGBO(0, 255, 65, alpha);
        } else {
          color = Color.fromRGBO(0, 180, 40, alpha);
        }

        _getPainter(column.chars[row], color)
            .paint(canvas, Offset(x + 1, y));
      }
    }
  }

  @override
  bool shouldRepaint(_MatrixPainter oldDelegate) => true;
}
