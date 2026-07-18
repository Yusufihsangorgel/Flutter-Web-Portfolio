import { spawnSync } from "node:child_process";
import { readFile } from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

import { resolveExecutable } from "./cli_safety.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const expected = JSON.parse(
  await readFile(path.join(root, "tool", "toolchain.json"), "utf8"),
);

for (const field of [
  "node",
  "flutter",
  "flutterFrameworkRevision",
  "flutterEngineRevision",
]) {
  if (typeof expected[field] !== "string" || expected[field].length === 0) {
    throw new Error(`tool/toolchain.json is missing ${field}`);
  }
}
if (!/^\d+\.\d+\.\d+$/.test(expected.node)) {
  throw new Error("tool/toolchain.json node must be an exact semantic version");
}
if (!/^\d+\.\d+\.\d+$/.test(expected.flutter)) {
  throw new Error(
    "tool/toolchain.json flutter must be an exact semantic version",
  );
}
for (const field of ["flutterFrameworkRevision", "flutterEngineRevision"]) {
  if (!/^[0-9a-f]{40}$/.test(expected[field])) {
    throw new Error(`tool/toolchain.json ${field} must be a full Git revision`);
  }
}

if (process.argv.includes("--current")) {
  const currentNode = process.version.replace(/^v/, "");
  const allowNodePatch = process.argv.includes("--allow-node-patch");
  const nodeMatches = allowNodePatch
    ? currentNode.split(".")[0] === expected.node.split(".")[0]
    : currentNode === expected.node;
  if (!nodeMatches) {
    throw new Error(
      `Node ${expected.node} is required; received ${currentNode}.`,
    );
  }

  const result = spawnSync(
    resolveExecutable("flutter"),
    ["--version", "--machine"],
    {
      cwd: root,
      encoding: "utf8",
      shell: false,
    },
  );
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`flutter --version --machine exited with ${result.status}`);
  }
  const currentFlutter = JSON.parse(result.stdout);
  const comparisons = [
    ["flutterVersion", "flutter"],
    ["frameworkRevision", "flutterFrameworkRevision"],
    ["engineRevision", "flutterEngineRevision"],
  ];
  for (const [actualField, expectedField] of comparisons) {
    if (currentFlutter[actualField] !== expected[expectedField]) {
      throw new Error(
        `Flutter ${actualField} must be ${expected[expectedField]}; received ${currentFlutter[actualField]}.`,
      );
    }
  }
  process.stdout.write(
    `Toolchain verified: Node ${allowNodePatch ? `${expected.node.split(".")[0]}.x` : expected.node}, Flutter ${expected.flutter} (${expected.flutterFrameworkRevision}).\n`,
  );
}

export { expected as expectedToolchain };
