# 0004 — Build once and promote an attested artifact

## Status

Proposed.

## Context

[CI](../../.github/workflows/ci.yml) builds and uploads `web-build`. [Pages deployment](../../.github/workflows/deploy.yml) builds again, while [production CD](../../.github/workflows/cd.yml) checks out the revision on a self-hosted runner and delegates building and deployment to a runner-local script. `build/web` is [currently tracked](../../build/web/index.html). These paths do not yet establish one artifact promoted unchanged to every target. The Pages mirror is served from a repository sub-path, so it builds its own variant with a different base path instead of reusing the production files. The repository is public, so running untrusted pull-request code on a production-capable self-hosted runner would expose that runner.

## Decision

Build and verify one release artifact on a hosted, isolated CI runner; publish its digest and provenance with the artifact. After CI succeeds for the exact source revision, an independent production pull process downloads that artifact, verifies its digest and provenance, and promotes the bytes without rebuilding. The GitHub Pages mirror stays a separate build of the same revision because it needs a different base path. Remove the self-hosted runner registered to this public repository. Stop versioning generated `build/web` output once consumers use the attested artifact.

## Consequences

The release pipeline needs retention and retrieval rules, a digest verification step, and a promotion path for each deployment target. The runner-local production build, runner registration, tracked output, and checks that assume tracked output must be migrated together. The Pages variant keeps its own build. This record does not claim the current pipeline already performs those steps.

## Alternatives considered

- Rebuilding in each deploy job keeps provider setup simple but cannot prove byte-for-byte promotion of the CI-tested release.
- Running CI on a self-hosted production-capable runner would expand exposure to public-repository change execution.
