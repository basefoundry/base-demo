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
  docs/representative-environment.md
  base_manifest.yaml
  Brewfile
  .mise.toml
  .base/activate.sh
  bin/base-demo-python-info
  bin/base-demo-services
  bin/base-demo-environments
  services/catalog.json
  infra/compose.yaml
  services/go-api/go.mod
  services/go-api/main.go
  services/go-api/server_test.go
  services/go-api/Dockerfile
  services/go-api/build.sh
  environments/dev.json
  environments/staging.json
  environments/prod.json
  src/hello.sh
  src/env.sh
  src/manifest.sh
  src/build-info.sh
  lib/python/base_demo_cli/__init__.py
  lib/python/base_demo_cli/__main__.py
  demo/demo.sh
  tests/demo_test.bats
  tests/services_test.bats
  tests/environments_test.bats
  tests/infra_test.bats
  tests/go_api_test.bats
  .github/workflows/tests.yml
  .github/pull_request_template.md
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || {
    printf 'Missing required file: %s\n' "$file" >&2
    exit 1
  }
done

for executable in tests/validate.sh install.sh .base/activate.sh bin/base-demo-python-info bin/base-demo-services bin/base-demo-environments src/hello.sh src/env.sh src/manifest.sh src/build-info.sh services/go-api/build.sh demo/demo.sh; do
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

grep -Fq 'services: ./bin/base-demo-services' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the services command.\n' >&2
  exit 1
}

grep -Fq 'environments: ./bin/base-demo-environments' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the environments command.\n' >&2
  exit 1
}

grep -Fq 'script: ./demo/demo.sh' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare the demo script.\n' >&2
  exit 1
}

grep -Fq '"name": "project-baseline"' services/catalog.json || {
  printf 'services/catalog.json does not declare the project-baseline entry.\n' >&2
  exit 1
}

for service in postgres mysql redis; do
  grep -Fq "\"name\": \"$service\"" services/catalog.json || {
    printf 'services/catalog.json does not declare %s.\n' "$service" >&2
    exit 1
  }
  grep -Fq "  $service:" infra/compose.yaml || {
    printf 'infra/compose.yaml does not declare %s.\n' "$service" >&2
    exit 1
  }
done

grep -Fq '"name": "go-api"' services/catalog.json || {
  printf 'services/catalog.json does not declare go-api.\n' >&2
  exit 1
}

grep -Fq '  go-api:' infra/compose.yaml || {
  printf 'infra/compose.yaml does not declare go-api.\n' >&2
  exit 1
}

if command -v go >/dev/null 2>&1; then
  (cd services/go-api && CGO_ENABLED=0 go test ./...) || exit 1
else
  printf 'Skipping go-api tests because go is not available.\n'
fi

for environment in dev staging prod; do
  grep -Fq "\"name\": \"$environment\"" "environments/$environment.json" || {
    printf 'environments/%s.json does not declare matching environment name.\n' "$environment" >&2
    exit 1
  }
done

grep -Fq 'required_env:' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare health.required_env.\n' >&2
  exit 1
}

grep -Fq 'build:' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare build targets.\n' >&2
  exit 1
}

grep -Fq 'mise:' base_manifest.yaml || {
  printf 'base_manifest.yaml does not declare mise configuration.\n' >&2
  exit 1
}

printf 'Repository baseline is present.\n'
