# 0006 — Seven locales and demand-loaded subset fonts

## Status

Accepted.

## Context

The [content contract](../../assets/content/portfolio.json) and [interface catalogs](../../assets/i18n/) cover `en`, `tr`, `de`, `fr`, `es`, `ar`, and `hi`. [AppFonts](../../lib/app/core/theme/app_fonts.dart) uses Inter, Space Grotesk, JetBrains Mono, Arabic, and Devanagari families. The [font manifest](../../pubspec.yaml) eagerly registers subset Latin families and small Arabic/Devanagari `-Shared` subsets for script glyphs in language names. Full Arabic and Devanagari files remain bundled as assets but [LocaleFontLoader](../../lib/app/core/theme/locale_font_loader.dart) registers them only for `ar` and `hi`. The shell preloads the selected script font only when needed.

## Decision

Keep seven supported locales. Generate Latin and shared-script subsets through [subset_fonts.mjs](../../tool/fonts/subset_fonts.mjs), preserving variation axes and required shaping features. Demand-load full script fonts for their locales. Preserve local, same-origin delivery and the shell's locale-specific first-frame typography.

## Consequences

`npm run verify:fonts` regenerates the five subsets in check mode, compares their bytes and verifies every locale's paintable text against the fonts actually available to that locale. Shared script glyphs are covered even on an English visit. `npm run test:fonts` calibrates subsetting and coverage; browser font tests bound the English font transfer and reject full Arabic/Devanagari requests on that visit. Full script fonts still occupy release bytes, but unused locales do not fetch them. Content refreshes must regenerate subsets before release checks; missing glyphs or stale subset bytes fail CI.

## Alternatives considered

- Keeping full files for every visit is simple but increases the shipped font payload.
- Remote font services would add a runtime dependency and conflict with same-origin release assets.
