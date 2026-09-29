# 0007 — Adaptive render budget and reduced motion

## Status

Accepted.

## Context

The local [budget package](../../packages/adaptive_render_budget/) normalizes frame build/raster pressure against a refresh-rate source, uses rolling evidence, and changes visual tiers with cooldown and probes. The [application adapter](../../lib/app/features/render_quality/application/render_quality_controller.dart) maps tiers to portfolio quality. The [motion helper](../../lib/app/utils/motion_preference_web.dart) reads `prefers-reduced-motion`.

## Decision

Keep frame-budget policy in the reusable local package and portfolio-specific visual choices in the application adapter. Reduced motion pauses adaptation and keeps a safe visual tier. Read the framework's display refresh report, fall back to 60 Hz when invalid, and expose the reported rate as an input to normalization rather than a verified physical panel measurement. In the [pinned Flutter SDK](../../tool/toolchain.json), both web display implementations initialize `EngineFlutterDisplay` with `refreshRate: 60` (`bin/cache/flutter_web_sdk/lib/ui/src/engine/display.dart` and `lib/_engine/engine/display.dart`).

## Consequences

Frame timing can lower or cautiously restore visual complexity without changing content. Reduced-motion users avoid adaptive effects. The source reads [`FlutterView.display.refreshRate`](../../packages/adaptive_render_budget/lib/src/sources.dart); with the pinned web engine's fixed 60 Hz report, the policy cannot infer the monitor's actual rate. Browser-frame observations would be needed to claim physical refresh-rate detection.

## Alternatives considered

- A fixed quality level would ignore sustained device pressure.
- Reacting to each slow frame would make quality oscillate during transient work.
