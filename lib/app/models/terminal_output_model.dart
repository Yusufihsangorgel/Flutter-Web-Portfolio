import 'package:flutter/material.dart';

/// Enum representing terminal output types
enum TerminalOutputType { text, command, error, system }

/// Model class representing a terminal output entry
class TerminalOutputModel {

  TerminalOutputModel({
    required this.content,
    this.type = TerminalOutputType.text,
    this.color = Colors.white,
    this.prefix = '',
    this.isBold = false,
    this.isTyping = false,
    this.isCompleted = false,
    this.currentIndex = 0,
    this.onTap,
  });
  String content;
  final TerminalOutputType type;
  final Color color;
  final String prefix;
  final bool isBold;
  final VoidCallback? onTap;

  /// Whether the typing animation is still in progress
  bool isTyping;

  /// Whether the typing animation has finished
  bool isCompleted;

  /// Current character index for the typing animation
  int currentIndex;
}
