# Customize the portfolio

The portfolio has one canonical factual record:
[`assets/content/portfolio.json`](../assets/content/portfolio.json). Names,
roles, dates, work, links, and contribution records do not belong in Dart
widgets or interface catalogs. Complete non-English professional copy belongs
in `assets/content/locales/<locale>.json` and must preserve those canonical
facts.

## Start clean—once

Run the initializer once in a fresh repository created from the template. It is
a destructive reset, not an update command: it replaces the canonical content
document, removes the original owner's optional experience, contribution, and
work sections, and regenerates public metadata.

```bash
npm ci
npm run setup:browsers
flutter pub get
npm run portfolio:init
npm run portfolio:validate
npm run build:release
node tool/serve_web.mjs
```

Open `http://127.0.0.1:4173` to inspect the release you would actually deploy.
Use `flutter run -d chrome` later for hot reload while editing layouts.

The wizard asks for identity, role, public contact information, canonical
domain, headline, and at least three focus areas. It starts with
no inherited work or social proof. It also removes the demo owner’s public work
artifacts and the source captures used to create them, then regenerates the
social card and source manifest. Optional sections disappear until you add
records.

The canonical HTTPS URL has no placeholder default. Enter the final custom
domain if you own it, or the real provider URL you intend to publish first;
that value is emitted into canonical tags, sharing metadata, sitemap, robots,
manifest, and package metadata.

Chromium is used only to render the deterministic 1200×630 social card. The
initializer checks it before touching content and rolls back the complete reset
if any later synchronization step fails. A normal GitHub clone also lets the
initializer detect `owner/repository` and replace the README badge with that
repository's live CI status. An archive or checkout without a GitHub origin
must pass `--repository owner/repository`; the initializer fails before changing
files when it cannot establish the new repository identity.

The initializer asks before overwriting the canonical document. It always
removes the demo evidence files because Flutter bundles the complete
`assets/work/` directory, including files that no content record references.
It also removes any inherited `build/web` release, which can otherwise keep the
demo owner's JSON and images public even after the source document is clean.
Copy evidence you legitimately own back into `assets/work/`, then run
`npm run build:release` to create the first safe release.

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
`--primary-name-line` and `--accent-name-line` control the two typographic name
lines in the hero; they are not color options. The shorter `--primary` and
`--accent` spellings remain compatibility aliases, but new automation should
use the explicit names.

## The everyday edit loop

After the one-time reset, normally do not run the initializer again: another
reset removes optional work, experience, contribution, locale, and evidence
data. Edit the canonical document and your own evidence directly:

1. Update `assets/content/portfolio.json`.
2. Add only images you own or may publish to `assets/work/`.
3. Keep each image's declared width and height equal to its real pixel size.
4. Run `npm run sync:content` and `npm run portfolio:validate`.
5. Run `npm run build:release`, then preview with
   `node tool/serve_web.mjs`.

If a release command fails, fix the reported source mismatch instead of editing
generated HTML, metadata, README records, or hosting files by hand; the next
content sync would replace those manual edits.

## The content contract

| Key | Owns | Required |
|---|---|---:|
| `site` | canonical URL, search/social copy, sharing image, analytics, and template CTA state | yes |
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

## Write accessible evidence

- Set `profile.display_name.accessible` to the complete name a screen reader
  should announce; do not split meaning across the two decorative name lines.
- Describe what is visibly present in each artifact `alt`. Do not repeat the
  project name or write “image of”.
- Use the artifact `caption` for source and context, not for details needed to
  understand the image.
- Give evidence links destination-specific labels such as “App Store listing”
  or “Source repository”; avoid “click here”.
- Do not put the only copy of a claim inside a screenshot. The surrounding
  structured record must remain understandable when images do not load.

Run the browser suite after changing navigation, focus behaviour, motion, or
layout. The tests cover keyboard access, reduced motion, mobile reflow, and RTL
geometry rather than treating an automated semantics tree as the whole audit.

## Languages

`assets/i18n/*.json` contains interface language only. Professional facts,
identifiers, dates, links, and the English source copy stay canonical in
`portfolio.json`; complete translated professional copy lives in
`assets/content/locales/<language>.json`. Add a locale code to `site.locales`
only after both catalogs exist and the locale document passes the all-or-nothing
parser. Missing fields are rejected instead of silently rendering a
mixed-language page.

The initializer resets `site.locales` to `en` and removes the demo
owner's localized copy. A new owner therefore never inherits translated claims
or advertises a language they have not authored yet.

## Offer your customized repository as another template

The initializer sets `site.template_repository` to `false`, so a normal
portfolio README links to its source instead of advertising a broken GitHub
`/generate` action. To publish your repository as a template:

1. In GitHub, open **Settings → General** and enable **Template repository**.
2. Set `site.template_repository` to `true` in `portfolio.json`.
3. Run `npm run sync:content` and verify that the README button targets your
   repository's `/generate` page.

Do not set the content flag first. It describes external GitHub state; the
repository setting is what makes the one-click action real.

## Analytics

Analytics is opt-in. Remove `site.analytics` for a tracking-free release. If you
add it, use a script URL and domain you control. `npm run sync:content` updates
the HTML and Nginx policy together.

## Change the visual theme

The initializer keeps the demo's editorial visual system by design; a palette
change is a code customization and should be reviewed visually. The colors are
centralized for the running Flutter page, while first-paint, sharing, and
documentation surfaces have static copies because they render before the Dart
application exists.

| Surface | Authoritative file | What to keep aligned |
|---|---|---|
| Flutter page | `lib/app/core/constants/app_colors.dart` | paper, text hierarchy, signal colors, and scene gradient |
| HTML first frame | `web/index.html` | theme meta tags and the complete `#bootstrap-surface` palette |
| Startup failure screen | `lib/main.dart` | fallback background and action color |
| Installed web-app chrome | `tool/sync_public_content.mjs` in `syncManifest` | manifest background and theme colors; `web/manifest.json` is generated |
| Social sharing card | `tool/social_card.html` | background, text, accent, and signal colors |
| Repository poster and badges | `docs/readme/hero.svg` and the badge renderers in `tool/sync_public_content.mjs` | optional repository branding; these do not affect the site |
| Individual case studies | each `systems[*].presentation` record in `assets/content/portfolio.json` | project-specific background, foreground, and accent; keep real product branding independent of the site theme |

Several section borders and the project atlas use alpha variants of the default
cobalt and ink. Before declaring a theme complete, find every remaining literal
from the old palette:

```bash
git grep -n -i -E \
  'f2eee5|faf7ef|d4cec1|12110f|403c36|756e64|fffcf4|1e51ff|e6ff57|d9e1ff' \
  -- lib web tool docs/readme
```

Classify each match instead of blind replacement: UI chrome should follow the
new theme, project evidence should retain its own brand, and opacity-prefixed
Dart colors such as `0x3D1E51FF` need only their final six RGB digits changed.
Then run:

```bash
npm run sync:content
npm run render:social-card
npm run portfolio:validate
flutter test
npm run build:release
npm run test:visual:update
npm test
```

Snapshots are platform-specific. On macOS, the update command writes Darwin
baselines. Update and verify the Linux baselines in the same Playwright image
used by CI:

```bash
docker run --rm --ipc=host \
  -v "$PWD:/work" -w /work \
  mcr.microsoft.com/playwright:v1.59.1-noble@sha256:b0ab6f3cb99aa7803adbc14d9027ec1785fc6e433b97e134e0f8fe61683b6b53 \
  bash -lc 'npm run test:visual:update && npm run test:visual'
```

Review both `*-darwin.png` and `*-linux.png` changes before committing them.

Review every changed visual baseline, keyboard focus ring, and text/background
pair. A screenshot update records a chosen change; it is not permission to
accept lost contrast.

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

Generated surfaces are checked into the repository so hosts can publish a
deterministic release without inventing content during deployment. Review their
diffs, but make corrections in `portfolio.json` or the generator that owns the
surface.
