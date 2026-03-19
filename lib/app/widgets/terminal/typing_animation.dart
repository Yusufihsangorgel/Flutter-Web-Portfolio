import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/models/terminal_output_model.dart';

/// Helper class for terminal typing animation
class TypingAnimation {
  final math.Random _random = math.Random();

  /// Displays terminal output with a typewriter effect
  ///
  /// [output] The output to animate
  /// [onComplete] Callback invoked when the animation finishes
  /// [setState] Function used to trigger UI updates
  /// [baseDuration] Base delay between characters (ms)
  /// [randomVariation] Random variation added to the delay (ms)
  void simulateTyping({
    required TerminalOutputModel output,
    required VoidCallback onComplete,
    required Function(VoidCallback) setState,
    int baseDuration = 8,
    int randomVariation = 5,
  }) {
    if (output.content.isEmpty) {
      setState(() {
        output.isTyping = false;
        output.isCompleted = true;
      });
      onComplete();
      return;
    }

    final typingDelay = baseDuration + _random.nextInt(randomVariation);

    Future.delayed(Duration(milliseconds: typingDelay), () {
      setState(() {
        output.currentIndex++;

        if (output.currentIndex >= output.content.length) {
          output.isTyping = false;
          output.isCompleted = true;
          onComplete();
        } else {
          simulateTyping(
            output: output,
            onComplete: onComplete,
            setState: setState,
            baseDuration: baseDuration,
            randomVariation: randomVariation,
          );
        }
      });
    });
  }
}
