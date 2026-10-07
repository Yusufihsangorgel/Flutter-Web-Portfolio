import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

/// Gradient stops and accent of one scene.
final class ScenePalette {
  const ScenePalette({
    required this.gradient1,
    required this.gradient2,
    required this.gradient3,
    required this.accent,
  });

  final Color gradient1;
  final Color gradient2;
  final Color gradient3;
  final Color accent;
}

/// Palette and vignette configuration for a single chapter.
final class SceneConfig {
  const SceneConfig({required this.palette, this.vignetteIntensity = 0.4});

  const SceneConfig.document({this.vignetteIntensity = 0.3})
    : palette = const ScenePalette(
        gradient1: AppColors.sceneGradientStart,
        gradient2: AppColors.sceneGradientMiddle,
        gradient3: AppColors.sceneGradientEnd,
        accent: AppColors.accent,
      );

  final ScenePalette palette;
  final double vignetteIntensity;
  Color get gradient1 => palette.gradient1;
  Color get gradient2 => palette.gradient2;
  Color get gradient3 => palette.gradient3;
  Color get accent => palette.accent;

  /// Interpolates the palette and vignette between two chapters.
  static SceneConfig lerp(SceneConfig a, SceneConfig b, double t) =>
      SceneConfig(
        palette: ScenePalette(
          gradient1: Color.lerp(a.gradient1, b.gradient1, t)!,
          gradient2: Color.lerp(a.gradient2, b.gradient2, t)!,
          gradient3: Color.lerp(a.gradient3, b.gradient3, t)!,
          accent: Color.lerp(a.accent, b.accent, t)!,
        ),
        vignetteIntensity:
            a.vignetteIntensity +
            (b.vignetteIntensity - a.vignetteIntensity) * t,
      );
}

/// Scene configurations, indexed by narrative motif.
final class SceneConfigs {
  const SceneConfigs._();

  static const document = SceneConfig.document();
  static const proof = SceneConfig.document(vignetteIntensity: 0.25);
  static const projects = SceneConfig.document(vignetteIntensity: 0.4);
  static const scenes = [document, document, document, proof, projects];
}
