# 0008 — Repository-owned release and verification tooling

## Status

Accepted.

## Context

The repository is both a portfolio and a reusable template. Its [`tool/`](../../tool/) directory initializes template content, refreshes public-source records, prepares the static release, and verifies hosting and bundle contracts. [`package.json`](../../package.json) exposes these operations; [CI](../../.github/workflows/ci.yml) runs the relevant checks. This makes template setup repeatable but increases the source and maintenance surface.

## Decision

Keep content, template, release, and verification tooling beside the application so a template user can build and check the same static output. Consolidate duplicated source parsing, release-file traversal, and host-policy checks into focused shared helpers as those oversized scripts are split. Keep external-source requests in tools, not Flutter UI.

## Consequences

The repository remains larger than a portfolio-only frontend; tooling changes need Node tests as well as application checks. [Technical debt](../TECH-DEBT.md) identifies scripts above the source-size limit and their planned splits. The [tooling inventory](../TOOLING.md) records the purpose folders, callers, and completed splits. Node type checking, lint, and formatting run in the analyze job.

## Alternatives considered

- External release scripts would hide the template's build contract from its users.
- A minimal UI-only template would omit current content synchronization and deployment verification behavior.
