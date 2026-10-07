# 0005 — Strict JSON content contract

## Status

Accepted.

## Context

The canonical [portfolio document](../../assets/content/portfolio.json) declares schema version 11; translated [locale documents](../../assets/content/locales/) declare schema version 1. The [data mapper](../../lib/app/data/dto/portfolio_document_mapper.dart) rejects unsupported versions and missing or malformed fields; the [domain document](../../lib/app/domain/models/portfolio_document.dart) validates document-level invariants. The [asset loader](../../lib/app/data/providers/bundle_asset_loader.dart) reads bundled JSON, and [application bootstrap](../../lib/app/app_dependencies.dart) validates a locale before activating it. Packages use integer `maturity_level` values from 1 to 5 and a validated category; packages and writing carry `featured`, capped at five and three entries respectively.

## Decision

Keep factual identifiers, URLs, dates, and records in one canonical document. Treat locale documents as complete overlays of human-facing copy: a missing required translation fails the overlay instead of mixing languages silently. Validate schemas and content during [release checks](../../tool/content/validate_portfolio.dart) and at application load. Change schema versions when the contract changes incompatibly.

## Consequences

Content authors must update every required overlay when the translated contract changes. A failed locale load leaves the current language active or falls back during initialization, as implemented by [LanguageCubit](../../lib/app/features/language/application/language_cubit.dart). JSON traversal lives in data mappers, entity models are split, and localization uses `copyWith` through `PortfolioLocalizer`, which implements the domain localization contract. Map-valued asset/language contracts remain recorded in [technical debt](../TECH-DEBT.md).

## Alternatives considered

- Partial locale merges would reduce translation work but could create mixed-language pages.
- Duplicating factual fields in each locale would allow records to diverge.
