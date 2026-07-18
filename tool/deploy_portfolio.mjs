import { spawnSync } from 'node:child_process';
import { access } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

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

if (!skipBuild) run(process.execPath, [path.join(root, 'tool', 'build_portfolio.mjs')]);
await access(path.join(root, 'build', 'web', 'index.html'));

switch (provider) {
  case 'firebase': {
    const project = requiredOption('--project');
    run('firebase', ['deploy', '--only', 'hosting', '--project', project]);
    break;
  }
  case 'netlify': {
    const site = optionalOption('--site');
    run('netlify', [
      'deploy',
      '--prod',
      '--dir',
      'build/web',
      ...(site ? ['--site', site] : []),
    ]);
    break;
  }
  case 'cloudflare': {
    const project = requiredOption('--project');
    run('wrangler', [
      'pages',
      'deploy',
      'build/web',
      '--project-name',
      project,
    ]);
    break;
  }
  case 'vercel': {
    run('vercel', ['deploy', 'build/web', '--prod']);
    break;
  }
  case 'docker': {
    const image = optionalOption('--image') ?? 'flutter-web-portfolio:local';
    run('docker', ['build', '--tag', image, '.']);
    console.log(`Run with: docker run --rm -p 8080:80 ${image}`);
    break;
  }
}

function validateOptions(options, allowed) {
  for (let index = 0; index < options.length; index += 1) {
    const option = options[index];
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
  const result = spawnSync(command, args, {
    cwd: root,
    stdio: 'inherit',
    shell: process.platform === 'win32',
  });
  if (result.error?.code === 'ENOENT') {
    throw new Error(
      `${command} is not installed. See docs/DEPLOY.md for the official CLI setup.`,
    );
  }
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`${command} ${args.join(' ')} exited with ${result.status}.`);
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
