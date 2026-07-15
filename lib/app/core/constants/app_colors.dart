import 'package:flutter/material.dart';

/// Centralized color palette for the portfolio.
final class AppColors {
  const AppColors._();

  // ─── Render Atlas base ──────────────────────────────────────────────
  // Warm ink, uncoated paper, and oxidised clay replace the familiar
  // black-and-electric-blue developer-portfolio palette.
  static const background = Color(0xFF11100E);
  static const backgroundDark = Color(0xFF090806);
  static const backgroundLight = Color(0xFF1A1815);
  static const backgroundHover = Color(0xFF25221D);

  // ─── Text hierarchy (dark) ──────────────────────────────────────────
  static const textBright = Color(0xFFF4EFE4);
  static const textPrimary = Color(0xFFC4BCAF);
  static const textSecondary = Color(0xFF8E877C);
  static const white = Color(0xFFFFFCF4);

  // ─── Signal palette ─────────────────────────────────────────────────
  static const oxidisedClay = Color(0xFFE47A57);
  static const paper = textBright;

  // ─── Hero palette ──────────────────────────────────────────────────
  static const heroGradient1 = Color(0xFF18120F);
  static const heroGradient2 = Color(0xFF3A211A);
  static const heroGradient3 = oxidisedClay;
  static const heroAccent = oxidisedClay;

  // ─── Shared document palette ───────────────────────────────────────
  static const aboutGradient1 = heroGradient1;
  static const aboutGradient2 = heroGradient2;
  static const aboutGradient3 = oxidisedClay;
  static const aboutAccent = oxidisedClay;

  // ─── Experience palette ────────────────────────────────────────────
  static const expGradient1 = heroGradient1;
  static const expGradient2 = heroGradient2;
  static const expGradient3 = oxidisedClay;
  static const expAccent = oxidisedClay;

  // ─── Open-source palette ───────────────────────────────────────────
  static const projGradient1 = heroGradient1;
  static const projGradient2 = heroGradient2;
  static const projGradient3 = oxidisedClay;
  static const projAccent = oxidisedClay;

  // ─── Selected-work palette ────────────────────────────────────────
  static const contactGradient1 = heroGradient1;
  static const contactGradient2 = heroGradient2;
  static const contactGradient3 = oxidisedClay;
  static const contactAccent = oxidisedClay;

  // ─── Semantic aliases ──────────────────────────────────────────────
  static const accent = heroAccent;
  static const accentMuted = Color(0x24E47A57);
  static const primary = accent;
  static const surface = backgroundLight;
  static const surfaceVariant = backgroundLight;
}
