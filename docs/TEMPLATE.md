# Use the portfolio template

This repository contains a Flutter Web portfolio and the tooling to create a
separate portfolio from it. The site builds to static files in `build/web`.

## Create a portfolio

Use GitHub's **Use this template** action to create a repository, then clone it.
A template copy starts with one unrelated commit; a fork keeps this
repository's history. Fork only to contribute changes back. GitHub explains the
difference in [Create a repository from a template](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template).

The pinned toolchain is Node.js 24.18.0 and Flutter 3.47.5 with Dart 3.13.4.
`.nvmrc` holds the Node.js version, `tool/toolchain.json` holds the Flutter
revision, and `npm run verify:toolchain` reports a mismatch. Install the tools,
then run:

```bash
git clone <your-repository-url>
cd <your-repository>
npm ci
npm run setup:browsers
flutter pub get
npm run portfolio:init
npm run portfolio:validate
npm run build:release
node tool/serve_web.mjs
```

Open `http://127.0.0.1:4173` to preview the release output. Stop the local
server with `Ctrl+C`. Use `flutter run -d chrome` for the hot-reload loop.

Run `npm run portfolio:init` once in a new template copy. It replaces the
starter profile and removes the demo's optional work, experience, contribution,
and evidence records. It also regenerates the social card, source manifest,
README record, search and sharing metadata, web manifest, sitemap, robots file,
and server policy. If a step fails, it restores every file it changed.

## Customize the content

1. Complete the initializer prompts for the portfolio profile and site.
2. Edit `assets/content/portfolio.json` for profile, experience, contributions,
   and selected work.
3. Add only images that may be published to `assets/work/`, and keep their
   declared dimensions aligned with the files.
4. Add interface translations under `assets/i18n/`. Put translated portfolio
   copy in `assets/content/locales/` and keep its structure aligned with the
   canonical document.
5. Run `npm run sync:content` and `npm run portfolio:validate` after content
   changes.
6. Run `npm run build:release`, then preview with `node tool/serve_web.mjs`.

The parser checks the content schema, links, identifiers, locale overlays, and
work evidence before the app starts. See [Customize the content](CUSTOMIZE.md)
for field examples, accessibility guidance, and visual changes.

## Choose a host

| Host | Build or deploy flow |
|---|---|
| GitHub Pages | Push `main`; the included workflow sets the repository base path |
| Firebase Hosting | `npm run deploy -- firebase --project <id>` |
| Netlify | Connect the repository or run `npm run deploy -- netlify` |
| Cloudflare Pages | `npm run deploy -- cloudflare --project <name>` |
| Vercel | Import the repository or run `npm run deploy -- vercel` |
| Docker or another VPS | `npm run deploy -- docker --image portfolio:latest` |

Threaded SkWasm requires cross-origin isolation headers. Firebase Hosting,
Netlify, Cloudflare Pages, Vercel, and the included Nginx configuration provide
them. GitHub Pages cannot set custom response headers and uses the compatible
single-threaded runtime path.

A custom domain needs no Dart change. Set `site.url` in
`assets/content/portfolio.json`, run `npm run sync:content`, then point DNS at
the host.

See the [deployment guide](DEPLOY.md) for provider setup, the order of a domain
move, and required response headers.
