# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly.

**Do not open a public issue.** Instead, email **developeryusuf@icloud.com** with:

- A description of the vulnerability
- Steps to reproduce
- Potential impact

I'll acknowledge receipt within 48 hours and work on a fix.

## Scope

This is a static portfolio site with no backend, database, or user authentication. The attack surface is limited to:

- Client-side XSS via URL parameters or hash routing
- Dependency vulnerabilities in Flutter/Dart packages
- Misconfigured deployment headers (CSP, CORS, etc.)
