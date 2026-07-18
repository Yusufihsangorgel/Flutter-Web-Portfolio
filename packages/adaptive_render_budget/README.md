# adaptive_render_budget

A repository-local Flutter core package that turns frame timing pressure into a
small, observable rendering-quality state.

It is intentionally not published to pub.dev (`publish_to: none`). The public
surface is compact and production-oriented, but it may evolve with the
portfolio's rendering system.

## What it does

- Normalizes build/raster work against the active display refresh rate.
- Uses a bounded rolling window instead of reacting to isolated slow frames.
- Downgrades one quality tier after sustained pressure.
- Probes one tier upward only after a healthy recovery window.
- Rolls an unhealthy or inconclusive probe back to its last verified tier.
- Applies a cooldown after transitions to avoid oscillation.
- Exposes a BLoC-independent `ValueListenable<AdaptiveRenderBudgetState>`.
- Supports a runtime ceiling, pause/resume, deterministic sources, and clean
  listener disposal.

The package never decides which effects an application should remove. A
consumer maps `minimal`, `reduced`, and `full` to its own rendering choices.

## Frame-load model

Flutter build and raster stages are pipelined. For throughput, the window uses
the slower stage:

```text
critical work = max(build duration, raster duration)
frame budget  = 1 second / refresh rate
normalized load = critical work / frame budget
```

A normalized load of `1.0` consumes one display interval. As a result, the same
8 ms frame is roughly `0.48` at 60 Hz and `0.96` at 120 Hz.

The default policy values are conservative starting points. Validate thresholds
with profile or release telemetry for the target experience; debug-mode timings
are not representative.

## Integration

Create and own the sources alongside the controller:

```dart
late final SchedulerFrameTimingSource timingSource;
late final DisplayRefreshRateSource refreshRateSource;
late final AdaptiveRenderBudgetController renderBudget;

void initialize(FlutterView view) {
  timingSource = SchedulerFrameTimingSource();
  refreshRateSource = DisplayRefreshRateSource(view: view);
  renderBudget = AdaptiveRenderBudgetController(
    timingSource: timingSource,
    refreshRateSource: refreshRateSource,
  );
}

void dispose() {
  renderBudget.dispose();
  timingSource.dispose();
  refreshRateSource.dispose();
}
```

Render from the listenable without a state-management dependency:

```dart
ValueListenableBuilder<AdaptiveRenderBudgetState>(
  valueListenable: renderBudget,
  builder: (context, state, child) {
    return Scene(
      drawAmbientParticles: state.level == RenderBudgetLevel.full,
      drawBlurredGlass: state.level != RenderBudgetLevel.minimal,
      child: child!,
    );
  },
  child: const Content(),
)
```

Use a ceiling for accessibility, thermal, battery, or product constraints:

```dart
renderBudget.setCeiling(RenderBudgetLevel.reduced);
renderBudget.pause();
renderBudget.resume();
```

Raising the ceiling does not immediately raise quality. The controller waits
for a recovery window and verifies the higher tier with a probe.

## Ownership contract

The controller listens to injected sources but does not dispose them. This
allows one source to serve multiple controllers. Dispose objects in this order:

1. `AdaptiveRenderBudgetController`
2. `SchedulerFrameTimingSource`
3. `DisplayRefreshRateSource`

`pause()` detaches both sources and rolls back an in-flight probe. `resume()`
reattaches them with an empty evidence window and a fresh cooldown.

## Testing

The controller accepts custom implementations of:

- `RenderFrameTimingSource`
- `RefreshRateSource`
- `MonotonicClock`

This keeps policy tests deterministic without pumping frames or waiting for
wall-clock time.

Run package checks with your active workspace SDK:

```sh
flutter analyze
flutter test
```
