# 0006 — Seven locales and demand-loaded subset fonts

## Status

Proposed.

## Context

The [content contract](../../assets/content/portfolio.json) and [interface catalogs](../../assets/i18n/) cover `en`, `tr`, `de`, `fr`, `es`, `ar`, and `hi`. [AppFonts](../../lib/app/core/theme/app_fonts.dart) uses bundled Inter, Space Grotesk, JetBrains Mono, Arabic, and Devanagari families. The current [font manifest](../../pubspec.yaml) bundles full font files, while the [release shell](../../tool/prepare_web_release.mjs) conditionally preloads Arabic or Devanagari for the selected locale. That preload is not proof that unused font bytes are excluded from the release.

## Decision

Keep seven supported locales. Subset the Latin families for glyphs used by the content contract, retain coverage needed by Arabic and Hindi, and load script-specific fonts only when their locale needs them. Preserve local, same-origin font delivery and the shell's locale-specific first-frame typography.

## Consequences

Font generation must be deterministic and checked against all seven catalogs, the static shell, and browser snapshots. Missing glyphs or premature font swaps would be user-visible failures. The current full font assets and manifest need implementation changes before this proposal can be marked Accepted.

## Alternatives considered

- Keeping full files for every visit is simple but increases the shipped font payload.
- Remote font services would add a runtime dependency and conflict with same-origin release assets.
