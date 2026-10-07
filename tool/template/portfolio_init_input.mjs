import { readFile } from 'node:fs/promises';
import path from 'node:path';

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

export async function collectAnswers(args, reader) {
  const identity = await collectIdentityAnswers(args, reader);
  const profile = await collectProfileAnswers(args, reader, identity);
  return {
    ...identity,
    ...profile,
    github: optionalHttpsUrl(args.github, 'GitHub URL'),
  };
}

async function collectIdentityAnswers(args, reader) {
  const name = await requiredAnswer(args.name, 'Full name', undefined, reader);
  const suggested = splitDisplayName(name);
  const role = await requiredAnswer(args.role, 'Professional role', 'Software Engineer', reader);
  const email = validateEmail(await requiredAnswer(args.email, 'Public email', undefined, reader));
  const site = normalizeSiteUrl(
    await requiredAnswer(args.site, 'Canonical site URL', undefined, reader),
  );
  const location = await requiredAnswer(args.location, 'Location', 'Remote', reader);
  const primary = await requiredAnswer(
    args.primaryNameLine ?? args.primary,
    'Primary name line',
    suggested.primary,
    reader,
  );
  const accent = await requiredAnswer(
    args.accentNameLine ?? args.accent,
    'Accent name line',
    suggested.accent,
    reader,
  );
  const navigation = await requiredAnswer(args.navigation, 'Navigation name', name, reader);
  return { name, role, email, site, location, primary, accent, navigation };
}

async function collectProfileAnswers(args, reader, identity) {
  const since = await requiredAnswer(
    args.since,
    'Building software since',
    String(new Date().getUTCFullYear()),
    reader,
  );
  const headline = await requiredAnswer(
    args.headline,
    'One-sentence headline',
    `I’m a ${identity.role.toLowerCase()} building dependable digital products.`,
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
  return { since, headline, summary, background, focus: parseFocusAreas(focusRaw) };
}

function parseFocusAreas(value) {
  const focus = value
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
  if (focus.length < 3) {
    throw new Error('Provide at least three comma-separated focus areas.');
  }
  return focus;
}

export function createPortfolioDocument(answers) {
  const today = new Date().toISOString().slice(0, 10);
  const primary = primaryProfessionalLink(answers);
  return {
    schema_version: 11,
    content_version: `${today.replaceAll('-', '.')}.1`,
    verified_at: today,
    site: createSiteDocument(answers, primary),
    sources: [createPrimarySource(primary)],
    profile: createProfileDocument(answers),
    experience: [],
    capabilities: [{ id: 'focus', label: 'Focus', items: answers.focus }],
    contributions: [],
    systems: [],
    packages: [],
    writing_sources: [],
    writing: [],
  };
}

function createSiteDocument(answers, primary) {
  return {
    template_repository: false,
    url: answers.site,
    title: `${answers.name} — ${answers.role}`,
    description: `${answers.name} is a ${answers.role.toLowerCase()} focused on ${answers.focus.join(', ')}.`,
    social_description: answers.headline,
    social_image: '/assets/og/engineering-showcase.png',
    domain_label: new URL(answers.site).hostname.toUpperCase(),
    locales: ['en'],
    engineering_links: [
      { id: 'live-site', label: 'Live site', url: answers.site },
      { id: primary.id, label: primary.label, url: primary.url },
    ],
  };
}

function createPrimarySource(primary) {
  return {
    id: primary.id,
    label: primary.label,
    url: primary.url,
    scope: 'Canonical professional information maintained by the portfolio owner',
  };
}

function createProfileDocument(answers) {
  return {
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
      ...(answers.github ? [{ id: 'github', label: 'GitHub', url: answers.github }] : []),
    ],
  };
}

function primaryProfessionalLink(answers) {
  return answers.github
    ? { id: 'github', label: 'GitHub', url: answers.github }
    : { id: 'portfolio-record', label: 'Website', url: answers.site };
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

export async function ensureOverwriteIsAllowed({ output, force, reader, root }) {
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
  const answer = (await reader.question(`Overwrite ${path.relative(root, output)}? [y/N]: `))
    .trim()
    .toLowerCase();
  if (answer !== 'y' && answer !== 'yes') {
    throw new Error('Initialization cancelled; no file was changed.');
  }
}

export function parseArguments(values) {
  const parsed = {};
  for (let index = 0; index < values.length; index += 1) {
    const token = values[index];
    if (token === '--force') {
      addFlag(parsed, 'force', token);
      continue;
    }
    rejectRemovedFlag(token);
    if (token === '--help' || token === '-h') {
      addFlag(parsed, 'help', '--help');
      continue;
    }
    validateValueOption(token);
    const key = camelCase(token.slice(2).replaceAll('-', '_'));
    if (Object.hasOwn(parsed, key)) {
      throw new Error(`${token} may only be provided once.`);
    }
    const next = values[index + 1];
    if (!next || next.startsWith('--')) throw new Error(`${token} requires a value.`);
    parsed[key] = next;
    index += 1;
  }
  return parsed;
}

function addFlag(parsed, key, flag) {
  if (parsed[key]) throw new Error(`${flag} may only be provided once.`);
  parsed[key] = true;
}

function rejectRemovedFlag(token) {
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
}

function validateValueOption(token) {
  if (!token.startsWith('--')) throw new Error(`Unexpected argument: ${token}`);
  if (!valueOptions.has(token)) throw new Error(`Unexpected argument: ${token}`);
}

function splitDisplayName(name) {
  const words = name.trim().split(/\s+/);
  if (words.length === 1) return { primary: words[0], accent: words[0] };
  return { primary: words.slice(0, -1).join(' '), accent: words.at(-1) };
}

function normalizeSiteUrl(value) {
  return requireHttpsUrl(value, 'Canonical site URL');
}

function optionalHttpsUrl(value, label) {
  if (!nonEmpty(value)) return null;
  return requireHttpsUrl(value, label);
}

function requireHttpsUrl(value, label) {
  const url = new URL(value);
  if (url.protocol !== 'https:' || !url.hostname) {
    throw new Error(`${label} must be an absolute HTTPS URL.`);
  }
  return url.toString().replace(/\/$/, '');
}

function validateEmail(value) {
  if (
    value.length > 254 ||
    !/^[A-Za-z0-9._%+-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$/.test(
      value,
    )
  ) {
    throw new Error('Public email must be a valid email address.');
  }
  return value;
}

export function validateRepository(value) {
  const normalized = value.trim();
  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(normalized)) {
    throw new Error('--repository must use the GitHub owner/repository form.');
  }
  return normalized;
}

export function nonEmpty(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function camelCase(value) {
  return value.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
}

export function printHelp() {
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
