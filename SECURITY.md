# Security Policy

## Supported versions

Security fixes target the `main` branch and the current 2.0 release line.
Historical tags and pre-2.0 development snapshots are not maintained.

| Version | Supported |
|---|---|
| `main` | Yes |
| `2.0.x` | Yes |
| `< 2.0` | No |

## Reporting a vulnerability

<!-- portfolio-security-contact:start -->
Please report vulnerabilities privately to [developeryusuf@icloud.com](mailto:developeryusuf@icloud.com) rather than opening a public issue. Include the affected revision, reproduction steps, impact, and any suggested mitigation. Do not include secrets or personal data in the report.
<!-- portfolio-security-contact:end -->

The maintainer will validate the report, minimize disclosure while a fix is in
progress, and credit the reporter when requested and appropriate. There is no
bug-bounty program or guaranteed response window.

## In scope

- The portfolio source, build and deployment scripts, hosting headers, and
  checked-in release bundle.
- A reproducible path that changes public content, executes unintended code,
  bypasses browser isolation, or exposes information not present in the source
  document.

Configuration errors in a downstream deployment and vulnerabilities in an
unsupported browser or third-party hosting provider should be reported to the
responsible project or provider first.
