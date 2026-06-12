#!/usr/bin/env bash

required_files=(
  README.md
  VERSION
  CHANGELOG.md
  CONTRIBUTING.md
  AGENTS.md
  skills.md
  LICENSE
  install.sh
  base_manifest.yaml
  Brewfile
  .base/activate.sh
  bin/base-demo-python-info
  src/hello.sh
  src/env.sh
  src/manifest.sh
  src/build-info.sh
  lib/python/base_demo_cli/__init__.py
  lib/python/base_demo_cli/__main__.py
  demo/demo.sh
  tests/demo_test.bats
  .github/workflows/tests.yml
  .github/pull_request_template.md
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || {
    printf 'Missing required file: %s\n' "$file" >&2
    exit 1
  }
done

for executable in tests/validate.sh install.sh .base/activate.sh bin/base-demo-python-info src/hello.sh src/env.sh src/manifest.sh src/build-info.sh demo/demo.sh; do
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

grep -Fq 'env: ./src/env.sh' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the env command.\n' >&2
  exit 1
}

grep -Fq 'manifest: ./src/manifest.sh' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the manifest command.\n' >&2
  exit 1
}

grep -Fq 'python-info: ./bin/base-demo-python-info' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the python-info command.\n' >&2
  exit 1
}

grep -Fq 'script: ./demo/demo.sh' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the demo script.\n' >&2
  exit 1
}

grep -Fq 'required_env:' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare health.required_env.\n' >&2
  exit 1
}

grep -Fq 'build:' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare build targets.\n' >&2
  exit 1
}

printf 'Repository baseline is present.\n'
