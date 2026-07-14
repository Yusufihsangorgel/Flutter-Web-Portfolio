import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/features/engineering_lab/domain/frame_statistics.dart';

void main() {
  group('FrameStatistics', () {
    test('returns an explicit empty summary without samples', () {
      final statistics = FrameStatistics.fromDurations(const []);

      expect(statistics.hasSamples, isFalse);
      expect(statistics.sampleCount, 0);
      expect(statistics.medianMilliseconds, 0);
      expect(statistics.p95Milliseconds, 0);
    });

    test('computes deterministic p50 and p95 values in milliseconds', () {
      final statistics = FrameStatistics.fromDurations([
        const Duration(milliseconds: 1),
        const Duration(milliseconds: 2),
        const Duration(milliseconds: 3),
        const Duration(milliseconds: 4),
        const Duration(milliseconds: 5),
        const Duration(milliseconds: 6),
        const Duration(milliseconds: 7),
        const Duration(milliseconds: 8),
        const Duration(milliseconds: 9),
        const Duration(milliseconds: 10),
      ]);

      expect(statistics.hasSamples, isTrue);
      expect(statistics.sampleCount, 10);
      expect(statistics.medianMilliseconds, 6);
      expect(statistics.p95Milliseconds, 10);
    });

    test('sorts unordered samples before calculating percentiles', () {
      final statistics = FrameStatistics.fromDurations([
        const Duration(microseconds: 12500),
        const Duration(microseconds: 2500),
        const Duration(microseconds: 7500),
      ]);

      expect(statistics.medianMilliseconds, 7.5);
      expect(statistics.p95Milliseconds, 12.5);
    });
  });
}
