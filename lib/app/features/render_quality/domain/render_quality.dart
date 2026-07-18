import 'package:flutter/foundation.dart';

/// Visual fidelity tiers for the restrained ambient background.
///
/// Every tier preserves the same content, section geometry, and semantics. Only
/// decorative work changes, so adaptation never changes the information
/// architecture of the portfolio.
enum RenderQuality {
  essential(
    RenderQualityProfile(
      drawAmbientField: false,
      drawGrain: false,
      trackPointer: false,
    ),
  ),
  balanced(
    RenderQualityProfile(
      drawAmbientField: true,
      drawGrain: false,
      trackPointer: false,
    ),
  ),
  full(
    RenderQualityProfile(
      drawAmbientField: true,
      drawGrain: true,
      trackPointer: true,
    ),
  );

  const RenderQuality(this.profile);

  final RenderQualityProfile profile;

  RenderQuality get lower => switch (this) {
    RenderQuality.full => RenderQuality.balanced,
    RenderQuality.balanced => RenderQuality.essential,
    RenderQuality.essential => RenderQuality.essential,
  };

  RenderQuality get higher => switch (this) {
    RenderQuality.essential => RenderQuality.balanced,
    RenderQuality.balanced => RenderQuality.full,
    RenderQuality.full => RenderQuality.full,
  };
}

@immutable
final class RenderQualityProfile {
  const RenderQualityProfile({
    required this.drawAmbientField,
    required this.drawGrain,
    required this.trackPointer,
  });

  final bool drawAmbientField;
  final bool drawGrain;
  final bool trackPointer;
}
