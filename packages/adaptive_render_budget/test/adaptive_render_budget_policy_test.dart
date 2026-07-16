import 'package:adaptive_render_budget/adaptive_render_budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts a coherent policy', () {
    final policy = AdaptiveRenderBudgetPolicy(
      windowCapacity: 20,
      minimumSamples: 10,
      probeSampleCount: 12,
    );

    expect(policy.windowCapacity, 20);
    expect(policy.minimumSamples, 10);
    expect(policy.probeSampleCount, 12);
  });

  test('rejects incoherent sample ranges', () {
    expect(
      () => AdaptiveRenderBudgetPolicy(windowCapacity: 10, minimumSamples: 11),
      throwsArgumentError,
    );
    expect(
      () => AdaptiveRenderBudgetPolicy(minimumSamples: 10, probeSampleCount: 9),
      throwsArgumentError,
    );
    expect(
      () => AdaptiveRenderBudgetPolicy(evaluationIntervalFrames: 91),
      throwsArgumentError,
    );
  });

  test('rejects non-finite thresholds and invalid fractions', () {
    expect(
      () => AdaptiveRenderBudgetPolicy(overloadThreshold: double.infinity),
      throwsArgumentError,
    );
    expect(
      () => AdaptiveRenderBudgetPolicy(downgradeOverloadedFraction: 1.1),
      throwsArgumentError,
    );
    expect(
      () => AdaptiveRenderBudgetPolicy(refreshRateResetTolerance: double.nan),
      throwsArgumentError,
    );
    expect(
      () => AdaptiveRenderBudgetPolicy(
        recoveryOverloadedFraction: 0.2,
        downgradeOverloadedFraction: 0.1,
      ),
      throwsArgumentError,
    );
    expect(
      () => AdaptiveRenderBudgetPolicy(
        recoveryP95Threshold: 0.8,
        rollbackP95Threshold: 0.7,
      ),
      throwsArgumentError,
    );
  });

  test('rejects a negative cooldown', () {
    expect(
      () => AdaptiveRenderBudgetPolicy(
        cooldown: const Duration(microseconds: -1),
      ),
      throwsArgumentError,
    );
  });
}
