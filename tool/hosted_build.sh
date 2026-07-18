#!/usr/bin/env bash
set -euo pipefail

TOOLCHAIN_JSON="tool/toolchain.json"
NODE_VERSION="$(node -e "const t=require('./${TOOLCHAIN_JSON}'); process.stdout.write(t.node)")"
FLUTTER_VERSION="$(node -e "const t=require('./${TOOLCHAIN_JSON}'); process.stdout.write(t.flutter)")"
FLUTTER_REVISION="$(node -e "const t=require('./${TOOLCHAIN_JSON}'); process.stdout.write(t.flutterFrameworkRevision)")"

NODE_VERIFY_ARGS=(--current)
if [[ "${VERCEL:-}" == "1" ]]; then
  NODE_MAJOR="${NODE_VERSION%%.*}"
  CURRENT_NODE_MAJOR="$(node -p "process.versions.node.split('.')[0]")"
  if [[ "${CURRENT_NODE_MAJOR}" != "${NODE_MAJOR}" ]]; then
    echo "Vercel must provide Node ${NODE_MAJOR}.x; received $(node --version)." >&2
    exit 64
  fi
  # Vercel owns minor and patch updates within the configured major runtime.
  NODE_VERIFY_ARGS+=(--allow-node-patch)
elif [[ "$(node --version)" != "v${NODE_VERSION}" ]]; then
  echo "Node ${NODE_VERSION} is required; received $(node --version)." >&2
  exit 64
fi

PORTFOLIO_CACHE_DIR="${NETLIFY_CACHE_DIR:-${PORTFOLIO_CACHE_DIR:-.hosted-cache}}"
if [[ "${PORTFOLIO_CACHE_DIR}" = /* ]]; then
  FLUTTER_SDK_DIR="${PORTFOLIO_CACHE_DIR}/flutter"
else
  FLUTTER_SDK_DIR="$(pwd)/${PORTFOLIO_CACHE_DIR}/flutter"
fi

if [[ ! -x "${FLUTTER_SDK_DIR}/bin/flutter" ]] || \
   [[ "$(git -C "${FLUTTER_SDK_DIR}" rev-parse HEAD 2>/dev/null || true)" != "${FLUTTER_REVISION}" ]] || \
   [[ "$(git -C "${FLUTTER_SDK_DIR}" rev-list -n 1 "refs/tags/${FLUTTER_VERSION}" 2>/dev/null || true)" != "${FLUTTER_REVISION}" ]]; then
  mkdir -p "${FLUTTER_SDK_DIR}"
  if [[ ! -d "${FLUTTER_SDK_DIR}/.git" ]]; then
    git -C "${FLUTTER_SDK_DIR}" init
    git -C "${FLUTTER_SDK_DIR}" remote add origin https://github.com/flutter/flutter.git
  fi
  git -C "${FLUTTER_SDK_DIR}" fetch --depth 1 origin \
    "refs/tags/${FLUTTER_VERSION}:refs/tags/${FLUTTER_VERSION}"
  if [[ "$(git -C "${FLUTTER_SDK_DIR}" rev-list -n 1 "refs/tags/${FLUTTER_VERSION}")" != "${FLUTTER_REVISION}" ]]; then
    echo "Flutter ${FLUTTER_VERSION} does not resolve to ${FLUTTER_REVISION}." >&2
    exit 65
  fi
  git -C "${FLUTTER_SDK_DIR}" checkout --detach "refs/tags/${FLUTTER_VERSION}"
fi

# A cache created by the previous SHA-only bootstrap can preserve
# `0.0.0-unknown` even after the matching release tag becomes available.
rm -f "${FLUTTER_SDK_DIR}/bin/cache/flutter.version.json"

export PATH="${FLUTTER_SDK_DIR}/bin:${PATH}"
flutter config --enable-web
node tool/verify_toolchain.mjs "${NODE_VERIFY_ARGS[@]}"
flutter pub get
npm ci
PORTFOLIO_VERIFY_SOCIAL_CARD=true npm run build:release
