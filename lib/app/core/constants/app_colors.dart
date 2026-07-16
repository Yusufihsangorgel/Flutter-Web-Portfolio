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
  static const backgroundHover = Color(0xFFE7E0D4);

  // ─── Text hierarchy ─────────────────────────────────────────────────
  static const textBright = Color(0xFF12110F);
  static const textPrimary = Color(0xFF403C36);
  static const textSecondary = Color(0xFF756E64);
  static const white = Color(0xFFFFFCF4);

  // ─── Signal palette ─────────────────────────────────────────────────
  static const cobalt = Color(0xFF1E51FF);
  static const acid = Color(0xFFE6FF57);
  static const documentAccent = cobalt;
  static const paper = background;

  // ─── Hero palette ──────────────────────────────────────────────────
  static const heroGradient1 = background;
  static const heroGradient2 = Color(0xFFD9E1FF);
  static const heroGradient3 = cobalt;
  static const heroAccent = cobalt;

  // ─── Shared document palette ───────────────────────────────────────
  static const aboutGradient1 = heroGradient1;
  static const aboutGradient2 = heroGradient2;
  static const aboutGradient3 = documentAccent;
  static const aboutAccent = documentAccent;

  // ─── Experience palette ────────────────────────────────────────────
  static const expGradient1 = heroGradient1;
  static const expGradient2 = heroGradient2;
  static const expGradient3 = documentAccent;
  static const expAccent = documentAccent;

  // ─── Open-source palette ───────────────────────────────────────────
  static const projGradient1 = heroGradient1;
  static const projGradient2 = heroGradient2;
  static const projGradient3 = documentAccent;
  static const projAccent = documentAccent;

  // ─── Selected-work palette ────────────────────────────────────────
  static const contactGradient1 = heroGradient1;
  static const contactGradient2 = heroGradient2;
  static const contactGradient3 = documentAccent;
  static const contactAccent = documentAccent;

  // ─── Semantic aliases ──────────────────────────────────────────────
  static const accent = heroAccent;
  static const accentMuted = Color(0x241E51FF);
  static const primary = accent;
  static const surface = backgroundLight;
  static const surfaceVariant = backgroundLight;
}
