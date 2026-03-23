import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// Character-by-character typewriter reveal with a blinking cursor.
///
/// After [delay], characters appear one at a time with a random interval
/// between [minCharDelay] and [maxCharDelay]. A blinking `|` cursor follows
/// the text while typing and blinks 3 times after completion before
/// disappearing.
class TypewriterText extends StatefulWidget {
  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.texts,
    this.delay = Duration.zero,
    this.minCharDelay = const Duration(milliseconds: 20),
    this.maxCharDelay = const Duration(milliseconds: 60),
    this.textAlign,
    this.loop = false,
    this.pauseBetween = const Duration(seconds: 2),
  });

  final String text;

  /// Optional list of texts to cycle through. When provided, [text] is ignored
  /// and the widget types each string in order, erasing and retyping the next.
  final List<String>? texts;

  /// Whether to loop back to the first text after the last.
  final bool loop;

  /// Pause duration between typing the next text.
  final Duration pauseBetween;
  final TextStyle style;
  final Duration delay;
  final Duration minCharDelay;
  final Duration maxCharDelay;
  final TextAlign? textAlign;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  static final _random = Random();

  int _charCount = 0;
  bool _showCursor = false;
  bool _typingDone = false;
  Timer? _typeTimer;
  Timer? _blinkTimer;
  int _blinkCount = 0;
  int _textIndex = 0;

  @override
  void initState() {
    super.initState();
    _scheduleStart();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _blinkTimer?.cancel();
    super.dispose();
  }

  void _scheduleStart() {
    if (widget.delay == Duration.zero) {
      _startTyping();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _startTyping();
      });
    }
  }

  void _startTyping() {
    setState(() => _showCursor = true);
    _typeNextChar();
  }

  void _typeNextChar() {
    if (!mounted) return;

    if (_charCount >= _currentText.length) {
      _onTypingComplete();
      return;
    }

    final delay = Duration(
      milliseconds: widget.minCharDelay.inMilliseconds +
          _random.nextInt(
            widget.maxCharDelay.inMilliseconds -
                widget.minCharDelay.inMilliseconds +
                1,
          ),
    );

    _typeTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() => _charCount++);
      _typeNextChar();
    });
  }

  void _onTypingComplete() {
    final hasMultiple = _activeTexts.length > 1;

    if (hasMultiple) {
      // Pause, then erase and type next
      _blinkTimer = Timer(widget.pauseBetween, () {
        if (!mounted) return;
        _startErasing();
      });
      return;
    }

    _typingDone = true;
    _blinkCount = 0;

    // Blink cursor 3 times (6 toggles: on-off-on-off-on-off) then hide.
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _blinkCount++;
      if (_blinkCount >= 6) {
        timer.cancel();
        setState(() => _showCursor = false);
        return;
      }
      setState(() => _showCursor = !_showCursor);
    });
  }

  void _startErasing() {
    _eraseNextChar();
  }

  void _eraseNextChar() {
    if (!mounted) return;
    if (_charCount <= 0) {
      _textIndex = (_textIndex + 1) % _activeTexts.length;
      if (!widget.loop && _textIndex == 0) {
        // Reached the end without loop — stop.
        setState(() => _showCursor = false);
        return;
      }
      _typeNextChar();
      return;
    }
    _typeTimer = Timer(const Duration(milliseconds: 25), () {
      if (!mounted) return;
      setState(() => _charCount--);
      _eraseNextChar();
    });
  }

  List<String> get _activeTexts => widget.texts ?? [widget.text];
  String get _currentText => _activeTexts[_textIndex];

  @override
  Widget build(BuildContext context) {
    final visibleText = _currentText.substring(0, _charCount.clamp(0, _currentText.length));
    final cursorChar = _showCursor ? '|' : '';

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: visibleText),
          if (_showCursor || (!_typingDone && _charCount == 0))
            TextSpan(
              text: cursorChar,
              style: widget.style.copyWith(
                fontWeight: FontWeight.w300,
              ),
            ),
        ],
      ),
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}
