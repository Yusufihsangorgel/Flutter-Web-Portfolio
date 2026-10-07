import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/features/render_quality/domain/render_quality.dart';

void main() {
  group('RenderQuality profiles', () {
    test('reduce decoration without changing content semantics', () {
      expect(RenderQuality.essential.profile.drawAmbientField, isFalse);
      expect(RenderQuality.balanced.profile.drawAmbientField, isTrue);
      expect(RenderQuality.full.profile.drawGrain, isTrue);
      expect(RenderQuality.essential.profile.trackPointer, isFalse);
      expect(RenderQuality.balanced.profile.trackPointer, isFalse);
      expect(RenderQuality.full.profile.trackPointer, isTrue);
    });

    test('compares profiles by render options', () {
      final profile = _profileWithOptions(
        drawAmbientField: true,
        drawGrain: false,
        trackPointer: true,
      );
      final equalProfile = _profileWithOptions(
        drawAmbientField: true,
        drawGrain: false,
        trackPointer: true,
      );

      expect(profile, equalProfile);
      expect(profile.hashCode, equalProfile.hashCode);
      expect([
        _profileWithOptions(
          drawAmbientField: false,
          drawGrain: false,
          trackPointer: true,
        ),
        _profileWithOptions(
          drawAmbientField: true,
          drawGrain: true,
          trackPointer: true,
        ),
        _profileWithOptions(
          drawAmbientField: true,
          drawGrain: false,
          trackPointer: false,
        ),
      ], everyElement(isNot(profile)));
    });
  });
}

RenderQualityProfile _profileWithOptions({
  required bool drawAmbientField,
  required bool drawGrain,
  required bool trackPointer,
}) => RenderQualityProfile(
  drawAmbientField: drawAmbientField,
  drawGrain: drawGrain,
  trackPointer: trackPointer,
);
