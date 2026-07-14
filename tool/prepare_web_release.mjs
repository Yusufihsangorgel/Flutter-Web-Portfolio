import { readdir, stat, unlink } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const webRoot = path.resolve(process.env.WEB_ROOT ?? 'build/web');
const files = await collectFiles(webRoot);
const symbolFiles = files.filter((file) => file.endsWith('.symbols'));

const removedBytes = (
  await Promise.all(
    symbolFiles.map(async (file) => {
      const metadata = await stat(file);
      await unlink(file);
      return metadata.size;
    }),
  )
).reduce((total, size) => total + size, 0);

console.log(
  `Removed ${symbolFiles.length} renderer symbol files (${formatBytes(removedBytes)}) from the public release.`,
);

async function collectFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const nested = await Promise.all(
    entries.map(async (entry) => {
      const entryPath = path.join(directory, entry.name);
      return entry.isDirectory() ? collectFiles(entryPath) : [entryPath];
    }),
  );
  return nested.flat();
}

function formatBytes(bytes) {
  return `${(bytes / 1024 / 1024).toFixed(2)} MiB`;
}
