import 'package:flutter/material.dart';

/// Centralized color palette for the cinematic portfolio theme.
final class AppColors {
  const AppColors._();

  // ─── Base (dark) ────────────────────────────────────────────────────
  static const background = Color(0xFF030014);
  static const backgroundDark = Color(0xFF010008);
  static const backgroundLight = Color(0xFF0F0A2A);
  static const backgroundHover = Color(0xFF1A1145);

  // ─── Text hierarchy (dark) ──────────────────────────────────────────
  static const textBright = Color(0xFFE8ECF4);
  static const textPrimary = Color(0xFF94A3B8);
  static const textSecondary = Color(0xFF475569);
  static const white = Color(0xFFF8FAFC);

  // ─── Scene: Hero — Blade Runner 2049 ──────────────────────────────
  static const heroGradient1 = Color(0xFF1E0B3E);
  static const heroGradient2 = Color(0xFF2D1055);
  static const heroGradient3 = Color(0xFF0891B2);
  static const heroAccent = Color(0xFF06B6D4);

  // ─── Scene: About — Dune ──────────────────────────────────────────
  static const aboutGradient1 = Color(0xFF451A03);
  static const aboutGradient2 = Color(0xFF78350F);
  static const aboutGradient3 = Color(0xFF1E1B4B);
  static const aboutAccent = Color(0xFFF59E0B);

  // ─── Scene: Experience — Matrix ────────────────────────────────────
  static const expGradient1 = Color(0xFF0F4C4C);
  static const expGradient2 = Color(0xFF064E3B);
  static const expGradient3 = Color(0xFF78350F);
  static const expAccent = Color(0xFF10B981);

  // ─── Scene: Projects — Spider-Verse ────────────────────────────────
  static const projGradient1 = Color(0xFF831843);
  static const projGradient2 = Color(0xFF9F1239);
  static const projGradient3 = Color(0xFF0C1445);
  static const projAccent = Color(0xFFF43F5E);

  // ─── Scene: Contact — Interstellar ─────────────────────────────────
  static const contactGradient1 = Color(0xFF0A0A0A);
  static const contactGradient2 = Color(0xFF171717);
  static const contactGradient3 = Color(0xFF1C1C1C);
  static const contactAccent = Color(0xFFF8FAFC);

  // ─── Semantic aliases ──────────────────────────────────────────────
  static const accent = heroAccent;
  static const accentMuted = Color(0x1A06B6D4);
  static const primary = accent;
  static const surface = backgroundLight;
  static const surfaceVariant = backgroundLight;
}
