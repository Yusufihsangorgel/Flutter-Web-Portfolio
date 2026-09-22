# Automated data refresh

`tool/refresh_portfolio_data.mjs` keeps the factual parts of
`assets/content/portfolio.json` in sync with their live sources, so the site
does not depend on someone remembering to update it by hand.

## What refreshes automatically

- **Packages**, from the pub.dev API, for every entry already listed under
  `packages[]`: `version`, `pub_points`, `likes`, and `downloads`.
  `likes`/`downloads` are stored but not rendered by the site today; they
  refresh anyway so the record stays accurate if that changes. A package's
  `description` is authored site copy and is never overwritten from its
  pubspec. `topics` is not refreshed: the site does not render it, and pub.dev
  topics can name model vendors, which `audit:history` rejects in source.
- **Contributions**, from the GitHub API, only for entries whose `status` is
  `under_review`: when a pull request has merged, `status` becomes `merged`
  and `date` becomes the merge date. A pull request closed without merging is
  reported, never changed or removed.
- **Writing**, from every feed listed in `writing_sources[]` (an RSS/Atom
  blog feed, or a dev.to `kind`). Entries are merged across sources, one per
  normalized title (a cross-posted article keeps the URL from whichever
  source comes first in `writing_sources[]`), sorted newest first, and capped
  at 12 into `writing[]`. A source that fails to fetch or parse keeps that
  source's previously stored entries and is reported; it never blocks the
  package/contribution refresh above and never empties the list.

All three are diffed against the current file. A change to `version` or
`pub_points` (packages), to `status`/`date` (contributions), or to the
rendered `writing[]` list is **visible** — it changes what a reader sees —
and is what triggers a write and a `content_version` bump. A change to
`likes`/`downloads` alone is a **counter** and is not written by default, so
the scheduled job does not produce a commit that changes nothing a visitor
can see. `verified_at` is never changed: the site publishes it as the date
every listed source was checked, and this tool checks only pub.dev, GitHub,
and the declared writing feeds.

pub.dev scores a newly published version asynchronously. If `grantedPoints`
is not yet available for a package, the tool keeps the previous `pub_points`
value, reports the package as `pending-score`, and never writes `0` or
`null`.

The tool also looks for merged, **public** pull requests by the account named
in `profile.links` that are not yet listed in `contributions[]`, and reports
them as candidates. Candidates are never written automatically — a
contribution's `title`/`problem`/`change` is hand-written and translated into
every locale, so adding one is a deliberate, authored decision.

## What is deliberately not automated

- **Contribution prose** (`title`, `problem`, `change`) — hand-written and
  translated into every locale; automation cannot produce accepted copy.
- **`roadmap`, `maturity`, `proof`** on each package — an authored claim
  about the package's state and evidence, not a fact pub.dev reports.
- **Adding or removing a package** — the tool only refreshes packages that
  are already listed; a new package needs the same authored fields
  (`category`, `maturity`, `proof`, `roadmap`) as any other.
- **`experience`, `systems`, `capabilities`, `site`, `profile`** — none of
  this comes from a live API; it stays hand-maintained.
- **`writing_sources`** itself — which feeds to check, and their labels and
  profile links, are authored once and not discovered automatically.

## Schedule

`.github/workflows/refresh.yml` runs weekly (`workflow_dispatch` also works
on demand). The first run of each month also writes counters, which keeps the
repository active: GitHub disables a public repository's schedules after 60
days without activity. Only if `assets/content/portfolio.json` changed does
it install the Flutter toolchain, run the checks CI runs, regenerate the
derived files (`npm run sync:content`) and the tracked release
(`npm run build:release`), run the clone and browser tests against that
release, and commit everything as `github-actions[bot]`.

A push made with the workflow's own token starts no other workflow, so the job
then starts CI with a `workflow_dispatch` event; the GitHub Pages deploy
follows CI as it does for any push. A host that deploys on its own from every
push to `main` (a webhook-driven platform, for example) picks up the commit
directly. If `main` moves while the job runs, the push is rejected and the run
fails; start a new run rather than re-running the failed one, which would
reuse the old commit.

## Enabling it on a clone

Nothing needs editing. The tool reads which packages to check from
`packages[].name`, which GitHub account to search for candidate pull
requests from `profile.links` (the entry with `id: "github"`), and which
feeds to check from `writing_sources[]` — all already in
`assets/content/portfolio.json`. The initializer writes `writing_sources` as
an empty list for a clean clone; add entries by hand to turn writing refresh
on. Enable GitHub Actions on the repository and the schedule starts running.
An authenticated `GITHUB_TOKEN` is provided automatically by Actions; running
the tool locally without one works too, at GitHub's lower unauthenticated
rate limit.

## Running it locally

```bash
npm run refresh:data -- --check --report /tmp/refresh-report.md
```

`--check` fetches and compares but writes nothing (exit `1` if it found a
visible change, `0` otherwise). Drop `--check` to write. Add `--counters` to
also write when only counters changed. `--file <path>` points the tool at a
different JSON file, for testing against a scratch copy.
