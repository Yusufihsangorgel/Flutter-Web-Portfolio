import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { dirname, join, relative, resolve, sep } from 'node:path';

const projectRoot = process.cwd();
const libRoot = join(projectRoot, 'lib');
const entrypoint = join(libRoot, 'main.dart');
const packagePrefix = 'package:flutter_web_portfolio/';

if (!existsSync(entrypoint)) {
  throw new Error(`Dart entrypoint not found: ${entrypoint}`);
}

const dartFiles = collectDartFiles(libRoot);
const reachable = new Set();

visit(entrypoint);

const unreachable = dartFiles
  .filter((file) => !reachable.has(file))
  .map((file) => relative(projectRoot, file))
  .sort();

if (unreachable.length > 0) {
  console.error('Unreachable Dart sources detected:');
  for (const file of unreachable) console.error(`  - ${file}`);
  process.exitCode = 1;
} else {
  console.log(
    `Dart source graph verified: ${reachable.size}/${dartFiles.length} files reachable`,
  );
}

function visit(file) {
  const normalized = resolve(file);
  if (reachable.has(normalized)) return;
  reachable.add(normalized);

  const source = readFileSync(normalized, 'utf8');
  for (const uri of directiveUris(source)) {
    const dependency = resolveDartUri(uri, normalized);
    if (dependency == null) continue;
    if (!existsSync(dependency)) {
      throw new Error(
        `Internal Dart dependency not found: ${uri} from ${relative(projectRoot, normalized)}`,
      );
    }
    visit(dependency);
  }
}

function directiveUris(source) {
  const uris = [];
  const directivePattern = /^[\t ]*(?:import|export|part)[\t ]+([^;]+);/gm;
  for (const directive of source.matchAll(directivePattern)) {
    for (const match of directive[1].matchAll(/['"]([^'"]+)['"]/g)) {
      uris.push(match[1]);
    }
  }
  return uris;
}

function resolveDartUri(uri, sourceFile) {
  if (uri.startsWith('dart:')) return null;
  if (uri.startsWith(packagePrefix)) {
    return resolve(libRoot, uri.slice(packagePrefix.length));
  }
  if (uri.startsWith('package:')) return null;
  return resolve(dirname(sourceFile), uri);
}

function collectDartFiles(directory) {
  const files = [];
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) {
      files.push(...collectDartFiles(path));
    } else if (entry.isFile() && entry.name.endsWith('.dart')) {
      files.push(resolve(path));
    }
  }
  return files.sort((left, right) =>
    left.split(sep).join('/').localeCompare(right.split(sep).join('/')),
  );
}
