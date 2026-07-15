import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

/// Palette and geometry configuration for a single scroll chapter.
final class SceneConfig {
  const SceneConfig({
    required this.gradient1,
    required this.gradient2,
    required this.gradient3,
    required this.accent,
    required this.atlasMorph,
    this.vignetteIntensity = 0.4,
  });

  final Color gradient1;
  final Color gradient2;
  final Color gradient3;
  final Color accent;

  /// Continuous 0–4 coordinate used by the procedural Render Atlas.
  final double atlasMorph;
  final double vignetteIntensity;

  /// Lerp between two scene configs for crossfade
  static SceneConfig lerp(SceneConfig a, SceneConfig b, double t) =>
      SceneConfig(
        gradient1: Color.lerp(a.gradient1, b.gradient1, t)!,
        gradient2: Color.lerp(a.gradient2, b.gradient2, t)!,
        gradient3: Color.lerp(a.gradient3, b.gradient3, t)!,
        accent: Color.lerp(a.accent, b.accent, t)!,
        atlasMorph: a.atlasMorph + (b.atlasMorph - a.atlasMorph) * t,
        vignetteIntensity:
            a.vignetteIntensity +
            (b.vignetteIntensity - a.vignetteIntensity) * t,
      );
}

/// Predefined scene configurations for each portfolio section.
final class SceneConfigs {
  const SceneConfigs._();

  static const scenes = [hero, about, experience, proof, projects];

  // Chapter 0: Hero
  static const hero = SceneConfig(
    gradient1: AppColors.heroGradient1,
    gradient2: AppColors.heroGradient2,
    gradient3: AppColors.heroGradient3,
    accent: AppColors.heroAccent,
    atlasMorph: 0,
    vignetteIntensity: 0.3,
  );

  // Chapter 1: About
  static const about = SceneConfig(
    gradient1: AppColors.aboutGradient1,
    gradient2: AppColors.aboutGradient2,
    gradient3: AppColors.aboutGradient3,
    accent: AppColors.aboutAccent,
    atlasMorph: 1,
    vignetteIntensity: 0.3,
  );

  // Chapter 2: Experience
  static const experience = SceneConfig(
    gradient1: AppColors.expGradient1,
    gradient2: AppColors.expGradient2,
    gradient3: AppColors.expGradient3,
    accent: AppColors.expAccent,
    atlasMorph: 2,
    vignetteIntensity: 0.3,
  );

  // Chapter 3: Open source
  static const proof = SceneConfig(
    gradient1: AppColors.projGradient1,
    gradient2: AppColors.projGradient2,
    gradient3: AppColors.projGradient3,
    accent: AppColors.projAccent,
    atlasMorph: 3,
    vignetteIntensity: 0.25,
  );

  // Selected work section
  static const projects = SceneConfig(
    gradient1: AppColors.contactGradient1,
    gradient2: AppColors.contactGradient2,
    gradient3: AppColors.contactGradient3,
    accent: AppColors.contactAccent,
    atlasMorph: 4,
    vignetteIntensity: 0.4,
  );
}
