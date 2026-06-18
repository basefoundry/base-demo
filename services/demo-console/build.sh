#!/usr/bin/env bash
set -euo pipefail

service_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
}

cd "$(service_dir)"
node scripts/prepare-catalog.mjs
node scripts/validate-source.mjs
if [[ -x node_modules/.bin/vite ]] && node -e 'const [major, minor] = process.versions.node.split(".").map(Number); process.exit((major === 20 && minor >= 19) || (major === 22 && minor >= 12) || major > 22 ? 0 : 1)'; then
  npm run build
else
  printf 'Skipping demo-console Vite build because dependencies are not installed or Node is too old.\n'
fi
