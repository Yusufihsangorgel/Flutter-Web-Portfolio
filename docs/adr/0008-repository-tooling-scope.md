# 0008 — Repository-owned release and verification tooling

## Status

Accepted.

## Context

The repository is both a portfolio and a reusable template. Its [`tool/`](../../tool/) directory initializes template content, refreshes public-source records, prepares the static release, and verifies hosting and bundle contracts. [`package.json`](../../package.json) exposes these operations; [CI](../../.github/workflows/ci.yml) runs the relevant checks. This makes template setup repeatable but increases the source and maintenance surface.

## Decision

Keep content, template, release, and verification tooling beside the application so a template user can build and check the same static output. Group tools by purpose with thin entry points and focused modules; share helpers where multiple tool areas need them. The renderer, initializer and release verifier have been split to meet the file limits. Keep external-source requests in tools, not Flutter UI.

## Consequences

The repository remains larger than a portfolio-only frontend; tooling changes need Node tests as well as application checks. [Technical debt](../TECH-DEBT.md) records outstanding limits and planned fixes. The [tooling guide](../TOOLING.md) maps folder responsibilities, entry points, npm/CI callers, and contribution conventions. Derive per-file callers and metrics from current code and checks. Node type checking, lint, and formatting run in the analyze job.

## Alternatives considered

- External release scripts would hide the template's build contract from its users.
- A minimal UI-only template would omit current content synchronization and deployment verification behavior.
