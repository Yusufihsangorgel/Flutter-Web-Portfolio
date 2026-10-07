# 0004 — Build once and promote an attested artifact

## Status

Accepted.

## Context

[CI](../../.github/workflows/ci.yml) builds once, runs bundle, browser, runtime and container checks against that release, and uploads deterministic `web-release.tar.gz` with a SHA-256 sidecar. Its `attest` job checks the digest and records build provenance for `main` push or manual runs. Generated `build/web` output is untracked. Production delivery uses an independent pull process; the repository has no production CD workflow or self-hosted runner. [Pages deployment](../../.github/workflows/deploy.yml) checks the successful CI revision against current `main` and builds its own variant because its base path may differ.

## Decision

Build and verify one production release on a GitHub-hosted runner; publish its digest and provenance with the artifact. The independent production pull process verifies the attested artifact and promotes the image by digest without rebuilding the Flutter release. Keep deploy credentials outside CI and generated output outside Git. The GitHub Pages mirror stays a separate build of the checked source revision with its own base path.

After compression, release preparation sets each file's mtime to one plus the first 30 bits of its SHA-256 as epoch seconds (1970–2004), giving same-size edits content-derived Last-Modified and Nginx ETag values with a residual 30-bit collision risk instead of future HTTP dates. Directory timestamps stay fixed at 2000-01-01 UTC, and tar packaging preserves file mtimes with sorted entries, normalized ownership and timestamp-free gzip so identical prepared content packages identically; Docker's `COPY build/web` preserves those mtimes and existing immutable-path cache policies remain unchanged.

## Consequences

CI retains the release artifact for 30 days and failure reports for 7 days. Only successful `main` builds receive provenance; PR builds are checked but not production-attested. The external pull process owns retrieval, provenance verification and image-digest promotion. Its live state is outside the repository's checks. The Pages variant rebuilds, so its bytes are not the attested production artifact. Exact-tree source-manifest verification guards the production image input.

## Alternatives considered

- Rebuilding in each deploy job keeps provider setup simple but cannot prove byte-for-byte promotion of the CI-tested release.
- Running CI on a self-hosted production-capable runner would expand exposure to public-repository change execution.
