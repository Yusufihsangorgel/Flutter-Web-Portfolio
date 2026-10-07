import { spawnSync } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { createInterface } from 'node:readline/promises';
import { fileURLToPath } from 'node:url';

import { resolveExecutable } from '../shared/cli_safety.mjs';
import {
  collectAnswers,
  createPortfolioDocument,
  ensureOverwriteIsAllowed,
  nonEmpty,
  parseArguments,
  printHelp,
  validateRepository,
} from './portfolio_init_input.mjs';
import { findTemplateRepository } from './package_links.mjs';
import {
  createRepositoryTransaction,
  initializeCanonicalRepository,
  writeAtomically,
} from './portfolio_init_repository.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const defaultOutput = path.join(root, 'assets', 'content', 'portfolio.json');
const options = parseArguments(process.argv.slice(2));
const interactive = process.stdin.isTTY && process.stdout.isTTY;
const prompt = interactive
  ? createInterface({ input: process.stdin, output: process.stdout })
  : null;

try {
  await executeInitializer({ options, prompt });
} finally {
  prompt?.close();
}

async function executeInitializer({ options: initializerOptions, prompt: reader }) {
  if (initializerOptions.help) {
    printHelp();
    return;
  }

  const answers = await collectAnswers(initializerOptions, reader);
  const document = createPortfolioDocument(answers);
  const output = path.resolve(initializerOptions.output ?? defaultOutput);
  await ensureOverwriteIsAllowed({
    output,
    force: initializerOptions.force,
    reader,
    root,
  });

  if (output !== defaultOutput) {
    await writePortfolioDocument(document, output);
    console.log('Skipped repository synchronization for the custom output path.');
    printNextSteps(output);
    return;
  }

  const repositories = await resolveRepositories(initializerOptions.repository);
  run(process.execPath, [
    path.join(root, 'tool', 'assets', 'render_social_card.mjs'),
    '--check-browser',
  ]);
  await runRepositoryTransaction({ answers, document, output, repositories });
  printNextSteps(output);
}

async function runRepositoryTransaction(context) {
  const transaction = await createRepositoryTransaction(root);
  try {
    await writePortfolioDocument(context.document, context.output);
    await initializeCanonicalRepository({
      root,
      answers: context.answers,
      originalRepository: context.repositories.original,
      initializationRepository: context.repositories.initialization,
      run,
    });
  } catch (error) {
    await transaction.rollback();
    console.error(
      'Initialization failed; restored every repository file changed by the initializer.',
    );
    throw error;
  } finally {
    await transaction.dispose();
  }
}

async function writePortfolioDocument(document, output) {
  await writeAtomically(output, `${JSON.stringify(document, null, 2)}\n`);
  console.log(`\nCreated ${path.relative(root, output)}.`);
}

async function resolveRepositories(explicitRepository) {
  const initialization = resolveInitializationRepository(explicitRepository);
  const manifest = JSON.parse(await readFile(path.join(root, 'package.json'), 'utf8'));
  return {
    initialization,
    original: findTemplateRepository(manifest),
  };
}

function resolveInitializationRepository(explicitRepository) {
  if (nonEmpty(explicitRepository)) return validateRepository(explicitRepository);
  const result = spawnSync(resolveExecutable('git'), ['config', '--get', 'remote.origin.url'], {
    cwd: root,
    encoding: 'utf8',
    shell: false,
  });
  const remote = result.status === 0 ? result.stdout.trim() : '';
  const match = remote.match(/(?:github\.com[/:])([A-Za-z0-9_.-]+)\/([A-Za-z0-9_.-]+?)(?:\.git)?$/);
  if (match) return `${match[1]}/${match[2]}`;
  throw new Error(
    'A GitHub origin was not found. Pass --repository owner/repository so initialization cannot retain the template owner’s repository metadata.',
  );
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

function printNextSteps(output) {
  console.log('\nNext:');
  console.log(
    output === defaultOutput
      ? '  npm run portfolio:validate'
      : `  npm run portfolio:validate -- ${path.relative(root, output)}`,
  );
  if (output === defaultOutput) console.log('  npm run build:release');
  console.log('  flutter run -d chrome');
}
