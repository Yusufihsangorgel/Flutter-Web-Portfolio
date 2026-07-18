import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

/// Palette and geometry configuration for a single scroll chapter.
final class SceneConfig {
  const SceneConfig({
    required this.gradient1,
    required this.gradient2,
    required this.gradient3,
    required this.accent,
    this.vignetteIntensity = 0.4,
  });

  const SceneConfig.document({this.vignetteIntensity = 0.3})
    : gradient1 = AppColors.sceneGradientStart,
      gradient2 = AppColors.sceneGradientMiddle,
      gradient3 = AppColors.sceneGradientEnd,
      accent = AppColors.accent;

  final Color gradient1;
  final Color gradient2;
  final Color gradient3;
  final Color accent;

  final double vignetteIntensity;

  /// Interpolates the complete ambient palette between two chapters.
  static SceneConfig lerp(SceneConfig a, SceneConfig b, double t) =>
      SceneConfig(
        gradient1: Color.lerp(a.gradient1, b.gradient1, t)!,
        gradient2: Color.lerp(a.gradient2, b.gradient2, t)!,
        gradient3: Color.lerp(a.gradient3, b.gradient3, t)!,
        accent: Color.lerp(a.accent, b.accent, t)!,
        vignetteIntensity:
            a.vignetteIntensity +
            (b.vignetteIntensity - a.vignetteIntensity) * t,
      );
}

/// Predefined scene configurations for each portfolio section.
final class SceneConfigs {
  const SceneConfigs._();

  static const scenes = [hero, about, experience, proof, projects];

  static const hero = SceneConfig.document();
  static const about = SceneConfig.document();
  static const experience = SceneConfig.document();
  static const proof = SceneConfig.document(vignetteIntensity: 0.25);
  static const projects = SceneConfig.document(vignetteIntensity: 0.4);
}
