#!/usr/bin/env bash
set -euo pipefail

service_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
}

cd "$(service_dir)"
node scripts/prepare-catalog.mjs
if [[ ! -x node_modules/.bin/vite ]]; then
  printf 'ERROR: demo-console dependencies are not installed. Run npm install in services/demo-console.\n' >&2
  exit 2
fi
if ! node -e 'const [major, minor] = process.versions.node.split(".").map(Number); process.exit((major === 20 && minor >= 19) || (major === 22 && minor >= 12) || major > 22 ? 0 : 1)'; then
  printf 'ERROR: demo-console Vite requires Node 20.19+ or 22.12+.\n' >&2
  exit 2
fi
exec npm run dev -- --host 127.0.0.1 --port "${PORT:-8070}"
