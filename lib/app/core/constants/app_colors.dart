import 'package:flutter/material.dart';

/// Centralized color palette for the portfolio.
final class AppColors {
  const AppColors._();

  // ─── Base document ──────────────────────────────────────────────────
  // A light editorial field lets the real work, project palettes, and
  // personal information carry the page instead of defaulting to the
  // familiar black developer-portfolio treatment.
  static const background = Color(0xFFF2EEE5);
  static const backgroundDark = Color(0xFFD4CEC1);
  static const backgroundLight = Color(0xFFFAF7EF);

  // ─── Text hierarchy ─────────────────────────────────────────────────
  static const textBright = Color(0xFF12110F);
  static const textPrimary = Color(0xFF403C36);
  static const textSecondary = Color(0xFF756E64);
  static const white = Color(0xFFFFFCF4);

  // ─── Signal palette ─────────────────────────────────────────────────
  static const cobalt = Color(0xFF1E51FF);
  static const acid = Color(0xFFE6FF57);
  static const paper = background;

  // ─── Ambient scene palette ─────────────────────────────────────────
  static const sceneGradientStart = background;
  static const sceneGradientMiddle = Color(0xFFD9E1FF);
  static const sceneGradientEnd = cobalt;

  // ─── Semantic aliases ──────────────────────────────────────────────
  static const accent = cobalt;
}
