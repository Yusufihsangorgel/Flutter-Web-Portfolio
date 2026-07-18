# Deploy the portfolio

The output is a static `build/web` directory containing a dual Flutter Web
runtime: Dart Wasm/SkWasm where the browser and headers allow it, plus the
JavaScript/CanvasKit fallback. No backend, database, or runtime secret is
required.

## Build once

```bash
npm ci
flutter pub get
npm run build:release
```

The release command validates content and source reachability, renders derived
assets, verifies every provider contract, builds with same-origin renderer
resources, removes development-only files, and verifies the final bundle.

For a repository served below a path rather than at `/`:

```bash
npm run build:release -- --base-href /repository-name/
```

## Provider matrix

| Target | Command or flow | Included configuration |
|---|---|---|
| GitHub Pages | push `main`; enable Pages with **GitHub Actions** as the source | `.github/workflows/deploy.yml` |
| Firebase Hosting | `npm run deploy -- firebase --project <id>` | `firebase.json` |
| Netlify | `npm run deploy -- netlify` | `netlify.toml`, `web/_headers`, `web/_redirects` |
| Cloudflare Pages | `npm run deploy -- cloudflare --project <name>` | `web/_headers`, `web/_redirects` |
| Vercel | `npm run deploy -- vercel` | `vercel.json` |
| Docker / any VPS | `npm run deploy -- docker --image portfolio:latest` | `Dockerfile`, `nginx/default.conf` |

The deploy helper builds first. Add `--skip-build` only when the exact
`build/web` directory already passed `npm run verify:bundle`.

## Firebase Hosting

Install and authenticate the official Firebase CLI, create a Hosting site, then
deploy:

```bash
npm install --global firebase-tools
firebase login
npm run deploy -- firebase --project your-project-id
```

The checked-in configuration serves exact static assets first, rewrites
document routes to `index.html`, sends the isolation headers required by
threaded SkWasm, and revalidates stable Flutter entrypoint names.

Official reference: [Firebase Hosting configuration](https://firebase.google.com/docs/hosting/full-config).

## Netlify

The repository includes a pinned hosted-build script. Connecting the repository
in Netlify is enough; `netlify.toml` builds and publishes `build/web`. For a
local CLI deployment:

```bash
npm install --global netlify-cli
netlify login
npm run deploy -- netlify
```

Official references: [build configuration](https://docs.netlify.com/build/configure-builds/overview/) and [redirects](https://docs.netlify.com/manage/routing/redirects/overview/).

## Cloudflare Pages

In the Pages dashboard use:

- Build command: `bash tool/hosted_build.sh`
- Build output directory: `build/web`
- Environment variable: `FLUTTER_REVISION=ee80f08bbf97172ec030b8751ceab557177a34a6`

Or deploy from the CLI:

```bash
npm install --global wrangler
wrangler login
npm run deploy -- cloudflare --project your-pages-project
```

Official references: [custom headers](https://developers.cloudflare.com/pages/configuration/headers/) and [serving Pages](https://developers.cloudflare.com/pages/configuration/serving-pages/).

## Vercel

Import the repository or use the CLI. `vercel.json` runs the pinned hosted build,
publishes `build/web`, preserves SPA routes, and adds the same cross-origin
isolation headers.

```bash
npm install --global vercel
vercel login
npm run deploy -- vercel
```

Official reference: [project configuration](https://vercel.com/docs/project-configuration/vercel-json).

## Docker and custom domains

```bash
npm run deploy -- docker --image my-portfolio:latest
docker run --rm -p 8080:80 my-portfolio:latest
```

Point the domain at the host or provider only after the preview URL is healthy.
Then update `site.url` in `assets/content/portfolio.json` and run
`npm run sync:content`; canonical tags, sharing URLs, sitemap, robots file,
package homepage, and manifest will move together.

## Required production headers

Do not remove these from a custom host:

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: credentialless
```

Without them the site remains usable through its fallback runtime, but the
threaded SkWasm path cannot be selected. Preserve `nosniff` and serve `.mjs`,
`.wasm`, and font MIME types correctly as shown in `nginx/default.conf`.
