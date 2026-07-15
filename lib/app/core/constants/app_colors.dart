import 'package:flutter/material.dart';

/// Centralized color palette for the portfolio.
final class AppColors {
  const AppColors._();

  // ─── Render Atlas base ──────────────────────────────────────────────
  // Near-black ink and warm paper replace the familiar blue-purple
  // developer-portfolio palette. Signal colours are intentionally sparse.
  static const background = Color(0xFF0B0B0D);
  static const backgroundDark = Color(0xFF050507);
  static const backgroundLight = Color(0xFF151519);
  static const backgroundHover = Color(0xFF202026);

  // ─── Text hierarchy (dark) ──────────────────────────────────────────
  static const textBright = Color(0xFFF2F0E9);
  static const textPrimary = Color(0xFFB8B6AF);
  static const textSecondary = Color(0xFF777671);
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

  // ─── About palette ─────────────────────────────────────────────────
  static const aboutGradient1 = Color(0xFF14190B);
  static const aboutGradient2 = Color(0xFF34400F);
  static const aboutGradient3 = signalLime;
  static const aboutAccent = signalLime;

  // ─── Experience palette ────────────────────────────────────────────
  static const expGradient1 = Color(0xFF24100D);
  static const expGradient2 = Color(0xFF522016);
  static const expGradient3 = hotCoral;
  static const expAccent = hotCoral;

  // ─── Approach palette ──────────────────────────────────────────────
  static const projGradient1 = Color(0xFF191814);
  static const projGradient2 = Color(0xFF302F29);
  static const projGradient3 = paper;
  static const projAccent = paper;

  // ─── Projects palette ──────────────────────────────────────────────
  static const contactGradient1 = Color(0xFF07171C);
  static const contactGradient2 = Color(0xFF0C3540);
  static const contactGradient3 = digitalIce;
  static const contactAccent = digitalIce;

  // ─── Semantic aliases ──────────────────────────────────────────────
  static const accent = heroAccent;
  static const accentMuted = Color(0x245B6CFF);
  static const primary = accent;
  static const surface = backgroundLight;
  static const surfaceVariant = backgroundLight;
}
