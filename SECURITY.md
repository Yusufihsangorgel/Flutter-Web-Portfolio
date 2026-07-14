# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly.

**Do not open a public issue.** Use the repository's private vulnerability
reporting channel with:

- A description of the vulnerability
- Steps to reproduce
- Potential impact

Reports are reviewed privately and handled according to impact.

## Scope

This is a static portfolio site with no backend, database, or user authentication. The attack surface is limited to:

- Client-side XSS via URL parameters or hash routing
- Dependency vulnerabilities in Flutter/Dart packages
- Misconfigured deployment headers (CSP, CORS, etc.)
