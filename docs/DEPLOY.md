# Deploy the portfolio

The output is a static `build/web` directory containing a dual Flutter Web
runtime: single-threaded Dart Wasm/SkWasm where the browser supports it, plus the
JavaScript/CanvasKit fallback. No backend, database, or runtime secret is
required.

The weekly refresh workflow is configured to update package metrics and merged
pull-request status through a checked pull request. Its successful scheduled
PR/merge path still needs confirmation; see [`AUTOMATION.md`](AUTOMATION.md).

CI builds the release once, tests that build, and publishes deterministic
`web-release.tar.gz` with `web-release.sha256`. Successful `main` push or manual
CI runs attest the tarball in the `attest` job. The production delivery contract
uses an independent host pull process: verify checksum and provenance for the
expected revision, package the verified static release, and promote the image
by digest. Its live configuration is outside this repository's checks. CI holds
no production deploy credentials, and all repository jobs use hosted runners.
The artifact is retained for 30 days; generated `build/web` is not tracked.
Pages builds a separate base-path variant after CI instead of downloading the
production artifact. Template users build locally with `npm run build:release` and deploy
`build/web` to their chosen host using the instructions below.

## Build once

```bash
npm ci
npm run setup:browsers
flutter pub get
npm run build:release
node tool/runtime/serve_web.mjs
```

Open `http://127.0.0.1:4173` and inspect the exact release before sending it to
a provider. The local server applies the same isolation headers expected from
production and answers unknown paths with the static `404.html` page and HTTP
status 404; stop it with `Ctrl+C`.

Section navigation uses `#/section` fragments, which never reach the server, so
no host rewrites paths to `index.html`. Every provider below serves the root
document for `/` and returns its 404 response for any path that is not a file in
the release.

The release command validates content and the reachable Dart source graph,
renders derived assets, verifies every provider contract, builds with
same-origin renderer resources, removes development-only files, and verifies
the final bundle.
Hosted providers verify the committed social-card fingerprint instead of
rendering the card again. They still need Chromium to generate the résumé PDF;
the provider build image must supply the Playwright browser and its system
dependencies because the hosted-build script does not install them. If the card gate is stale,
run `npm run render:social-card` locally and commit both the PNG and its
`.sha256` sidecar.

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

The deploy helper builds first and always re-runs `verify:bundle` before a
prebuilt directory can leave the machine. Vercel is the exception: its CLI is
invoked from the repository root so `vercel.json` performs the same canonical
hosted build and applies the checked-in headers. `--skip-build` is
therefore rejected for Vercel.

## GitHub Pages

In the new repository, open **Settings → Pages** and select **GitHub Actions** as
the source, then push `main`. Deployment starts only after CI succeeds for that
exact commit. It also requires that revision to remain current `main` before rebuilding.
This workflow publishes its own `build/web`, not CI's attested tarball. Manual
dispatch is allowed on `main` and still checks the current revision.
The workflow chooses the base path automatically:

- `owner.github.io` repositories and configured custom domains use `/`;
- project sites use `/<repository>/`;
- the optional repository variable `PORTFOLIO_BASE_HREF` overrides both for an
  unusual nested preview path.

The resolver is part of the tested hosting contract, so changing a repository
name or adding a domain does not require editing Dart or workflow code.

Official references:
[publishing with GitHub Actions](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)
and
[custom domains](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site).

## Firebase Hosting

This project targets **Firebase Hosting**, not Firebase App Hosting. Create a
Firebase project, enable Hosting, install and authenticate the official CLI,
then deploy:

```bash
npm install --global firebase-tools
firebase login
npm run deploy -- firebase --project your-project-id
```

The checked-in configuration serves exact static files only, answers unknown
paths with `404.html`, sends the isolation headers required by threaded SkWasm,
and revalidates stable Flutter entrypoint names.

Official references:
[Hosting quickstart](https://firebase.google.com/docs/hosting/quickstart),
[configuration](https://firebase.google.com/docs/hosting/full-config), and
[custom domains](https://firebase.google.com/docs/hosting/custom-domain).

## Netlify

The repository includes a pinned hosted-build script. Connect the repository
in Netlify and provide Chromium and its system dependencies for the résumé step;
`netlify.toml` builds and publishes `build/web`. For a
local CLI deployment:

```bash
npm install --global netlify-cli
netlify login
npm run deploy -- netlify
```

On the first CLI deployment, Netlify asks whether to create a site or link an
existing one. Later non-interactive deployments can pass its site ID with
`--site`.

Official references:
[CLI deployment](https://docs.netlify.com/api-and-cli-guides/cli-guides/get-started-with-cli/),
[build configuration](https://docs.netlify.com/build/configure-builds/overview/),
[redirects](https://docs.netlify.com/manage/routing/redirects/overview/), and
[custom domains](https://docs.netlify.com/manage/domains/manage-domains/assign-a-domain-to-your-site-app/).

## Cloudflare Pages

For automatic Git deployments, connect the repository in the Pages dashboard
and use:

- Build command: `bash tool/release/hosted_build.sh`
- Build output directory: `build/web`
- Node.js version: `24.18.0`
- Do not define Flutter version overrides. `tool/quality/toolchain.json` is the
  immutable Node/Flutter version and revision contract consumed by the hosted
  build; the build stops if the provider runtime differs.

For a Direct Upload project, deploy from the CLI:

```bash
npm install --global wrangler
wrangler login
wrangler pages project create
npm run deploy -- cloudflare --project your-pages-project
```

Choose the project type before starting: a Direct Upload project cannot later
be converted to Git integration. Create a new Pages project if you need to
change that choice.

Official references:
[Git integration](https://developers.cloudflare.com/pages/get-started/git-integration/),
[Direct Upload](https://developers.cloudflare.com/pages/get-started/direct-upload/),
[custom headers](https://developers.cloudflare.com/pages/configuration/headers/),
and
[custom domains](https://developers.cloudflare.com/pages/configuration/custom-domains/).

## Vercel

Import the repository or use the CLI. `vercel.json` runs the pinned hosted build,
publishes `build/web`, serves `404.html` for unknown paths, and adds the same
cross-origin isolation headers.

Vercel guarantees the selected Node **major**, not an exact patch. The hosted
build therefore accepts Vercel's current Node 24.x release while local builds,
GitHub CI, Netlify, and Cloudflare continue to verify the exact version in
`tool/quality/toolchain.json`. Flutter's framework and engine revisions remain exact on
every provider.

```bash
npm install --global vercel
vercel login
npm run deploy -- vercel
```

Official references:
[project configuration](https://vercel.com/docs/project-configuration/vercel-json),
[supported Node.js versions](https://vercel.com/docs/functions/runtimes/node-js/node-js-versions),
and [custom domains](https://vercel.com/docs/domains/set-up-custom-domain).

## Docker / VPS

```bash
npm run deploy -- docker --image my-portfolio:latest
docker run --rm -p 8080:80 my-portfolio:latest
```

Terminate TLS in your reverse proxy or load balancer and forward traffic to the
container. Preserve the response headers listed below. The image contains only
the verified static release and pinned Nginx runtime; it does not require a
database, writable volume, or runtime secret.

## Move to a custom domain without an SEO split

Do not point DNS at a deployment whose canonical metadata still names a
provider preview URL. Use this order:

1. Keep the existing site live while you test the new provider preview URL.
2. Change `site.url` in `assets/content/portfolio.json` to the final HTTPS
   domain, then run `npm run sync:content` and `npm run build:release`.
3. Deploy again and confirm the provider preview still renders correctly; its
   canonical URL, social URL, sitemap, robots file, package homepage, and web
   manifest should now name the final domain.
4. Add the domain to the hosting provider **before** changing DNS. Use the exact
   DNS records shown by that provider rather than copying generic records from a
   blog post.
5. Change DNS, wait for the provider to report the domain as connected, and
   verify HTTPS on both the apex and `www` form you intend to support.
6. Choose one canonical host and configure the provider to redirect the other;
   do not leave two independently indexable copies.

GitHub, Firebase, Netlify, Cloudflare, and Vercel all publish provider-specific
domain instructions linked in their sections above. DNS and certificate status
are external state; a successful application build does not prove either one.

## Required production headers

Do not remove these from a custom host:

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: credentialless
```

The current single-threaded SkWasm path does not require isolation. These headers
are retained for the threaded path once its workaround is removed. Preserve
the checked content security policy, HSTS and `nosniff`, and serve `.mjs`,
`.wasm`, and font MIME types correctly as shown in `nginx/default.conf`.

GitHub Pages does not expose custom response-header configuration. Its workflow
still verifies and publishes a dual-runtime release, and compatible browsers
use single-threaded SkWasm there. Threaded rendering remains disabled on every
host until the pinned Flutter release contains the glyph-cache fix; see
[ADR 0003](adr/0003-dual-wasm-javascript-runtime.md).
