import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';

void main() {
  group('CinematicCurves', () {
    // Collect all curves for batch testing
    final namedCurves = <String, Curve>{
      'easeInOutCinematic': CinematicCurves.easeInOutCinematic,
      'dramaticEntrance': CinematicCurves.dramaticEntrance,
      'revealDecel': CinematicCurves.revealDecel,
      'magneticPull': CinematicCurves.magneticPull,
      'sceneFade': CinematicCurves.sceneFade,
      'textReveal': CinematicCurves.textReveal,
      'hoverLift': CinematicCurves.hoverLift,
      'particleDrift': CinematicCurves.particleDrift,
    };

    test('all curve constants are non-null', () {
      for (final entry in namedCurves.entries) {
        expect(entry.value, isNotNull, reason: '${entry.key} should be non-null');
        expect(entry.value, isA<Curve>());
      }
    });

    for (final entry in namedCurves.entries) {
      test('${entry.key} returns 0.0 at t=0 and 1.0 at t=1', () {
        final curve = entry.value;
        expect(curve.transform(0.0), closeTo(0.0, 0.001),
            reason: '${entry.key} should start at 0.0');
        expect(curve.transform(1.0), closeTo(1.0, 0.001),
            reason: '${entry.key} should end at 1.0');
      });
    }

    for (final entry in namedCurves.entries) {
      test('${entry.key} is monotonically increasing', () {
        final curve = entry.value;
        final samples = [0.0, 0.25, 0.5, 0.75, 1.0];
        final values = samples.map(curve.transform).toList();

        for (var i = 1; i < values.length; i++) {
          expect(
            values[i],
            greaterThanOrEqualTo(values[i - 1]),
            reason: '${entry.key} should be monotonically increasing: '
                'value at ${samples[i]} (${values[i]}) should be >= '
                'value at ${samples[i - 1]} (${values[i - 1]})',
          );
        }
      });
    }

    test('all curves are Cubic instances', () {
      for (final entry in namedCurves.entries) {
        expect(entry.value, isA<Cubic>(),
            reason: '${entry.key} should be a Cubic curve');
      }
    });

    test('curves produce intermediate values between 0 and 1', () {
      for (final entry in namedCurves.entries) {
        final midValue = entry.value.transform(0.5);
        expect(midValue, greaterThan(0.0),
            reason: '${entry.key} at t=0.5 should be > 0');
        expect(midValue, lessThan(1.0),
            reason: '${entry.key} at t=0.5 should be < 1');
      }
    });
  });
}
