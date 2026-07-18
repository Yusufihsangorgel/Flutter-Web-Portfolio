import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/constants/motion_curves.dart';

void main() {
  group('MotionCurves', () {
    final namedCurves = <String, Curve>{
      'standard': MotionCurves.standard,
      'emphasizedDecelerate': MotionCurves.emphasizedDecelerate,
      'quickOut': MotionCurves.quickOut,
    };

    for (final entry in namedCurves.entries) {
      test('${entry.key} preserves endpoints and increases monotonically', () {
        final curve = entry.value;
        final values = <double>[
          for (var step = 0; step <= 20; step += 1) curve.transform(step / 20),
        ];
        expect(values.first, closeTo(0, 0.0001));
        expect(values.last, closeTo(1, 0.0001));
        for (var index = 1; index < values.length; index += 1) {
          expect(values[index], greaterThanOrEqualTo(values[index - 1]));
        }
      });
    }

    test('direct-feedback curves lead the symmetric transition early', () {
      final standardProgress = MotionCurves.standard.transform(0.25);
      expect(
        MotionCurves.emphasizedDecelerate.transform(0.25),
        greaterThan(standardProgress),
      );
      expect(
        MotionCurves.quickOut.transform(0.25),
        greaterThan(standardProgress),
      );
    });
  });
}
