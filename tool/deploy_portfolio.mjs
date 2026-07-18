import { spawnSync } from 'node:child_process';
import { access } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

import { resolveExecutable, validateDeploymentValue } from './cli_safety.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const arguments_ = process.argv.slice(2);

if (arguments_.includes('--help') || arguments_.includes('-h')) {
  printHelp();
  process.exit(0);
}

const [provider, ...values] = arguments_;
if (!provider || provider.startsWith('--')) {
  printHelp();
  process.exit(64);
}

const providerOptions = {
  firebase: new Set(['--project']),
  netlify: new Set(['--site']),
  cloudflare: new Set(['--project']),
  vercel: new Set(),
  docker: new Set(['--image']),
};
const allowedOptions = providerOptions[provider];
if (!allowedOptions) throw new Error(`Unsupported provider: ${provider}`);
validateOptions(values, allowedOptions);

const skipBuild = values.includes('--skip-build');
const deployment = validateProviderValues();

if (provider === 'vercel' && skipBuild) {
  throw new Error(
    'Vercel owns its build from the repository root; --skip-build is not supported.',
  );
}
if (provider !== 'vercel') {
  if (!skipBuild) {
    run(process.execPath, [path.join(root, 'tool', 'build_portfolio.mjs')]);
  }
  await access(path.join(root, 'build', 'web', 'index.html'));
  run(process.execPath, [path.join(root, 'tool', 'verify_web_build.mjs')]);
}

switch (provider) {
  case 'firebase': {
    run('firebase', [
      'deploy',
      '--only',
      'hosting',
      '--project',
      deployment.project,
    ]);
    break;
  }
  case 'netlify': {
    run('netlify', [
      'deploy',
      '--prod',
      '--dir',
      'build/web',
      ...(deployment.site ? ['--site', deployment.site] : []),
    ]);
    break;
  }
  case 'cloudflare': {
    run('wrangler', [
      'pages',
      'deploy',
      'build/web',
      '--project-name',
      deployment.project,
    ]);
    break;
  }
  case 'vercel': {
    // Keep the repository root as Vercel's project root so vercel.json owns the
    // canonical hosted build, SPA rewrites, and security headers.
    run('vercel', ['deploy', '--prod']);
    break;
  }
  case 'docker': {
    run('docker', ['build', '--tag', deployment.image, '.']);
    console.log(`Run with: docker run --rm -p 8080:80 ${deployment.image}`);
    break;
  }
}

function validateProviderValues() {
  switch (provider) {
    case 'firebase':
      return {
        project: validateDeploymentValue(
          'firebase-project',
          requiredOption('--project'),
        ),
      };
    case 'cloudflare':
      return {
        project: validateDeploymentValue(
          'cloudflare-project',
          requiredOption('--project'),
        ),
      };
    case 'netlify': {
      const site = optionalOption('--site');
      return {
        site: site ? validateDeploymentValue('netlify-site', site) : null,
      };
    }
    case 'docker':
      return {
        image: validateDeploymentValue(
          'docker-image',
          optionalOption('--image') ?? 'flutter-web-portfolio:local',
        ),
      };
    case 'vercel':
      return {};
  }
}

function validateOptions(options, allowed) {
  const seen = new Set();
  for (let index = 0; index < options.length; index += 1) {
    const option = options[index];
    if (seen.has(option)) throw new Error(`Duplicate option: ${option}`);
    seen.add(option);
    if (option === '--skip-build') continue;
    if (!option.startsWith('--')) {
      throw new Error(`Unexpected positional argument: ${option}`);
    }
    if (!allowed.has(option)) {
      throw new Error(`Unsupported option for ${provider}: ${option}`);
    }
    const value = options[index + 1];
    if (!value || value.startsWith('--')) {
      throw new Error(`${option} requires a value.`);
    }
    index += 1;
  }
}

function optionalOption(name) {
  const index = values.indexOf(name);
  if (index < 0) return null;
  const value = values[index + 1];
  if (!value || value.startsWith('--')) throw new Error(`${name} requires a value.`);
  return value;
}

function requiredOption(name) {
  const value = optionalOption(name);
  if (!value) throw new Error(`${provider} deployment requires ${name}.`);
  return value;
}

function run(command, args) {
  const executable = resolveExecutable(command);
  const result = spawnSync(executable, args, {
    cwd: root,
    stdio: 'inherit',
    shell: false,
  });
  if (result.error?.code === 'ENOENT') {
    throw new Error(
      `${executable} is not installed. See docs/DEPLOY.md for the official CLI setup.`,
    );
  }
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`${executable} ${args.join(' ')} exited with ${result.status}.`);
  }
}

function printHelp() {
  console.log(`Build and deploy the static portfolio.

  npm run deploy -- firebase --project <firebase-project-id>
  npm run deploy -- netlify [--site <site-id>]
  npm run deploy -- cloudflare --project <pages-project-name>
  npm run deploy -- vercel
  npm run deploy -- docker [--image <name:tag>]

Add --skip-build only when build/web already passed verify:bundle.
`);
}
