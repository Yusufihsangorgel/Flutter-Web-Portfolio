import 'package:flutter/material.dart';

/// Centralized color palette for the portfolio.
final class AppColors {
  const AppColors._();

  // ─── Render Atlas base ──────────────────────────────────────────────
  // Near-black ink, warm paper, and one cobalt accent keep the document
  // visually coherent from the opening through the work index.
  static const background = Color(0xFF0B0B0D);
  static const backgroundDark = Color(0xFF050507);
  static const backgroundLight = Color(0xFF151519);
  static const backgroundHover = Color(0xFF202026);

  // ─── Text hierarchy (dark) ──────────────────────────────────────────
  static const textBright = Color(0xFFF2F0E9);
  static const textPrimary = Color(0xFFB8B6AF);
  static const textSecondary = Color(0xFF817F79);
  static const white = Color(0xFFFEFDF8);

  // ─── Signal palette ─────────────────────────────────────────────────
  static const electricCobalt = Color(0xFF5B6CFF);
  static const signalLime = Color(0xFFDFFF3F);
  static const hotCoral = Color(0xFFFF5A43);
  static const digitalIce = Color(0xFF68E4FF);
  static const paper = textBright;

  // ─── Hero palette ──────────────────────────────────────────────────
  static const heroGradient1 = Color(0xFF11132A);
  static const heroGradient2 = Color(0xFF20276A);
  static const heroGradient3 = electricCobalt;
  static const heroAccent = electricCobalt;

  // ─── Shared document palette ───────────────────────────────────────
  static const aboutGradient1 = heroGradient1;
  static const aboutGradient2 = heroGradient2;
  static const aboutGradient3 = electricCobalt;
  static const aboutAccent = electricCobalt;

  // ─── Experience palette ────────────────────────────────────────────
  static const expGradient1 = heroGradient1;
  static const expGradient2 = heroGradient2;
  static const expGradient3 = electricCobalt;
  static const expAccent = electricCobalt;

  // ─── Open-source palette ───────────────────────────────────────────
  static const projGradient1 = heroGradient1;
  static const projGradient2 = heroGradient2;
  static const projGradient3 = electricCobalt;
  static const projAccent = electricCobalt;

  // ─── Selected-work palette ────────────────────────────────────────
  static const contactGradient1 = heroGradient1;
  static const contactGradient2 = heroGradient2;
  static const contactGradient3 = electricCobalt;
  static const contactAccent = electricCobalt;

  // ─── Semantic aliases ──────────────────────────────────────────────
  static const accent = heroAccent;
  static const accentMuted = Color(0x245B6CFF);
  static const primary = accent;
  static const surface = backgroundLight;
  static const surfaceVariant = backgroundLight;
}
