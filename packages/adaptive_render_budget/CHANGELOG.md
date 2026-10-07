## 0.1.0

- Initial release: rendering tiers (`minimal`, `reduced`, `full`) driven by
  normalized frame timings, with cooldowns, upward probes and rollback.
- `AdaptiveRenderBudgetConfig` groups the tunable settings and the policy
  validates them.
- Injectable timing, refresh-rate and clock sources for deterministic tests.
- On the web `DisplayRefreshRateSource` reports the engine's fixed 60 Hz; see
  the README for how to supply a different rate.
