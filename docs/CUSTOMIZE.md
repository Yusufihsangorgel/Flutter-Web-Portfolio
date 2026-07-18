# Customize the portfolio

The portfolio has one professional-content source:
[`assets/content/portfolio.json`](../assets/content/portfolio.json). Names,
roles, biography, work, links, and contribution records do not belong in Dart
widgets or translations.

## Start clean

Run the initializer in a fresh branch. It replaces the canonical content
document, removes the original owner's optional experience, contribution, and
work sections, and regenerates public metadata.

```bash
npm ci
flutter pub get
npm run portfolio:init
npm run portfolio:validate
flutter run -d chrome
```

The wizard asks for identity, role, public contact information, canonical
domain, headline, and at least three focus areas. It intentionally starts with
no inherited work or social proof. It also removes the demo owner’s public work
artifacts and the source captures used to create them, then regenerates the
social card and source manifest. Optional sections disappear until you add
records.

The initializer asks before overwriting the canonical document. In an advanced
fork where you intentionally want to retain the demo evidence files, pass
`--keep-demo-assets`; the files still remain unreferenced until you add records.

For automation or a reproducible team setup:

```bash
npm run portfolio:init -- \
  --name "Ada Lovelace" \
  --role "Software Engineer" \
  --email "hello@example.com" \
  --site "https://example.com" \
  --location "London, UK" \
  --focus "Distributed systems, Developer tools, Reliability" \
  --github "https://github.com/example" \
  --force
```

Use `npm run portfolio:init -- --help` for every optional field.

## The content contract

| Key | Owns | Required |
|---|---|---:|
| `site` | canonical URL, search/social copy, sharing image, analytics | yes |
| `profile` | identity, public contact, headline, biography, links | yes |
| `sources` | provenance for public claims | yes |
| `capabilities` | grouped skills and tools | yes |
| `experience` | professional timeline | no |
| `contributions` | merged or in-review upstream work | no |
| `systems` | featured case studies and supporting work | no |

The Dart parser rejects unsupported schema versions, malformed HTTPS URLs,
duplicate IDs, identity/metadata drift, incomplete cases, reused artifacts,
invalid colors, and unverifiable work records before `runApp`.

## Add experience

Append an object to `experience`:

```json
{
  "id": "company-role",
  "company": "Company",
  "role": "Senior Software Engineer",
  "domain": "Product area",
  "period": "2024 — Present",
  "current": true,
  "summary": "What you are responsible for and why it matters.",
  "evidence": [
    "A specific shipped responsibility",
    "A specific operational or product responsibility"
  ]
}
```

`current` is factual state, not visual emphasis. Keep historical roles false.

## Add selected work

Every work item needs a local, real artifact. Put landscape evidence in
`assets/work/` at 1600×1000 and a compact crop at 900×1200. Product captures,
release pages, diagrams derived from real source, and repository media work
well; decorative stock mockups do not.

Featured records carry the complete case:

```json
{
  "id": "project-id",
  "name": "Project name",
  "kind": "What the product is",
  "year": "2025 — Present",
  "featured": true,
  "summary": "One sentence of product context.",
  "ownership": "Your exact responsibility.",
  "decision": "The consequential engineering decision.",
  "challenge": "The constraint or failure mode.",
  "approach": "What you built and how you bounded it.",
  "outcome": "The truthful shipped result, without invented metrics.",
  "presentation": {
    "background": "#F2EDE4",
    "foreground": "#12110F",
    "accent": "#1E51FF"
  },
  "evidence": [
    {
      "label": "Public product or repository",
      "url": "https://example.com/project",
      "kind": "product"
    }
  ],
  "artifact": {
    "label": "SHIPPED PRODUCT",
    "asset": "assets/work/project.jpg",
    "alt": "A literal description of the evidence image.",
    "caption": "Where the evidence came from and when.",
    "width": 1600,
    "height": 1000,
    "fit": "cover",
    "alignment": "center",
    "composition": "evidence_stack",
    "compact": {
      "asset": "assets/work/project-compact.jpg",
      "alt": "A literal description of the compact evidence image.",
      "caption": "Compact evidence source.",
      "width": 900,
      "height": 1200,
      "fit": "cover",
      "alignment": "center"
    }
  },
  "url": "https://example.com/project",
  "technologies": ["Flutter", "Dart", "PostgreSQL"]
}
```

Use the checked-in records as the authoritative examples for supporting work
and contribution event-order labs.

## Languages

`assets/i18n/*.json` contains interface language only. Keep every locale on the
same key schema; professional content stays canonical and is never translated
by copying it into locale files.

## Analytics

Analytics is opt-in. Remove `site.analytics` for a tracking-free release. If you
add it, use a script URL and domain you control. `npm run sync:content` updates
the HTML and Nginx policy together.

## Regenerate every public surface

After any content edit:

```bash
npm run sync:content
npm run portfolio:validate
npm run prepare:source
```

This updates the README record, HTML metadata, JSON-LD, manifest, sitemap,
robots file, analytics include, Nginx policy, social card, and source manifest
from the same document.
