#!/usr/bin/env bash
set -euo pipefail

service_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
}

cd "$(service_dir)"

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  printf 'ERROR: demo-console build requires Node and npm; install the package.json engine before building.\n' >&2
  exit 1
fi

if ! node -e 'const [major, minor] = process.versions.node.split(".").map(Number); process.exit((major === 20 && minor >= 19) || (major === 22 && minor >= 12) || major > 22 ? 0 : 1)'; then
  printf 'ERROR: demo-console build requires Node ^20.19.0 or >=22.12.0; found %s.\n' "$(node --version)" >&2
  exit 1
fi

if [[ ! -x node_modules/.bin/vite ]]; then
  printf 'ERROR: demo-console dependencies are missing; run npm ci in services/demo-console.\n' >&2
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
