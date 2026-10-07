#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 1 || ( $# -eq 1 && $1 != --update-snapshots ) ]]; then
  echo 'Usage: bash tool/runtime/run_visual_in_docker.sh [--update-snapshots]' >&2
  exit 2
fi

repository=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repository"

if [[ ! -f build/web/index.html ]]; then
  echo 'build/web is missing. Build the release before running visual tests.' >&2
  exit 1
fi
if [[ ! -f node_modules/@playwright/test/package.json ]]; then
  echo 'node_modules/@playwright/test is missing.' >&2
  exit 1
fi

version=$(python3 - <<'PY'
import json
import sys
from pathlib import Path

manifest = json.loads(Path('package.json').read_text())
lock = json.loads(Path('package-lock.json').read_text())
installed = json.loads(Path('node_modules/@playwright/test/package.json').read_text())
requested = manifest['devDependencies']['@playwright/test']
locked_request = lock['packages']['']['devDependencies']['@playwright/test']
locked_version = lock['packages']['node_modules/@playwright/test']['version']
if requested != locked_request or installed['version'] != locked_version:
    raise SystemExit('Playwright package, lockfile, and installation disagree.')
sys.stdout.write(f'{locked_version}\n')
PY
)

module_mount=()
if [[ -L node_modules ]]; then
  container_modules=$(python3 - <<'PY'
import os
import sys

sys.stdout.write(os.path.normpath(os.path.join('/workspace', os.readlink('node_modules'))) + '\n')
PY
)
  module_mount=(--mount "type=bind,source=$(realpath node_modules),target=$container_modules,readonly")
fi

docker run --rm --init --ipc=host --network none \
  --user "$(id -u):$(id -g)" -e HOME=/tmp \
  --mount "type=bind,source=$repository,target=/workspace" \
  "${module_mount[@]}" \
  --workdir /workspace \
  "mcr.microsoft.com/playwright:v${version}-noble" \
  node node_modules/@playwright/test/cli.js test tests/e2e/visual.spec.ts "$@"
