import { spawnSync } from 'node:child_process';
import {
  cp,
  lstat,
  mkdir,
  mkdtemp,
  readFile,
  readdir,
  rename,
  rm,
  writeFile,
} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { createInterface } from 'node:readline/promises';
import { fileURLToPath } from 'node:url';

import { resolveExecutable } from './cli_safety.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const defaultOutput = path.join(root, 'assets', 'content', 'portfolio.json');
const options = parseArguments(process.argv.slice(2));
const interactive = process.stdin.isTTY && process.stdout.isTTY;
const prompt = interactive
  ? createInterface({ input: process.stdin, output: process.stdout })
  : null;

try {
  if (options.help) {
    printHelp();
    process.exit(0);
  }

  const answers = await collectAnswers(options, prompt);
  const document = createPortfolioDocument(answers);
  const output = path.resolve(options.output ?? defaultOutput);

  await ensureOverwriteIsAllowed(output, options.force, prompt);
  const synchronizesRepository = output === defaultOutput;
  const initializationRepository = synchronizesRepository
    ? resolveInitializationRepository(options.repository)
    : null;
  if (synchronizesRepository) {
    run(process.execPath, [
      path.join(root, 'tool', 'render_social_card.mjs'),
      '--check-browser',
    ]);
  }

  const transaction = synchronizesRepository
    ? await createRepositoryTransaction()
    : null;
  try {
    await writeAtomically(output, `${JSON.stringify(document, null, 2)}\n`);
    console.log(`\nCreated ${path.relative(root, output)}.`);

    if (synchronizesRepository) {
      await rm(path.join(root, 'assets', 'content', 'locales'), {
        recursive: true,
        force: true,
      });
      await mkdir(path.join(root, 'assets', 'content', 'locales'), {
        recursive: true,
      });
      await writeFile(
        path.join(root, 'assets', 'content', 'locales', '.gitkeep'),
        '',
      );
      console.log('Removed the demo owner’s translated professional copy.');
      await pruneDemoAssets();
      console.log('Removed the demo owner’s work artifacts and source captures.');
      await removeDemoArtifactRenderer();
      console.log('Removed the demo owner’s artifact renderer and package command.');
      await writeStarterChangelog();
      console.log('Replaced the demo history with an identity-neutral changelog.');
      await rm(path.join(root, 'build', 'web'), {
        recursive: true,
        force: true,
      });
      console.log('Removed the inherited public release; a clean build is required.');
      const syncEnvironment = {
        ...process.env,
        PORTFOLIO_GITHUB_REPOSITORY: initializationRepository,
      };
      run(
        process.execPath,
        [path.join(root, 'tool', 'sync_public_content.mjs')],
        syncEnvironment,
      );
      run(
        process.execPath,
        [path.join(root, 'tool', 'render_social_card.mjs')],
        syncEnvironment,
      );
      run(
        process.execPath,
        [path.join(root, 'tool', 'write_source_manifest.mjs')],
        syncEnvironment,
      );
      console.log('Synchronized metadata, README record, manifest, and hosting files.');
    } else if (output !== defaultOutput) {
      console.log('Skipped repository synchronization for the custom output path.');
    }
  } catch (error) {
    if (transaction) {
      await transaction.rollback();
      console.error(
        'Initialization failed; restored every repository file changed by the initializer.',
      );
    }
    throw error;
  } finally {
    await transaction?.dispose();
  }

  console.log('\nNext:');
  console.log(
    output === defaultOutput
      ? '  npm run portfolio:validate'
      : `  npm run portfolio:validate -- ${path.relative(root, output)}`,
  );
  if (output === defaultOutput) {
    console.log('  npm run build:release');
  }
  console.log('  flutter run -d chrome');
} finally {
  prompt?.close();
}

async function collectAnswers(args, reader) {
  const name = await requiredAnswer(
    args.name,
    'Full name',
    undefined,
    reader,
  );
  const suggestedNames = splitDisplayName(name);
  const role = await requiredAnswer(
    args.role,
    'Professional role',
    'Software Engineer',
    reader,
  );
  const email = await requiredAnswer(
    args.email,
    'Public email',
    undefined,
    reader,
  );
  const site = normalizeSiteUrl(
    await requiredAnswer(
      args.site,
      'Canonical site URL',
      undefined,
      reader,
    ),
  );
  const location = await requiredAnswer(
    args.location,
    'Location',
    'Remote',
    reader,
  );
  const primary = await requiredAnswer(
    args.primaryNameLine ?? args.primary,
    'Primary name line',
    suggestedNames.primary,
    reader,
  );
  const accent = await requiredAnswer(
    args.accentNameLine ?? args.accent,
    'Accent name line',
    suggestedNames.accent,
    reader,
  );
  const navigation = await requiredAnswer(
    args.navigation,
    'Navigation name',
    name,
    reader,
  );
  const since = await requiredAnswer(
    args.since,
    'Building software since',
    String(new Date().getUTCFullYear()),
    reader,
  );
  const headline = await requiredAnswer(
    args.headline,
    'One-sentence headline',
    `I’m a ${role.toLowerCase()} building dependable digital products.`,
    reader,
  );
  const summary = await requiredAnswer(
    args.summary,
    'Short professional summary',
    'I turn product problems into accessible, maintainable software and follow the work from discovery through release.',
    reader,
  );
  const background = await requiredAnswer(
    args.background,
    'Longer background paragraph',
    'My work spans product engineering, interface systems, delivery, and the operational details that keep software useful after launch.',
    reader,
  );
  const focusRaw = await requiredAnswer(
    args.focus,
    'Focus areas (comma-separated, at least three)',
    'Product engineering, Accessible interfaces, Production reliability',
    reader,
  );
  const focus = focusRaw
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
  if (focus.length < 3) {
    throw new Error('Provide at least three comma-separated focus areas.');
  }

  const github = optionalHttpsUrl(args.github, 'GitHub URL');
  return {
    name,
    role,
    email: validateEmail(email),
    site,
    location,
    primary,
    accent,
    navigation,
    since,
    headline,
    summary,
    background,
    focus,
    github,
  };
}

function createPortfolioDocument(answers) {
  const today = new Date().toISOString().slice(0, 10);
  const contentVersion = `${today.replaceAll('-', '.')}.1`;
  const siteUrl = new URL(answers.site);
  const primaryLink = answers.github ?? answers.site;
  const primaryLabel = answers.github ? 'GitHub' : 'Website';

  return {
    schema_version: 9,
    content_version: contentVersion,
    verified_at: today,
    site: {
      template_repository: false,
      url: answers.site,
      title: `${answers.name} — ${answers.role}`,
      description: `${answers.name} is a ${answers.role.toLowerCase()} focused on ${answers.focus.join(', ')}.`,
      social_description: answers.headline,
      social_image: '/assets/og/engineering-showcase.png',
      domain_label: siteUrl.hostname.toUpperCase(),
      locales: ['en'],
      engineering_links: [
        { id: 'live-site', label: 'Live site', url: answers.site },
        {
          id: answers.github ? 'github' : 'portfolio-record',
          label: primaryLabel,
          url: primaryLink,
        },
      ],
    },
    sources: [
      {
        id: answers.github ? 'github' : 'portfolio-record',
        label: primaryLabel,
        url: primaryLink,
        scope: 'Canonical professional information maintained by the portfolio owner',
      },
    ],
    profile: {
      name: answers.name,
      display_name: {
        primary: answers.primary.toUpperCase(),
        accent: answers.accent.toUpperCase(),
        navigation: answers.navigation,
        accessible: answers.name,
      },
      role: answers.role,
      location: answers.location,
      email: answers.email,
      since: answers.since,
      headline: answers.headline,
      summary: answers.summary,
      background: answers.background,
      focus: answers.focus,
      links: [
        { id: 'website', label: 'Website', url: answers.site },
        ...(answers.github
          ? [{ id: 'github', label: 'GitHub', url: answers.github }]
          : []),
      ],
    },
    experience: [],
    capabilities: [
      { id: 'focus', label: 'Focus', items: answers.focus },
    ],
    contributions: [],
    systems: [],
    packages: [],
  };
}

async function requiredAnswer(value, label, fallback, reader) {
  if (nonEmpty(value)) return value.trim();
  if (!reader) {
    if (nonEmpty(fallback)) return fallback.trim();
    throw new Error(
      `Missing ${label.toLowerCase()} in non-interactive mode. Run with --help for flags.`,
    );
  }
  const suffix = fallback ? ` [${fallback}]` : '';
  const answer = (await reader.question(`${label}${suffix}: `)).trim();
  const resolved = answer || fallback;
  if (!nonEmpty(resolved)) throw new Error(`${label} is required.`);
  return resolved.trim();
}

async function ensureOverwriteIsAllowed(output, force, reader) {
  try {
    await readFile(output, 'utf8');
  } catch (error) {
    if (error?.code === 'ENOENT') return;
    throw error;
  }
  if (force) return;
  if (!reader) {
    throw new Error(`Refusing to overwrite ${output}. Pass --force to confirm.`);
  }
  const answer = (
    await reader.question(`Overwrite ${path.relative(root, output)}? [y/N]: `)
  )
    .trim()
    .toLowerCase();
  if (answer !== 'y' && answer !== 'yes') {
    throw new Error('Initialization cancelled; no file was changed.');
  }
}

function parseArguments(values) {
  const parsed = {};
  const valueOptions = new Set([
    '--accent',
    '--accent-name-line',
    '--background',
    '--email',
    '--focus',
    '--github',
    '--headline',
    '--location',
    '--name',
    '--navigation',
    '--output',
    '--primary',
    '--primary-name-line',
    '--repository',
    '--role',
    '--since',
    '--site',
    '--summary',
  ]);
  for (let index = 0; index < values.length; index += 1) {
    const token = values[index];
    if (token === '--force') {
      if (parsed.force) throw new Error('--force may only be provided once.');
      parsed.force = true;
      continue;
    }
    if (token === '--skip-sync') {
      throw new Error(
        '--skip-sync was removed: use --output for an isolated draft; the canonical portfolio must update every public surface transactionally.',
      );
    }
    if (token === '--keep-demo-assets') {
      throw new Error(
        '--keep-demo-assets was removed: initialized repositories must not retain demo-owner artifacts.',
      );
    }
    if (token === '--help' || token === '-h') {
      if (parsed.help) throw new Error('--help may only be provided once.');
      parsed.help = true;
      continue;
    }
    if (!token.startsWith('--')) throw new Error(`Unexpected argument: ${token}`);
    if (!valueOptions.has(token)) throw new Error(`Unexpected argument: ${token}`);
    const key = token.slice(2).replaceAll('-', '_');
    const parsedKey = camelCase(key);
    if (Object.hasOwn(parsed, parsedKey)) {
      throw new Error(`${token} may only be provided once.`);
    }
    const next = values[index + 1];
    if (!next || next.startsWith('--')) throw new Error(`${token} requires a value.`);
    parsed[parsedKey] = next;
    index += 1;
  }
  return parsed;
}

async function pruneDemoAssets() {
  await pruneDirectory(path.join(root, 'assets', 'work'), new Set(['README.md']));
  await pruneDirectory(
    path.join(root, 'tool', 'work_sources'),
    new Set(['README.md']),
  );
  await writeFile(
    path.join(root, 'tool', 'work_sources', 'README.md'),
    `# Work artifact sources\n\nKeep a source ledger for every project image you add to \`assets/work/\`. Record\nthe original URL or local capture, capture date, permitted use, and any crop or\ncomposition applied. Do not add evidence you cannot publicly substantiate.\n`,
  );
}

async function removeDemoArtifactRenderer() {
  await rm(path.join(root, 'tool', 'render_work_artifacts.mjs'), {
    force: true,
  });
  const packagePath = path.join(root, 'package.json');
  const packageDocument = JSON.parse(await readFile(packagePath, 'utf8'));
  delete packageDocument.scripts?.['render:work-artifacts'];
  await writeAtomically(packagePath, `${JSON.stringify(packageDocument, null, 2)}\n`);
}

async function writeStarterChangelog() {
  await writeAtomically(
    path.join(root, 'CHANGELOG.md'),
    `# Changelog

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Initialized a clean portfolio record and regenerated every public surface.
- Removed the template demo's professional history, artifacts, and localized claims.
`,
  );
}

async function pruneDirectory(directory, keep) {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    if (keep.has(entry.name)) continue;
    await rm(path.join(directory, entry.name), {
      recursive: entry.isDirectory(),
      force: true,
    });
  }
}

function splitDisplayName(name) {
  const words = name.trim().split(/\s+/);
  if (words.length === 1) return { primary: words[0], accent: words[0] };
  return { primary: words.slice(0, -1).join(' '), accent: words.at(-1) };
}

function normalizeSiteUrl(value) {
  const url = new URL(value);
  if (url.protocol !== 'https:' || !url.hostname) {
    throw new Error('Canonical site URL must be an absolute HTTPS URL.');
  }
  return url.toString().replace(/\/$/, '');
}

function optionalHttpsUrl(value, label) {
  if (!nonEmpty(value)) return null;
  const url = new URL(value);
  if (url.protocol !== 'https:' || !url.hostname) {
    throw new Error(`${label} must be an absolute HTTPS URL.`);
  }
  return url.toString().replace(/\/$/, '');
}

function validateEmail(value) {
  if (
    value.length > 254 ||
    !/^[A-Za-z0-9._%+\-]+@[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?)+$/.test(
      value,
    )
  ) {
    throw new Error('Public email must be a valid email address.');
  }
  return value;
}

function run(command, args, environment = process.env) {
  const executable = resolveExecutable(command);
  const result = spawnSync(executable, args, {
    cwd: root,
    stdio: 'inherit',
    shell: false,
    env: environment,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`${command} ${args.join(' ')} exited with ${result.status}.`);
  }
}

function resolveInitializationRepository(explicitRepository) {
  if (nonEmpty(explicitRepository)) return validateRepository(explicitRepository);
  const result = spawnSync(resolveExecutable('git'), [
    'config',
    '--get',
    'remote.origin.url',
  ], {
    cwd: root,
    encoding: 'utf8',
    shell: false,
  });
  const remote = result.status === 0 ? result.stdout.trim() : '';
  const match = remote.match(
    /(?:github\.com[/:])([A-Za-z0-9_.-]+)\/([A-Za-z0-9_.-]+?)(?:\.git)?$/,
  );
  if (match) return `${match[1]}/${match[2]}`;
  throw new Error(
    'A GitHub origin was not found. Pass --repository owner/repository so initialization cannot retain the template owner’s repository metadata.',
  );
}

async function writeAtomically(output, contents) {
  await mkdir(path.dirname(output), { recursive: true });
  const temporary = path.join(
    path.dirname(output),
    `.${path.basename(output)}.${process.pid}.${Date.now()}.tmp`,
  );
  try {
    await writeFile(temporary, contents);
    await rename(temporary, output);
  } finally {
    await rm(temporary, { force: true });
  }
}

async function createRepositoryTransaction() {
  const temporary = await mkdtemp(
    path.join(os.tmpdir(), 'portfolio-init-transaction-'),
  );
  const targets = [
    'README.md',
    'CHANGELOG.md',
    'CODE_OF_CONDUCT.md',
    'SECURITY.md',
    'package.json',
    'nginx/default.conf',
    'firebase.json',
    'vercel.json',
    'web/_headers',
    'web/index.html',
    'web/manifest.json',
    'web/robots.txt',
    'web/sitemap.xml',
    'assets/content/portfolio.json',
    'assets/content/locales',
    'assets/work',
    'tool/work_sources',
    'tool/render_work_artifacts.mjs',
    'web/assets/og/engineering-showcase.png',
    'web/assets/og/engineering-showcase.png.sha256',
    'assets/build/source_manifest.sha256',
    'build/web',
  ];
  const snapshots = [];
  for (const relative of targets) {
    const target = path.join(root, relative);
    const backup = path.join(temporary, relative);
    const existed = await pathExists(target);
    snapshots.push({ target, backup, existed });
    if (existed) {
      await mkdir(path.dirname(backup), { recursive: true });
      await cp(target, backup, { recursive: true, force: true });
    }
  }
  return {
    async rollback() {
      for (const snapshot of snapshots) {
        await rm(snapshot.target, { recursive: true, force: true });
        if (snapshot.existed) {
          await mkdir(path.dirname(snapshot.target), { recursive: true });
          await cp(snapshot.backup, snapshot.target, {
            recursive: true,
            force: true,
          });
        }
      }
    },
    async dispose() {
      await rm(temporary, { recursive: true, force: true });
    },
  };
}

async function pathExists(target) {
  try {
    await lstat(target);
    return true;
  } catch (error) {
    if (error?.code === 'ENOENT') return false;
    throw error;
  }
}

function validateRepository(value) {
  const normalized = value.trim();
  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(normalized)) {
    throw new Error('--repository must use the GitHub owner/repository form.');
  }
  return normalized;
}

function nonEmpty(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function camelCase(value) {
  return value.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
}

function printHelp() {
  console.log(`Create a clean portfolio record without editing Dart code.

Interactive:
  npm run portfolio:init

Non-interactive:
  npm run portfolio:init -- \\
    --name "Ada Lovelace" \\
    --role "Software Engineer" \\
    --email "hello@example.com" \\
    --site "https://example.com" \\
    --location "London, UK" \\
    --focus "Distributed systems, Developer tools, Reliability" \\
    --force

Optional flags:
  --github, --primary-name-line, --accent-name-line, --navigation, --since,
  --headline,
  --summary, --background, --repository, --output,
  --force
`);
}
