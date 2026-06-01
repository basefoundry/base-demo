#!/usr/bin/env bash
set -euo pipefail

required_files=(
  README.md
  VERSION
  CHANGELOG.md
  CONTRIBUTING.md
  LICENSE
  base_manifest.yaml
  Brewfile
  .base/activate.sh
  src/hello.sh
  .github/workflows/tests.yml
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || {
    printf 'Missing required file: %s\n' "$file" >&2
    exit 1
  }
done

for executable in tests/validate.sh .base/activate.sh src/hello.sh; do
  [[ -x "$executable" ]] || {
    printf 'Required file is not executable: %s\n' "$executable" >&2
    exit 1
  }
done

grep -Fq 'name: base-demo' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare project name base-demo.\n' >&2
  exit 1
}

grep -Fq 'command: ./tests/validate.sh' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the validation test command.\n' >&2
  exit 1
}

grep -Fq '.base/activate.sh' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the activation source.\n' >&2
  exit 1
}

grep -Fq 'hello: ./src/hello.sh' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the hello command.\n' >&2
  exit 1
}

printf 'Repository baseline is present.\n'
