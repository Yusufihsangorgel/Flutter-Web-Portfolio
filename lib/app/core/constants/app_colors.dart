import 'package:flutter/material.dart';

/// Centralized color palette for the portfolio.
final class AppColors {
  const AppColors._();

  static const background = Color(0xFFF2EEE5);
  static const backgroundDark = Color(0xFFD4CEC1);
  static const backgroundLight = Color(0xFFFAF7EF);

  static const textBright = Color(0xFF12110F);
  static const textPrimary = Color(0xFF403C36);
  static const textSecondary = Color(0xFF756E64);
  static const white = Color(0xFFFFFCF4);

  static const cobalt = Color(0xFF1E51FF);
  static const acid = Color(0xFFE6FF57);
  static const paper = background;

  static const sceneGradientStart = background;
  static const sceneGradientMiddle = Color(0xFFD9E1FF);
  static const sceneGradientEnd = cobalt;

  static const accent = cobalt;
  static const focusRing = accent;
}
