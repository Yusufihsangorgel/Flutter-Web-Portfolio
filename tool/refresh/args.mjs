export class UsageError extends Error {}

export function parseArgs(argv) {
  const options = { check: false, counters: false, report: null, file: null };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    switch (arg) {
      case '--check':
        options.check = true;
        break;
      case '--counters':
        options.counters = true;
        break;
      case '--report': {
        const value = argv[index + 1];
        if (!value) throw new UsageError('--report requires a path');
        options.report = value;
        index += 1;
        break;
      }
      case '--file': {
        const value = argv[index + 1];
        if (!value) throw new UsageError('--file requires a path');
        options.file = value;
        index += 1;
        break;
      }
      default:
        throw new UsageError(`Unknown argument: ${arg}`);
    }
  }
  return options;
}
