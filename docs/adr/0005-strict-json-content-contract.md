# 0005 — Strict JSON content contract

## Status

Accepted.

## Context

The canonical [portfolio document](../../assets/content/portfolio.json) declares schema version 10; translated [locale documents](../../assets/content/locales/) declare schema version 1. The [domain parser](../../lib/app/domain/models/portfolio_document.dart) rejects unsupported versions and missing or malformed required fields. The [asset loader](../../lib/app/data/providers/bundle_asset_loader.dart) reads bundled JSON, and [application bootstrap](../../lib/app/app_dependencies.dart) validates a locale before activating it.

## Decision

Keep factual identifiers, URLs, dates, and records in one canonical document. Treat locale documents as complete overlays of human-facing copy: a missing required translation fails the overlay instead of mixing languages silently. Validate schemas and content during [release checks](../../tool/validate_portfolio.dart) and at application load. Change schema versions when the contract changes incompatibly.

## Consequences

Content authors must update every required overlay when the translated contract changes. A failed locale load leaves the current language active or falls back during initialization, as implemented by [LanguageCubit](../../lib/app/features/language/application/language_cubit.dart). The current parser still uses `dynamic` for JSON traversal; [debt](../TECH-DEBT.md) records moving typed parsing toward the data boundary.

## Alternatives considered

- Partial locale merges would reduce translation work but could create mixed-language pages.
- Duplicating factual fields in each locale would allow records to diverge.
