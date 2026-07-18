import { spawnSync } from 'node:child_process';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const baseHref = readOption('--base-href');

run('npm', ['run', 'verify:content']);
run('npm', ['run', 'portfolio:validate']);
run('npm', ['run', 'verify:source']);
run('npm', ['run', 'verify:hosting']);
run('npm', ['run', 'verify:community']);
run('npm', ['run', 'prepare:source']);

const flutterArguments = [
  'build',
  'web',
  '--release',
  '--wasm',
  '--no-web-resources-cdn',
];
if (baseHref) flutterArguments.push('--base-href', normalizeBaseHref(baseHref));
run('flutter', flutterArguments);
run('npm', ['run', 'prepare:bundle']);
run('npm', ['run', 'verify:bundle']);

console.log(`Release ready at ${path.join(root, 'build', 'web')}.`);

function readOption(name) {
  const index = process.argv.indexOf(name);
  if (index < 0) return null;
  const value = process.argv[index + 1];
  if (!value || value.startsWith('--')) throw new Error(`${name} requires a value.`);
  return value;
}

function normalizeBaseHref(value) {
  const withLeadingSlash = value.startsWith('/') ? value : `/${value}`;
  return withLeadingSlash.endsWith('/') ? withLeadingSlash : `${withLeadingSlash}/`;
}

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: root,
    stdio: 'inherit',
    shell: process.platform === 'win32',
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`${command} ${args.join(' ')} exited with ${result.status}.`);
  }
}
