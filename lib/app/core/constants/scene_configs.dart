import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

/// Color and particle configuration for a single scroll scene.
final class SceneConfig {
  const SceneConfig({
    required this.gradient1,
    required this.gradient2,
    required this.gradient3,
    required this.accent,
    this.particleDensity = 1.0,
    this.particleSpeed = 1.0,
    this.vignetteIntensity = 0.4,
  });

  final Color gradient1;
  final Color gradient2;
  final Color gradient3;
  final Color accent;
  final double particleDensity;
  final double particleSpeed;
  final double vignetteIntensity;

  /// Lerp between two scene configs for crossfade
  static SceneConfig lerp(SceneConfig a, SceneConfig b, double t) => SceneConfig(
    gradient1: Color.lerp(a.gradient1, b.gradient1, t)!,
    gradient2: Color.lerp(a.gradient2, b.gradient2, t)!,
    gradient3: Color.lerp(a.gradient3, b.gradient3, t)!,
    accent: Color.lerp(a.accent, b.accent, t)!,
    particleDensity: a.particleDensity + (b.particleDensity - a.particleDensity) * t,
    particleSpeed: a.particleSpeed + (b.particleSpeed - a.particleSpeed) * t,
    vignetteIntensity: a.vignetteIntensity + (b.vignetteIntensity - a.vignetteIntensity) * t,
  );
}

/// Predefined scene configurations for each portfolio section.
final class SceneConfigs {
  const SceneConfigs._();

  static const scenes = [hero, about, experience, projects, contact];

  // Scene 0: Hero — Blade Runner 2049
  static const hero = SceneConfig(
    gradient1: AppColors.heroGradient1,
    gradient2: AppColors.heroGradient2,
    gradient3: AppColors.heroGradient3,
    accent: AppColors.heroAccent,
    particleDensity: 0.6,
    particleSpeed: 0.5,
    vignetteIntensity: 0.3,
  );

  // Scene 1: About — Dune
  static const about = SceneConfig(
    gradient1: AppColors.aboutGradient1,
    gradient2: AppColors.aboutGradient2,
    gradient3: AppColors.aboutGradient3,
    accent: AppColors.aboutAccent,
    particleDensity: 0.4,
    particleSpeed: 0.3,
    vignetteIntensity: 0.3,
  );

  // Scene 2: Experience — Matrix
  static const experience = SceneConfig(
    gradient1: AppColors.expGradient1,
    gradient2: AppColors.expGradient2,
    gradient3: AppColors.expGradient3,
    accent: AppColors.expAccent,
    particleDensity: 0.5,
    particleSpeed: 0.4,
    vignetteIntensity: 0.3,
  );

  // Scene 3: Projects — Spider-Verse
  static const projects = SceneConfig(
    gradient1: AppColors.projGradient1,
    gradient2: AppColors.projGradient2,
    gradient3: AppColors.projGradient3,
    accent: AppColors.projAccent,
    particleDensity: 0.6,
    particleSpeed: 0.5,
    vignetteIntensity: 0.25,
  );

  // Scene 4: Contact — Interstellar
  static const contact = SceneConfig(
    gradient1: AppColors.contactGradient1,
    gradient2: AppColors.contactGradient2,
    gradient3: AppColors.contactGradient3,
    accent: AppColors.contactAccent,
    particleDensity: 0.8,
    particleSpeed: 0.2,
    vignetteIntensity: 0.4,
  );
}
