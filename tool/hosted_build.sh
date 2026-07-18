#!/usr/bin/env bash
set -euo pipefail

FLUTTER_REVISION="${FLUTTER_REVISION:-ee80f08bbf97172ec030b8751ceab557177a34a6}"
PORTFOLIO_CACHE_DIR="${NETLIFY_CACHE_DIR:-${PORTFOLIO_CACHE_DIR:-.hosted-cache}}"
if [[ "${PORTFOLIO_CACHE_DIR}" = /* ]]; then
  FLUTTER_SDK_DIR="${PORTFOLIO_CACHE_DIR}/flutter"
else
  FLUTTER_SDK_DIR="$(pwd)/${PORTFOLIO_CACHE_DIR}/flutter"
fi

if [[ ! -x "${FLUTTER_SDK_DIR}/bin/flutter" ]] || \
   [[ "$(git -C "${FLUTTER_SDK_DIR}" rev-parse HEAD 2>/dev/null || true)" != "${FLUTTER_REVISION}" ]]; then
  mkdir -p "${FLUTTER_SDK_DIR}"
  if [[ ! -d "${FLUTTER_SDK_DIR}/.git" ]]; then
    git -C "${FLUTTER_SDK_DIR}" init
    git -C "${FLUTTER_SDK_DIR}" remote add origin https://github.com/flutter/flutter.git
  fi
  git -C "${FLUTTER_SDK_DIR}" fetch --depth 1 origin "${FLUTTER_REVISION}"
  git -C "${FLUTTER_SDK_DIR}" checkout --detach FETCH_HEAD
fi

export PATH="${FLUTTER_SDK_DIR}/bin:${PATH}"
flutter config --enable-web
flutter pub get
npm ci
npm run build:release
