import 'package:adaptive_render_budget/adaptive_render_budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdaptiveRenderBudgetConfig', () {
    test('keeps the documented defaults', () {
      const config = AdaptiveRenderBudgetConfig();

      expect(config.sampling.windowCapacity, 90);
      expect(config.sampling.minimumSamples, 36);
      expect(config.sampling.evaluationIntervalFrames, 6);
      expect(config.sampling.overloadThreshold, 1);
      expect(config.thresholds.downgradeP95Threshold, 1.08);
      expect(config.thresholds.downgradeOverloadedFraction, 0.15);
      expect(config.thresholds.recoveryP95Threshold, 0.78);
      expect(config.thresholds.recoveryOverloadedFraction, 0.02);
      expect(config.probe.probeSampleCount, 48);
      expect(config.probe.rollbackMinimumSamples, 12);
      expect(config.probe.rollbackP95Threshold, 1);
      expect(config.probe.rollbackOverloadedFraction, 0.08);
      expect(config.transition.cooldown, const Duration(seconds: 4));
      expect(config.transition.refreshRateResetTolerance, 0.05);
    });

    test('overrides one field without restating the others', () {
      const config = AdaptiveRenderBudgetConfig(
        sampling: RenderBudgetSampling(windowCapacity: 120),
      );

      expect(config.sampling.windowCapacity, 120);
      expect(config.sampling.minimumSamples, 36);
      expect(config.thresholds, const RenderBudgetThresholds());
    });

    test('compares every group by value', () {
      const config = AdaptiveRenderBudgetConfig(
        sampling: RenderBudgetSampling(windowCapacity: 120),
      );
      const same = AdaptiveRenderBudgetConfig(
        sampling: RenderBudgetSampling(windowCapacity: 120),
      );

      expect(config, same);
      expect(config.hashCode, same.hashCode);
      expect(config, isNot(const AdaptiveRenderBudgetConfig()));
      expect(
        const RenderBudgetSampling(minimumSamples: 30),
        isNot(const RenderBudgetSampling()),
      );
      expect(
        const RenderBudgetThresholds(recoveryP95Threshold: 0.5),
        isNot(const RenderBudgetThresholds()),
      );
      expect(
        const RenderBudgetProbe(rollbackMinimumSamples: 6),
        isNot(const RenderBudgetProbe()),
      );
      expect(
        const RenderBudgetTransitionSettings(cooldown: Duration.zero),
        isNot(const RenderBudgetTransitionSettings()),
      );
    });

    test('groups with equal fields share a hash code', () {
      expect(
        const RenderBudgetSampling(windowCapacity: 20).hashCode,
        const RenderBudgetSampling(windowCapacity: 20).hashCode,
      );
      expect(
        const RenderBudgetThresholds(downgradeP95Threshold: 1.2).hashCode,
        const RenderBudgetThresholds(downgradeP95Threshold: 1.2).hashCode,
      );
      expect(
        const RenderBudgetProbe(probeSampleCount: 40).hashCode,
        const RenderBudgetProbe(probeSampleCount: 40).hashCode,
      );
      expect(
        const RenderBudgetTransitionSettings(
          refreshRateResetTolerance: 0.1,
        ).hashCode,
        const RenderBudgetTransitionSettings(
          refreshRateResetTolerance: 0.1,
        ).hashCode,
      );
    });
  });

  group('AdaptiveRenderBudgetPolicy', () {
    test('accepts the defaults and exposes them through the policy', () {
      final policy = AdaptiveRenderBudgetPolicy();

      expect(policy.config, const AdaptiveRenderBudgetConfig());
      expect(policy.windowCapacity, 90);
      expect(policy.probeSampleCount, 48);
      expect(policy.cooldown, const Duration(seconds: 4));
    });

    test('accepts the configuration shown in the README', () {
      final policy = AdaptiveRenderBudgetPolicy(
        config: const AdaptiveRenderBudgetConfig(
          sampling: RenderBudgetSampling(
            windowCapacity: 120,
            minimumSamples: 48,
          ),
          transition: RenderBudgetTransitionSettings(
            cooldown: Duration(seconds: 6),
          ),
        ),
      );

      expect(policy.windowCapacity, 120);
      expect(policy.minimumSamples, 48);
      expect(policy.cooldown, const Duration(seconds: 6));
    });

    final invalidSettings =
        <({String reason, AdaptiveRenderBudgetConfig config, String argument})>[
          (
            reason: 'a window without capacity',
            config: const AdaptiveRenderBudgetConfig(
              sampling: RenderBudgetSampling(windowCapacity: 0),
            ),
            argument: 'windowCapacity',
          ),
          (
            reason: 'minimum samples beyond the window',
            config: const AdaptiveRenderBudgetConfig(
              sampling: RenderBudgetSampling(windowCapacity: 30),
            ),
            argument: 'minimumSamples',
          ),
          (
            reason: 'an evaluation interval beyond the window',
            config: const AdaptiveRenderBudgetConfig(
              sampling: RenderBudgetSampling(
                windowCapacity: 40,
                evaluationIntervalFrames: 41,
              ),
            ),
            argument: 'evaluationIntervalFrames',
          ),
          (
            reason: 'a non-finite overload threshold',
            config: const AdaptiveRenderBudgetConfig(
              sampling: RenderBudgetSampling(overloadThreshold: double.nan),
            ),
            argument: 'overloadThreshold',
          ),
          (
            reason: 'an infinite downgrade P95',
            config: const AdaptiveRenderBudgetConfig(
              thresholds: RenderBudgetThresholds(
                downgradeP95Threshold: double.infinity,
              ),
            ),
            argument: 'downgradeP95Threshold',
          ),
          (
            reason: 'a downgrade share above one',
            config: const AdaptiveRenderBudgetConfig(
              thresholds: RenderBudgetThresholds(
                downgradeOverloadedFraction: 1.5,
              ),
            ),
            argument: 'downgradeOverloadedFraction',
          ),
          (
            reason: 'a recovery P95 above the downgrade P95',
            config: const AdaptiveRenderBudgetConfig(
              thresholds: RenderBudgetThresholds(recoveryP95Threshold: 1.2),
            ),
            argument: 'recoveryP95Threshold',
          ),
          (
            reason: 'a recovery share above the downgrade share',
            config: const AdaptiveRenderBudgetConfig(
              thresholds: RenderBudgetThresholds(
                recoveryOverloadedFraction: 0.2,
              ),
            ),
            argument: 'recoveryOverloadedFraction',
          ),
          (
            reason: 'a probe shorter than the minimum samples',
            config: const AdaptiveRenderBudgetConfig(
              probe: RenderBudgetProbe(probeSampleCount: 12),
            ),
            argument: 'probeSampleCount',
          ),
          (
            reason: 'a probe longer than the window',
            config: const AdaptiveRenderBudgetConfig(
              probe: RenderBudgetProbe(probeSampleCount: 100),
            ),
            argument: 'probeSampleCount',
          ),
          (
            reason: 'a rollback minimum beyond the probe',
            config: const AdaptiveRenderBudgetConfig(
              probe: RenderBudgetProbe(rollbackMinimumSamples: 60),
            ),
            argument: 'rollbackMinimumSamples',
          ),
          (
            reason: 'a rollback P95 below the recovery P95',
            config: const AdaptiveRenderBudgetConfig(
              probe: RenderBudgetProbe(rollbackP95Threshold: 0.7),
            ),
            argument: 'rollbackP95Threshold',
          ),
          (
            reason: 'a rollback share equal to the recovery share',
            config: const AdaptiveRenderBudgetConfig(
              probe: RenderBudgetProbe(rollbackOverloadedFraction: 0.02),
            ),
            argument: 'rollbackOverloadedFraction',
          ),
          (
            reason: 'a negative cooldown',
            config: const AdaptiveRenderBudgetConfig(
              transition: RenderBudgetTransitionSettings(
                cooldown: Duration(microseconds: -1),
              ),
            ),
            argument: 'cooldown',
          ),
          (
            reason: 'a negative refresh-rate tolerance',
            config: const AdaptiveRenderBudgetConfig(
              transition: RenderBudgetTransitionSettings(
                refreshRateResetTolerance: -0.1,
              ),
            ),
            argument: 'refreshRateResetTolerance',
          ),
        ];

    for (final invalid in invalidSettings) {
      test('rejects ${invalid.reason}', () {
        expect(
          () => AdaptiveRenderBudgetPolicy(config: invalid.config),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.name,
              'name',
              invalid.argument,
            ),
          ),
        );
      });
    }
  });
}
