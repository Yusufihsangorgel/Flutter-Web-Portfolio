# Deploy the portfolio

The output is a static `build/web` directory containing a dual Flutter Web
runtime: Dart Wasm/SkWasm where the browser and headers allow it, plus the
JavaScript/CanvasKit fallback. No backend, database, or runtime secret is
required.

## Build once

```bash
npm ci
npm run setup:browsers
flutter pub get
npm run build:release
node tool/serve_web.mjs
```

Open `http://127.0.0.1:4173` and inspect the exact release before sending it to
a provider. The local server applies the same isolation headers and SPA fallback
expected from production; stop it with `Ctrl+C`.

The release command validates content and the reachable Dart source graph,
renders derived assets, verifies every provider contract, builds with
same-origin renderer resources, removes development-only files, and verifies
the final bundle.
Hosted providers verify the committed social-card fingerprint instead of
installing a browser in their restricted build images. If that gate is stale,
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
hosted build and applies the checked-in rewrites and headers. `--skip-build` is
therefore rejected for Vercel.

## GitHub Pages

In the new repository, open **Settings → Pages** and select **GitHub Actions** as
the source, then push `main`. Deployment starts only after CI succeeds for that
exact commit. The workflow chooses the base path automatically:

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

The checked-in configuration serves exact static assets first, rewrites
document routes to `index.html`, sends the isolation headers required by
threaded SkWasm, and revalidates stable Flutter entrypoint names.

Official references:
[Hosting quickstart](https://firebase.google.com/docs/hosting/quickstart),
[configuration](https://firebase.google.com/docs/hosting/full-config), and
[custom domains](https://firebase.google.com/docs/hosting/custom-domain).

## Netlify

The repository includes a pinned hosted-build script. Connecting the repository
in Netlify is enough; `netlify.toml` builds and publishes `build/web`. For a
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

- Build command: `bash tool/hosted_build.sh`
- Build output directory: `build/web`
- Node.js version: `24.18.0`
- Do not define Flutter version overrides. `tool/toolchain.json` is the
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
publishes `build/web`, preserves SPA routes, and adds the same cross-origin
isolation headers.

Vercel guarantees the selected Node **major**, not an exact patch. The hosted
build therefore accepts Vercel's current Node 24.x release while local builds,
GitHub CI, Netlify, and Cloudflare continue to verify the exact version in
`tool/toolchain.json`. Flutter's framework and engine revisions remain exact on
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

Without them the site remains usable through its fallback runtime, but the
threaded SkWasm path cannot be selected. Preserve `nosniff` and serve `.mjs`,
`.wasm`, and font MIME types correctly as shown in `nginx/default.conf`.

GitHub Pages does not expose custom response-header configuration. Its workflow
still verifies and publishes the dual-runtime artifact, but browsers select the
compatible non-isolated path there. Use one of the other included providers when
threaded SkWasm is a hard requirement.
