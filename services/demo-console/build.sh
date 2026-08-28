#!/usr/bin/env bash
set -euo pipefail

service_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
}

cd "$(service_dir)"

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  printf 'ERROR: demo-console requires the mise-managed Node 22.22.0/npm 10.9.4 toolchain; run basectl setup base-demo.\n' >&2
  exit 1
fi

if ! node -e 'const [major, minor] = process.versions.node.split(".").map(Number); process.exit((major === 20 && minor >= 19) || (major === 22 && minor >= 12) || major > 22 ? 0 : 1)'; then
  printf 'ERROR: demo-console build requires Node ^20.19.0 or >=22.12.0; found %s. Run basectl setup base-demo to restore Node 22.22.0.\n' "$(node --version)" >&2
  exit 1
fi

if [[ ! -x node_modules/.bin/vite || ! -x node_modules/.bin/vitest ]]; then
  printf 'ERROR: demo-console dependencies are missing; run mise run frontend-install from the repository root (basectl test base-demo does this automatically).\n' >&2
  exit 1
fi

npm run validate
npm run build

if [[ ! -f dist/index.html ]]; then
  printf 'ERROR: demo-console build did not create dist/index.html.\n' >&2
  exit 1
fi

if ! find dist/assets -type f -name '*.js' -print -quit 2>/dev/null | grep -q .; then
  printf 'ERROR: demo-console build did not create a JavaScript entry artifact.\n' >&2
  exit 1
fi
