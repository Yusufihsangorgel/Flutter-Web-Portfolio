import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Text scramble effect on hover.
///
/// When the mouse enters, letters rapidly scramble through random glyphs
/// and resolve left-to-right over ~400ms. On mouse exit the original text
/// is restored instantly.
class TextScramble extends StatefulWidget {
  const TextScramble({
    super.key,
    required this.text,
    required this.style,
    this.scrambleDuration = const Duration(milliseconds: 400),
    this.tickInterval = const Duration(milliseconds: 30),
  });

  final String text;
  final TextStyle style;

  /// Total time for all characters to resolve.
  final Duration scrambleDuration;

  /// How often the random characters are refreshed.
  final Duration tickInterval;

  @override
  State<TextScramble> createState() => _TextScrambleState();
}

class _TextScrambleState extends State<TextScramble> {
  static const _glyphs = '!<>-_\\/[]{}=+*^?#\u2588\u2593\u2591\u2592\u2502\u2500';
  static final _random = Random();

  late String _displayText;
  Timer? _timer;

  /// Per-character resolve timestamp (ms since scramble start).
  List<int> _resolveAt = [];
  int _startMs = 0;
  bool _scrambling = false;

  @override
  void initState() {
    super.initState();
    _displayText = widget.text;
  }

  @override
  void didUpdateWidget(TextScramble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _stop();
      _displayText = widget.text;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startScramble() {
    if (_scrambling) return;
    _scrambling = true;
    _startMs = DateTime.now().millisecondsSinceEpoch;

    // Each character gets a random resolve time within the duration window.
    final totalMs = widget.scrambleDuration.inMilliseconds;
    _resolveAt = List.generate(widget.text.length, (i) {
      // Characters resolve roughly left-to-right, with some jitter.
      final base = (i / widget.text.length) * totalMs;
      final jitter = _random.nextInt((totalMs * 0.25).toInt().clamp(1, 200));
      return (base + jitter).toInt().clamp(0, totalMs);
    });

    _timer = Timer.periodic(widget.tickInterval, _tick);
  }

  void _tick(Timer timer) {
    final elapsed = DateTime.now().millisecondsSinceEpoch - _startMs;
    final buf = StringBuffer();
    var allResolved = true;

    for (var i = 0; i < widget.text.length; i++) {
      if (widget.text[i] == ' ') {
        buf.write(' ');
        continue;
      }
      if (elapsed >= _resolveAt[i]) {
        buf.write(widget.text[i]);
      } else {
        allResolved = false;
        buf.write(_glyphs[_random.nextInt(_glyphs.length)]);
      }
    }

    setState(() => _displayText = buf.toString());

    if (allResolved) {
      _stop();
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _scrambling = false;
    if (mounted) {
      setState(() => _displayText = widget.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    // During scramble we use a monospace font so character widths stay stable.
    final effectiveStyle = _scrambling
        ? GoogleFonts.jetBrainsMono(
            fontSize: widget.style.fontSize,
            fontWeight: widget.style.fontWeight,
            color: widget.style.color,
            letterSpacing: widget.style.letterSpacing,
            height: widget.style.height,
          )
        : widget.style;

    return MouseRegion(
      onEnter: (_) => _startScramble(),
      onExit: (_) => _stop(),
      child: Text(
        _displayText,
        style: effectiveStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
