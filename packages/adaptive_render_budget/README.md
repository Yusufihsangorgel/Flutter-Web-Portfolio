# adaptive_render_budget

A Flutter package that turns frame timing pressure into an observable
rendering-quality state.

## What it does

- Normalizes build/raster work against the refresh rate supplied by a source.
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

## Refresh rate

`DisplayRefreshRateSource` follows the refresh rate the engine reports for a
view's display and notifies when that value changes.

**On the web that value is always 60 Hz.** The Flutter Web engine (checked
against Flutter 3.47) hard-codes `refreshRate` to 60 for every browser and
display; upstream tracks it in
[flutter/flutter#133562](https://github.com/flutter/flutter/issues/133562).
This package does not measure the browser's real cadence, so on a 120 Hz display
the budget stays 16.7 ms and an 8 ms frame still reads as `0.48`, not `0.96`.
A `requestAnimationFrame` interval would not fix that: it reports the frames the
browser actually delivered, so dropped frames and background-tab throttling
lower the measured rate and loosen the budget exactly when the page is under
pressure.

When the application knows the rate it targets, supply it instead:

```dart
final renderBudget = AdaptiveRenderBudgetController(
  timingSource: timingSource,
  refreshRateSource: FixedRefreshRateSource(120),
);
```

## Configuration

`AdaptiveRenderBudgetConfig` groups the tunables into `sampling`, `thresholds`,
`probe` and `transition`. Every field has a documented default, so override only
what you need:

```dart
final policy = AdaptiveRenderBudgetPolicy(
  config: const AdaptiveRenderBudgetConfig(
    sampling: RenderBudgetSampling(windowCapacity: 120, minimumSamples: 48),
    transition: RenderBudgetTransitionSettings(cooldown: Duration(seconds: 6)),
  ),
);
```

The policy throws an `ArgumentError` for incoherent combinations. The defaults
are conservative starting points, not device-performance claims: validate the
thresholds with profile or release telemetry for the target experience.
Debug-mode timings are not representative.

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

Run the package checks from the package directory:

```sh
flutter analyze
flutter test
```
