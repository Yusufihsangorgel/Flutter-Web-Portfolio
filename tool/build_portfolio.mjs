import { spawnSync } from 'node:child_process';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

import { normalizeBaseHref, resolveExecutable } from './cli_safety.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const options = parseArguments(process.argv.slice(2));
const baseHrefOption = options.baseHref;
const baseHref = baseHrefOption ? normalizeBaseHref(baseHrefOption) : null;

run(process.execPath, ['tool/verify_toolchain.mjs', '--current']);
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
if (baseHref) flutterArguments.push('--base-href', baseHref);
run('flutter', flutterArguments);
run('npm', ['run', 'prepare:bundle']);
run('npm', ['run', 'verify:bundle']);

console.log(`Release ready at ${path.join(root, 'build', 'web')}.`);

function parseArguments(values) {
  const parsed = { baseHref: null };
  for (let index = 0; index < values.length; index += 1) {
    const token = values[index];
    if (token !== '--base-href') {
      throw new Error(`Unexpected argument: ${token}`);
    }
    if (parsed.baseHref !== null) {
      throw new Error('--base-href may only be provided once.');
    }
    const value = values[index + 1];
    if (!value || value.startsWith('--')) {
      throw new Error('--base-href requires a value.');
    }
    parsed.baseHref = value;
    index += 1;
  }
  return parsed;
}

function run(command, args) {
  const executable = resolveExecutable(command);
  const result = spawnSync(executable, args, {
    cwd: root,
    stdio: 'inherit',
    shell: false,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`${executable} ${args.join(' ')} exited with ${result.status}.`);
  }
}
