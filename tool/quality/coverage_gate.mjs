import { appendFile, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const groups = {
  domain: (file) => file.startsWith('lib/app/domain/'),
  application: (file) =>
    file.startsWith('lib/app/controllers/') ||
    file.startsWith('lib/app/narrative/application/') ||
    /^lib\/app\/features\/[^/]+\/application\//.test(file),
};

function optionsFrom(args) {
  const options = {
    coverage: 'coverage/lcov.info',
    thresholds: 'tool/quality/coverage_thresholds.json',
    update: false,
  };
  for (let index = 0; index < args.length; index += 1) {
    const argument = args[index];
    if (argument === '--update') {
      options.update = true;
    } else if (argument === '--coverage' || argument === '--thresholds') {
      const value = args[index + 1];
      if (!value || value.startsWith('--')) {
        throw new Error(`Missing value for ${argument}`);
      }
      options[argument.slice(2)] = value;
      index += 1;
    } else {
      throw new Error(`Unknown option: ${argument}`);
    }
  }
  return options;
}

function sourcePath(file) {
  const relative = path.isAbsolute(file) ? path.relative(process.cwd(), file) : file;
  return relative.replaceAll('\\', '/').replace(/^\.\//, '');
}

function parseCoverage(input) {
  const sources = new Map();
  let lines;
  for (const record of input.split(/\r?\n/)) {
    if (record.startsWith('SF:')) {
      const file = sourcePath(record.slice(3));
      lines = sources.get(file) ?? new Map();
      sources.set(file, lines);
    } else if (record.startsWith('DA:')) {
      const match = /^DA:(\d+),(\d+)(?:,.*)?$/.exec(record);
      if (!lines || !match) {
        throw new Error(`Invalid coverage line: ${record}`);
      }
      const line = Number(match[1]);
      lines.set(line, Math.max(lines.get(line) ?? 0, Number(match[2])));
    } else if (record === 'end_of_record') {
      lines = undefined;
    }
  }
  return sources;
}

function collectGroups(sources) {
  const totals = Object.fromEntries(
    Object.keys(groups).map((name) => [name, { covered: 0, total: 0 }]),
  );
  for (const [file, lines] of sources) {
    for (const [name, includes] of Object.entries(groups)) {
      if (!includes(file)) continue;
      totals[name].total += lines.size;
      totals[name].covered += [...lines.values()].filter((hits) => hits > 0).length;
    }
  }
  for (const [name, counts] of Object.entries(totals)) {
    if (counts.total === 0) throw new Error(`No covered lines found for ${name}`);
  }
  return totals;
}

function validateThresholds(value) {
  for (const name of Object.keys(groups)) {
    const threshold = value[name];
    if (
      typeof threshold !== 'number' ||
      !Number.isFinite(threshold) ||
      threshold < 0 ||
      threshold > 100
    ) {
      throw new Error(`Invalid ${name} threshold`);
    }
  }
  return value;
}

function percentage(counts) {
  return (counts.covered / counts.total) * 100;
}

function tableFor(totals, thresholds) {
  const rows = [
    '| Group | Lines | Coverage | Threshold | Result |',
    '| --- | ---: | ---: | ---: | --- |',
  ];
  for (const [name, counts] of Object.entries(totals)) {
    const actual = percentage(counts);
    const result = actual + 1e-9 >= thresholds[name] ? 'PASS' : 'FAIL';
    rows.push(
      `| ${name} | ${counts.covered}/${counts.total} | ${actual.toFixed(1)}% | ${thresholds[name].toFixed(1)}% | ${result} |`,
    );
  }
  return `${rows.join('\n')}\n`;
}

async function main() {
  const options = optionsFrom(process.argv.slice(2));
  const coverage = parseCoverage(await readFile(options.coverage, 'utf8'));
  const totals = collectGroups(coverage);
  const thresholds = validateThresholds(JSON.parse(await readFile(options.thresholds, 'utf8')));
  const table = tableFor(totals, thresholds);
  process.stdout.write(table);
  if (process.env.GITHUB_STEP_SUMMARY) {
    await appendFile(process.env.GITHUB_STEP_SUMMARY, table);
  }

  if (options.update) {
    const updated = {};
    for (const [name, counts] of Object.entries(totals)) {
      updated[name] = Math.floor(percentage(counts) * 10 + 1e-9) / 10;
      if (updated[name] < thresholds[name]) {
        throw new Error(
          `Coverage update would lower ${name} from ${thresholds[name]} to ${updated[name]}`,
        );
      }
    }
    await writeFile(options.thresholds, `${JSON.stringify(updated, null, 2)}\n`);
    return;
  }

  if (
    Object.entries(totals).some(([name, counts]) => percentage(counts) + 1e-9 < thresholds[name])
  ) {
    process.exitCode = 1;
  }
}

try {
  await main();
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exitCode = 1;
}
